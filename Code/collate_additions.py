import os
import re
import itertools
from collections import defaultdict
from sage.all import ZZ
ope = os.path.exists
opj = os.path.join

nTt_re = re.compile(r"\d+T\d+")

def nTt_checked(nTt):
    n, t = [int(c) for c in nTt.split("T")]
    if n == 32:
        return t <= 9551 or t >= 2799324 or t in [11713, 11916, 12882, 12897, 14765, 22195, 34907, 37217, 96908, 96911, 96912, 96916, 96959, 97020, 97037, 205727]
    return n < 48

def collate(folder):
    # Naming conventions:
    # Big*.hashed -- lines contain pairs `desc ordhash`, where `desc` can be fed into StringToGroup
    #                and `ordhash` takes the form `N.hsh` where N is the order of the group and hsh is the hash.
    # Big*.unhashed -- lines contain pairs `desc order`, as above but without the hash
    # Small*.txt and Medium*.identified -- lines contain a small group id (generally of one of the skipped orders 512, 640, 768,...
    # Skipped.orders -- lines contain orders of groups that could not be hashed (not identifiable or 512,1152,1536,1920)
    # Other files are ignored

    # Output:
    # - creates a file `Smed.txt` containing small group ids without duplicates
    # - creates a folder `active`, and a file within it for each ordhash that has more than one group; each line of the file has the description of a group with that ordhash.
    # - creates a folder `done`, and a file within it for each ordhash with only one group (and for each unhashed group with an order that did not otherwise exist)
    # - creates a file `Problems.txt` containing pairs `desc order` of unhashed groups where the order is not unique

    smedfile = opj(folder, "Smed.txt")
    probfile = opj(folder, "Problems.txt")
    active = opj(folder, "active")
    done = opj(folder, "done")
    if ope(smedfile): raise ValueError("Smed.txt already exists")
    if ope(probfile): raise ValueError("Problems.txt already exists")
    if ope(active): raise ValueError("active already exists")
    if ope(done): raise ValueError("done already exists")
    os.mkdir(active)
    os.mkdir(done)
    smed = set()
    big = defaultdict(set)
    orders = set()
    unhashed = defaultdict(list)
    for ifile in os.listdir(folder):
        if (ifile.startswith("Small") and ifile.endswith(".txt") or
            ifile.startswith("Medium") and ifile.endswith(".identified")):
            with open(opj(folder, ifile)) as F:
                for line in F:
                    line = line.strip()
                    if line:
                        smed.add(line)
        elif ifile.startswith("Big") and ifile.endswith(".hashed"):
            with open(opj(folder, ifile)) as F:
                for line in F:
                    line = line.strip()
                    if line:
                        desc, ordhash = line.split()
                        order, hash = ordhash.split(".")
                        big[ordhash].add(desc)
                        orders.add(order)
        elif ifile.startswith("Big") and ifile.endswith(".unhashed"):
            with open(opj(folder, ifile)) as F:
                for line in F:
                    line = line.strip()
                    if line:
                        desc, order = line.split()
                        unhashed[order].append(desc)
    smed = sorted(smed, key=lambda x: [int(c) for c in x.split(".")])
    with open(smedfile, "w") as F:
        _ = F.write("\n".join(smed)+"\n")
    unh_ok = {}
    unh_probs = []
    for order, V in unhashed.items():
        if len(V) == 1 and order not in orders:
            unh_ok[order] = V
        else:
            for desc in V:
                unh_probs.append(f"{desc} {order}")
    for ordhash, V in itertools.chain(big.items(), unh_ok.items()):
        if len(V) == 1 or all(nTt_re.fullmatch(desc) and nTt_checked(desc) for desc in V):
            ofile = opj(done, ordhash)
        else:
            ofile = opj(active, ordhash)
        with open(ofile, "w") as F:
            _ = F.write("\n".join(V)+"\n")
    if unh_probs:
        with open(probfile, "w") as F:
            _ = F.write("\n".join(unh_probs)+"\n")
    print("Collated")

def make_twopow_file(active_folder, outfile):
    # Make a file for use with stanpresone.m for using StandardPresentation to find isomorphisms.
    # Note that this didn't work well: StandardPresentation is too slow for large 2-groups.
    lines = []
    if ope(outfile):
        raise ValueError("Output file already exists")
    for fname in os.listdir(active_folder):
        N = ZZ(fname.split(".")[0])
        if N.is_prime_power():
            with open(opj(active_folder, fname)) as F:
                for line in F:
                    first = line.strip().split(" ")[0]
                    lines.append(f"{fname} {first}")
    with open(outfile, "w") as F:
        _ = F.write("\n".join(lines)+"\n")
    print("Success")

