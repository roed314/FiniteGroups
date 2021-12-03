# Implements functions for identifying groups that are in the SmallGroups database but where IdGroup doesn't work (order 512, 1536, p^5, p^6, 3^7, 5^7, 7^7, 11^7, 3^8) using the gps_smallhash table in the LMFDB

from collections import defaultdict
from sage.misc.misc_c import prod
from sage.rings.integer import Integer
from sage.rings.integer_ring import ZZ
from sage.libs.gap.libgap import libgap
from sage.libs.gap.element import GapElement
from sage.interfaces.magma import MagmaElement

def _id_group(G):
    """
    Identify a group, assuming that the order is such that identification is possible

    INPUT:

    - ``G`` -- a libgap or Magma group
    """
    if isinstance(G, GapElement):
        return ZZ(G.IdGroup()[1])
    else: # magma group
        return ZZ(G.IdentifyGroup()[2])

def Hash(G):
    """
    The hash of G is a 63-bit positive integer invariant under isomorphism
    """
    REDP = ZZ(9223372036854775783) # largest prime below 2^63
    def collapse_int_list(L):
        if isinstance(L, (int, Integer)):
            return L % REDP
        L = [collapse_int_list(x) for x in L]
        res = 997 * len(L)
        for x in L:
            res = x.__xor__((1000003 * res) % REDP)
        return res
    def easy_hash_gap(H):
        M = H.Order()
        # We treat 1152 and 1920 as not identifiable so that we can produce the same hash both here and in magma, which cannot identify those orders
        if M not in [1152, 1920] and libgap.IdGroupsAvailable(M):
            return _id_group(H)
        data = defaultdict(int)
        for c in H.ConjugacyClasses():
            data[ZZ(c.Representative().Order()), ZZ(c.Size())] += 1
        data = sorted([o, s, cnt] for ((o, s), cnt) in data.items())
        return collapse_int_list(data)
    def easy_hash_magma(H):
        M = ZZ(H.Order())
        if M not in [1152, 1920] and libgap.IdGroupsAvailable(M):
            return _id_group(H)
        data = magma.AssociativeArray()
        magma.eval(f"""
for C in ConjugacyClasses({H.name()}) do
    if not IsDefined({data.name()}, <C[1], C[2]>) then
        {data.name()}[<C[1], C[2]>] := 0;
    end if;
    {data.name()}[<C[1], C[2]>] +:= 1;
end for;
{data.name()} := Sort([[k[1], k[2], v] : k -> v in {data.name()}]);
""")
        data = [[ZZ(c) for c in piece] for piece in data]
        return collapse_int_list(data)
    def smith_invariants(H):
        """
        The sequence of integers, each dividing the next, so that H is isomorphic to the corresponding product of cyclic groups.

        INPUT:

        - ``H`` -- a Gap or Magma abelian group
        """
        if isinstance(H, MagmaElement):
            return [ZZ(m) for m in H.AbelianInvariants()]
        invs = [ZZ(q) for q in H.AbelianInvariants()]
        by_p = defaultdict(list)
        for q in invs:
            p, _ = q.is_prime_power(get_data=True)
            by_p[p].append(q)
        M = max(len(qs) for qs in by_p.values())
        for p, qs in by_p.items():
            by_p[p] = [1] * (M - len(qs)) + qs
        return [prod(qs) for qs in zip(*by_p.values())]
    if not isinstance(G, (GapElement, MagmaElement)):
        G = G._libgap_()
    N = ZZ(G.Order())
    # See note above about 1152 and 1920
    if N not in [1152, 1920] and libgap.IdGroupsAvailable(N):
        return _id_group(G)
    elif G.IsAbelian():
        return collapse_int_list(smith_invariants(G))
    elif isinstance(G, GapElement):
        return collapse_int_list(sorted(
            [[N, easy_hash_gap(G)]] + [[ZZ(H.Order()), easy_hash_gap(H)] for H in G.MaximalSubgroupClassReps()]))
    else: # magma group
        return collapse_int_list(sorted(
            [[N, easy_hash_magma(G)]] + [[ZZ(H.get_magma_attribute("order")), easy_hash_magma(H.get_magma_attribute("subgroup"))] for H in G.MaximalSubgroups()]))

