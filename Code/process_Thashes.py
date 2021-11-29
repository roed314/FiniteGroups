import os
opj = os.path.join
from collections import defaultdict
from sage.libs.gap.libgap import libgap
from sage.rings.integer_ring import ZZ
from sage.functions.other import factorial

def load_db():
    sib_dict = defaultdict(lambda: defaultdict(set))
    bnd_dict = defaultdict(dict)
    for rec in db.gps_transitive.search({"n": {"$ne":32}, "order": {"$or": [1024, {"$gt": 2000}]}}, ["n", "t", "siblings", "order", "bound_siblings"]):
        sibs = set(tuple(s[0]) for s in rec["siblings"])
        sibs.add((rec["n"], rec["t"]))
        msib = min(sibs)
        sib_bnd = rec["bound_siblings"]
        msib_ok = (msib[0] <= sib_bnd)
        msib = "T".join(str(c) for c in msib)
        D = sib_dict[rec["order"]]
        D[msib] = D[msib].union(sibs)
        E = bnd_dict[rec["order"]]
        E[msib] = max(E[msib], sib_bnd)

def load_hashes():
    hashfile = opj("DATA", "hash", "thash.out")
    clusters = defaultdict(list)
    seen = defaultdict(set)
    with open(hashfile) as F:
        for line in F:
            n, t, N, hsh = map(ZZ, line.strip().split())
            seen[n].add(t)
            if N == 1024 or N > 2000 and not libgap.SmallGroupsAvailable(N):
                clusters[N,hsh].append(f"{n}T{t}")
    # We manually add some groups where we didn't succeed in computing the hash, but know that they are unique up to isomorphism
    for n in range(39, 48):
        tmax = ZZ(libgap.NrTransitiveGroups(n))
        clusters[factorial(n),-1] = [f"{n}T{tmax}"] # Sn
        clusters[factorial(n)//2,-1] = [f"{n}T{tmax-1}"] # An
        seen[n].update(set([tmax-1,tmax]))
    clusters[73123168801259520,-1] = ["45T10340"]
    seen[45].add(10340)
    clusters[216862434431944426122117120000,818067353932353174] = ["46T50"]
    clusters[334163384733794511232410592146672844800000000,-1] = ["46T51"]
    clusters[668326769467589022464821184293345689600000000,-1] = ["46T52"]
    clusters[668326769467589022464821184293345689600000000,7366024907030851873] = ["46T53"]
    clusters[1336653538935178044929642368586691379200000000,-1] = ["46T54"]
    seen[46].update(set(range(50,55)))
    for n in range(1, 47):
        if n not in seen:
            print("Missing degree", n)
        else:
            cnt = libgap.NrTransitiveGroups(n)
            if len(seen[n]) != cnt:
                print(f"Missing {cnt - len(seen[n])} in degree {n}")
                if cnt - len(seen[n]) < 10:
                    print([i for i in range(1, cnt+1) if i not in seen[n]])
                else:
                    for i in range(1, cnt+1):
                        if i not in seen[n]:
                            print("Smallest", i)
                            break
                    for i in range(cnt, 0, -1):
                        if i not in seen[n]:
                            print("Largest", i)
                            break
    return clusters

def process_clusters(data):
    sibs = {
        rec["label"]: (set(tuple(s[0])
                           for s in rec["siblings"]
                           if s[0][0] != 32).union(set([(rec["n"], rec["t"])])),
                       rec["bound_siblings"])
        for rec in db.gps_transitive.search({"n":{"$ne":32}, "gapid": 0},
                                            ["n", "t", "label", "siblings", "bound_siblings"])
    }
    with open("DATA/hash/tclusters.txt", "w") as F:
        for (N,hsh), bucket in data.items():
            clusters = defaultdict(set)
            bnd = defaultdict(int)
            to_check = []
            for label in bucket:
                if label not in sibs:
                    raise RuntimeError(label)
                S, b = sibs[label]
                msib = min(S)
                clusters[msib].update(S)
                bnd[msib] = max(bnd[msib], b)
                if b < msib[0]:
                    # msib might be wrong
                    to_check.append(msib)
            for check in sorted(to_check):
                for msib, V in list(clusters.items()):
                    if check in V and msib < check:
                        bnd[msib] = max(bnd[msib], bnd.pop(check))
                        V.update(clusters.pop(check))
            maxn = max(n for (n,t) in clusters)
            if len(clusters) == 1:
                done = clusters
                undone = {}
            else:
                # clusters where the bound is large enough that we can rule out merging with any other cluster
                done = {msib: clusters[msib] for (msib, b) in bnd.items() if b >= maxn}
                undone = {msib: clusters[msib] for (msib, b) in bnd.items() if b < maxn}
            for msib, osibs in done.items():
                osibs = ["T".join(str(c) for c in osib) for osib in sorted(osibs) if osib != msib]
                msib = "T".join(str(c) for c in msib)
                F.write(f"{msib} {hsh} {' '.join(osibs)}\n")
            if undone:
                with open(f"DATA/hash/tsep/{N}.{hsh}", "w") as Fsep:
                    for msib, osibs in undone.items():
                        b = bnd[msib]
                        osibs = ["T".join(str(c) for c in osib) for osib in sorted(osibs) if osib != msib]
                        msib = "T".join(str(c) for c in msib)
                        Fsep.write(f"{msib} {b} {' '.join(osibs)}\n")