def collate_success(folder, include_tiny=True):
    """
    Collates successfully identified groups into two files

    INPUT:

    - ``folder`` -- a string, giving the path to a folder
    - ``include_tiny`` -- boolean, whether to include all groups of tiny order (at most 2000 and not (larger than 500 and divisible by 128))

    The folder should contain the following:

    - files ``Big*.hashed`` -- lines contain pairs `desc ordhash`, where `desc` can be fed into StringToGroup
                               and `ordhash` takes the form `N.hsh` where N is the order of the group and hsh is the hash.
    - files ``Big*.unhashed`` -- lines contain pairs `desc order`, as above but without the hash
    - files ``Small*.txt`` and ``Medium*.identified`` -- lines contain a small group id(generally of one of the skipped orders 512, 640, 768).
    - files ``*.aliases`` --  lines consist of a pair of strings giving a group description, separated by a space.  The intention is that the first entry in each pair should be referred to by the second, and that the second will occur in some other Small, Medium or Big file.
    - a subfolder ``clustered``, containing files giving isomorphism classes of the ``Big*`` groups.  The lines in these files consist of space separated string descriptions, each line giving an isomorphism class.

    OUTPUT:

    - a file ``folder/aliases.txt`` containing pairs ``label desc`` of a description with the corresponding label
    - a file ``folder/to_add.txt`` giving a list of groups to be added to the LMFDB
    """
    if include_tiny:
        X = [(ZZ(pair[1]), ZZ(pair[2])) for pair in magma("[[N, NumberOfSmallGroups(N)] : N in [1..2000] | N le 500 or Valuation(N,2) lt 7]")]
        tiny = {N : [f"{N}.{i}" for i in range(1,lim+1)] for N,lim in X}
    else:
        tiny = {}
    smed = defaultdict(set)
    by_iso = defaultdict(list)
    aliases = defaultdict(lambda: defaultdict(list))
    labels = {}
    backaliases = defaultdict(list)
    biginputs = set()
    bigoutputs = set()
    for ifile in os.listdir(folder):
        if ifile.startswith("Small") and ifile.endswith(".txt"):
            with open(opj(folder, ifile)) as F:
                for line in F:
                    label = line.strip()
                    if label:
                        N = ZZ(label.split(".")[0])
                        smed[N].add(label)
        elif ifile.startswith("Medium") and ifile.endswith(".identified"):
            prefile = ifile.replace(".identified", ".txt")
            with open(opj(folder, ifile)) as F:
                labels = [x for x in F.read().strip().split("\n") if x]
            if ope(opj(folder, prefile)):
                with open(opj(folder, prefile)) as F:
                    descs = [x for x in F.read().strip().split("\n") if x]
            else:
                descs = []
            if len(labels) == len(descs):
                for label, desc in zip(labels, descs):
                    N = ZZ(label.split(".")[0])
                    aliases[N][label].append(desc)
                    smed[N].add(label)
            else:
                print("Length mismatch for", ifile)
                for label in labels:
                    N = ZZ(label.split(".")[0])
                    smed[N].add(label)
        elif ifile.startswith("Big") and (ifile.endswith(".hashed") or ifile.endswith(".unhashed")):
            with open(opj(folder, ifile)) as F:
                for line in F:
                    line = line.strip()
                    if line:
                        desc, ordhash = line.split()
                        biginputs.add(desc)
        elif ifile.endswith(".aliases"):
            with open(opj(folder, ifile)) as F:
                for line in F:
                    line = line.strip()
                    if line:
                        al, can = line.split()
                        backaliases[can].append(al)
    for ordhsh in os.listdir(opj(folder, "clustered")):
        N = ZZ(ordhsh.split(".")[0])
        if "." in ordhsh:
            hsh = ordhsh.split(".")[1]
        else:
            hsh = r"\N"
        with open(opj(folder, "clustered", ordhsh)) as F:
            for line in F:
                descs = F.strip().split()
                by_iso[N].append((hsh, descs))
                bigoutputs.update(descs)
    missing = biginputs.difference(bigoutputs)
    extra = bigoutputs.difference(biginputs)
    if missing:
        print(f"Missing {len(missing)} inputs")
        for desc in list(missing)[:10]:
            print("   ", desc[:120])
    if extra:
        print(f"Extra {len(extra)} outputs")
        for desc in list(extra)[:10]:
            print("   ", desc[:120])
    # Some "Big" groups were inappopriately classified, and actually can be identified.
    canid = [ZZ(N) for N in magma(f"[N : N in [{','.join(by_iso)}] | CanIdentifyGroup(N)]")]
    for N in canid:
        for hsh, iso in by_iso[N]:
            label = f"{N}.{hsh}"
            smed[N].add(label)
            for desc in iso:
                if desc != label:
                    aliases[N][label].append(desc)
        del by_iso[N]
    for N in smed:
        smed[N] = sorted(smed[N], key=lambda x: [int(c) for c in x.split(".")])
    # Now we choose labels.  First we sort the isomorphism class and pick two descriptions: the one to be displayed and one that's best to compute with.
    lie_codes = ["GL", "SL", "Sp", "SO", "SOPlus", "SOMinus", "SU", "GO", "GOPlus", "GOMinus", "GU", "CSp", "CSO", "CSOPlus", "CSOMinus", "CSU", "CO", "COPlus", "COMinus", "CU", "Omega", "OmegaPlus", "OmegaMinus", "Spin", "SpinPlus", "SpinMinus", "PGL", "PSL", "PSp", "PSO", "PSOPlus", "PSOMinus", "PSU", "PGO", "PGOPlus", "PGOMinus", "PGU", "POmega", "POmegaPlus", "POmegaMinus", "PGammaL", "PSigmaL", "PSigmaSp", "PGammaU", "AGL", "ASL", "ASp", "AGammaL", "ASigmaL", "ASigmaSp"]
    def codes(desc):
        # A code to sort by in sorting by how nice a presentation is to display, and another for computation
        # Here we generally prefer matrix representations to permutation representations
        # Smaller is better
        # The descriptions fall into the following types:
        # nTt, d,RMat, nPerm, PerfI, ChevX, Lie code (e.g. PGL(2,17)), sporadic codes
        if "Chev" in desc:
            # No collisions in our dataset between Chevalley groups
            return (-1,), (2,)
        elif "Perf" in desc:
            # These are permutation representations and have been optimized for degree
            return (0, ZZ(desc[4:])), (0, ZZ(desc[4:]))
        elif "Perm" in desc:
            code = tuple(1000000 + ZZ(c) for c in desc[4:].split(",")) # Prefer transitive labels if same degree
            return (3,) + code, (1,) + code
        elif "Mat" in desc:
            dR, gens = desc.split("Mat")
            d,R = dR.split(",")
            d,R = ZZ(d), ZZ(R.replace("q", ""))
            gens = tuple(ZZ(c) for c in gens.split(","))
            code = (d,R) + gens
            return (1,) + code, (3,) + code
        elif "T" in desc:
            n, t = desc.split("T")
            code = (ZZ(n), ZZ(t))
            return (3,) + code, (1,) + code
        elif desc.endswith(")"):
            lie, params = disc[:-1].split("(")
            lie = lie_codes.index(lie)
            params = tuple(ZZ(c) for c in params.split(","))
            code = (lie,) + params
            return code, code
        else:
            raise ValueError("Unrecognized description type", desc)
    def display_key(desc):
        return codes(desc)[0] if isinstance(desc, str) else codes(desc[0])[0]
    def compute_key(desc):
        return codes(desc)[1]
    def num2letters(n):
        r"""
        Convert a number into a string of letters
        """
        if n < 26:
            return chr(97+n)
        else:
            return num2letters(int(n/26))+chr(97+n%26)
    def letters2num(s):
        return sum((ord(z)-97)*26**i for i,z in enumerate(reversed(s)))
    iso_reps = defaultdict(list)
    for N, isos in by_iso.items():
        hashes = [hsh for hsh, cls in isos]
        disp_sorted = sorted([sorted(cls, key=display_key) for hsh, cls in isos], key=display_key)
        comp_sorted = [sorted(cls, key=compute_key) for cls in disp_sorted]
        for i, (h, D, C) in enumerate(zip(hashes, disp_sorted, comp_sorted)):
            label = "{N}.{num2letters(i)}"
            for desc in disp_sorted:
                aliases[N][label].append(desc)
                for al in backaliases[desc]:
                    aliases[N][label].append(al)
            iso_reps[N].append(f"{label} {h} {D[0]} {C[0]}")
    iso_reps.update(smed)
    iso_reps.update(tiny)
    with open(opj(folder, "aliases.txt"), "w") as F:
        for N in sorted(aliases):
            for label in sorted(aliases[N], key=lambda x: letters2num(x.split(".")[1])):
                for desc in aliases[N][label]:
                    _ = F.write(f"{label} {desc}\n")
    # For now we just write to one file, though it's maybe better to use one for each thing to add?
    with open(opj(folder, "to_add.txt"), "w") as F:
        for N in sorted(iso_reps):
            for line in iso_reps[N]:
                _ = F.write(line+"\n")
    print("Successfully wrote", opj(folder, "aliases.txt"), "and", opj(folder, "to_add.txt"))