def IdGroup(G, verbose=False, check=False, already_standard=False):
    """
    Returns the id number of G in the SmallGroups database.

    INPUT:

    - ``G`` -- a group (GAP, Sage or Magma)
    - ``verbose`` -- if true, print status reports while iterating through possible group ids
    - ``check`` -- if True, confirm the existence of an isomorphism even if only one (remaining) possibility
    - ``already_standard`` -- if true, asserts that G is already in StandardPresentation form

    OUTPUT:

    - ``N`` -- the order of ``G``
    - ``i`` -- the small group id of ``G``
    """
    if not isinstance(G, (GapElement, MagmaElement)):
        G = G._libgap_()
    using_magma = isinstance(G, MagmaElement)
    N = ZZ(G.Order())
    if libgap.IdGroupsAvailable(N) and not (using_magma and N in [1152, 1920]):
        if verbose:
            print(f"Identification of groups of order {N} available in",
                  "Magma" if using_magma else "GAP")
        return N, _id_group(G)
    if libgap.SmallGroupsAvailable(N):
        if verbose:
            print("Computing hash value to determine id")
        hsh = Hash(G)
        try:
            from lmfdb import db
            if verbose:
                print(f"Hash is {hsh}, looking up possibilities in local LMFDB database")
            ids = [ZZ(rec['counter']) for rec in db.gps_smallhash.search({"order": N, "hash": hsh})]
        except ModuleNotFoundError:
            # We use the lmfdb's online API
            if verbose:
                print(f"Hash is {hsh}, looking up possibilities in online LMFDB database")
            from requests import get
            url = f"https://beta.lmfdb.org/api/gps_smallhash/?order=i{N}&hash=i{hsh}&_format=json"
            r = get(url)
            if r.status_code == 200:
                J = r.json()
                ids = [ZZ(rec['counter']) for rec in J['data']]
            else:
                raise RuntimeError("LMFDB not installed and internet connection to beta.lmfdb.org not available")
        if not ids:
            if N > 2000: # Need to update once p^5 and p^6 stored in the LMFDB
                raise ValueError(f"Hash values for groups of order {N} not yet stored in the LMFDB")
            else:
                raise RuntimeError("No groups found with the correct hash; please contact LMFDB developers at lmfdb-support@googlegroups.com")
        if len(ids) == 1 and not check:
            if verbose:
                print(f"Only one possibility from hashing: {ids[0]}")
            return N, ids[0]
        # There are multiple possibilities, and we need to check them all.
        if using_magma:
            if N.is_prime_power():
                # We can use Magma's StandardPresentation function
                if verbose:
                    print(f"Checking {len(ids)} possibilities using StandardPresentation")
                if already_standard:
                    Gstandard = G
                else:
                    GStandard = G.StandardPresentation()
                    if verbose:
                        print("Standard presentation of G computed")
                for ctr, Hi in enumerate(ids[:-1]):
                    H = magma.SmallGroup(N, Hi)
                    HStandard = H.StandardPresentation()
                    if GStandard.IsIdenticalPresentation(HStandard):
                        if verbose:
                            print("Isomorphic group found")
                        return N, Hi
                    if verbose:
                        print(f"Checked {ctr+1}/{len(ids)}")
                Hi = ids[-1]
                if check:
                    H = magma.SmallGroup(N, Hi)
                    HStandard = H.StandardPresentation()
                    if not GStandard.IsIdenticalPresentation(HStandard):
                        raise RuntimeError("Groups found with same hash, but none isomorphic; please contact LMFDB developers at lmfdb-support@googlegroups.com")
                return N, Hi
            else: # not a p-group
                solv = G.IsSolvable()
                if solv:
                    if verbose:
                        print(f"Checking {len(ids)} possibilities using IsIsomorphicSolubleGroupNoMap")
                    isofunc = magma.IsIsomorphicSolubleGroupNoMap
                else:
                    if verbose:
                        print(f"Checking {len(ids)} possibilities using IsIsomorphic")
                    isofunc = magma.IsIsomorphic
                for ctr, Hi in enumerate(ids[:-1]):
                    H = magma.SmallGroup(N, Hi)
                    if H.IsSolvable() != solv:
                        continue
                    if isofunc(G, H):
                        if verbose:
                            print("Isomorphic group found")
                        return N, Hi
                    if verbose:
                        print(f"Checked {ctr+1}/{len(ids)}")
                Hi = ids[-1]
                if check:
                    H = magma.SmallGroup(N, Hi)
                    if not isofunc(G, H):
                        raise RuntimeError("Groups found with same hash, but none isomorphic; please contact LMFDB developers at lmfdb-support@googlegroups.com")
                return N, Hi
        else: # GAP
            solv = G.IsSolvable()
            if solv:
                # We try a randomized strategy, following that of GAP's RandomIsomorphismTest
                groups = []
                j = 0
                while j < len(ids):
                    i = ids[j]
                    H = libgap.SmallGroup(N, i)
                    if H.IsSolvable():
                        groups.append(H)
                        j += 1
                    else:
                        ids.pop(j)
                if len(groups) == 1 and not check: # might happen
                    return N, ids[0]
                groups.append(G.IsomorphismPcGroup().Image())
                codes = {}
                if verbose:
                    print(f"Trying randomized strategy to distinguish from {len(ids)} options")
                ctr = 1
                while True:
                    for j, H in enumerate(groups):
                        code = ZZ(H.RandomSpecialPcgsCoded())
                        if code in codes and codes[code] != j:
                            if max(codes[code], j) != len(ids):
                                raise RuntimeError(f"Small groups {N}.{ids[j]} and {N}.{ids[codes[code]]} isomorphic to each other!")
                            if verbose:
                                print("Isomorphic group found")
                            return N, ids[min(j, codes[code])]
                    if verbose and ctr % 1000 == 0:
                        print(f"Finished {ctr} iterations")
                    ctr += 1
            else: # non-solvable
                for i in ids[:-1]:
                    H = libgap.SmallGroups(N, i)
                    if H.IsSolvable():
                        continue
                    f = G.IsomorphismGroups(H)
                    if f != libgap.fail:
                        return N, i
                if check:
                    H = libgap.SmallGroup(N, ids[-1])
                    f = G.IsomorphismGroups(H)
                    if f == libgap.fail:
                        raise RuntimeError("Groups found with same hash, but none isomorphic; please contact LMFDB developers at lmfdb-support@googlegroups.com")
                return N, ids[-1]
