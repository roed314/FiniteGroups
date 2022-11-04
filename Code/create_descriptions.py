#!/usr/bin/env -S sage -python
# Create the descriptions folder

from sage.misc.misc import walltime
t0 = walltime()
import os
import sys
opj = os.path.join
ope = os.path.exists
from sage.all import ZZ

sys.path.append(os.path.expanduser(opj("~", "lmfdb")))

from lmfdb import db
from collections import defaultdict

slookup = {rec["label"]: (rec["pc_code"], None, rec["gens_used"], True) for rec in db.gps_groups.search({"solvable":True}, ["label", "pc_code", "gens_used"])}
nlookup = {rec["label"]: rec["perm_gens"] for rec in db.gps_groups.search({"solvable":False}, ["label", "perm_gens"])}
sibling_bound = {rec["label"]: rec["bound_siblings"] for rec in db.gps_transitive.search({}, ["label", "bound_siblings"])}
tbound = defaultdict(lambda: 48) # 48 is larger than any transitive degree in an nTt label
for rec in db.gps_transitive.search({"gapid":{"$ne":0}}, ["order", "gapid", "n"]):
    label = f"{rec['order']}.{rec['gapid']}"
    tbound[label] = min(tbound[label], rec["n"])
print("LMFDB data loaded in", walltime() - t0)

os.makedirs(opj("DATA", "descriptions"), exist_ok=True)
os.makedirs(opj("DATA", "preload"), exist_ok=True)
os.makedirs(opj("DATA", "pcbug.todo"), exist_ok=True)
os.makedirs(opj("DATA", "pcbugs"), exist_ok=True)
os.makedirs(opj("DATA", "hash_lookup"), exist_ok=True)

# Permutation degrees of perfect groups from the perfect group database
Perf_lookup = dict(zip(
    [13, 14, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 32, 33, 34, 40, 41, 42, 43, 44, 45, 46, 48, 49, 51, 52, 53, 54, 55, 56, 57, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 77, 78, 80, 81, 82, 113, 114, 115, 136, 140, 166, 168, 169, 173, 179, 180, 181, 183, 184, 185, 186, 187, 188, 189, 190, 191, 193, 194, 195, 196, 197, 198, 199, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 219, 220, 221, 222, 223, 224, 225, 238, 250, 251, 252, 253, 254, 255, 256, 279, 281, 282, 283, 286, 323, 324, 351, 353, 354, 356, 357, 359, 360, 361, 362, 363, 364, 365, 366, 367, 368, 369, 370, 372, 374, 410, 411, 428, 429, 431, 436, 437, 442, 443, 456, 457, 459, 477, 478, 479, 483, 484, 485, 486, 488, 489, 490, 491, 493],
    [64, 64, 48, 36, 48, 56, 76, 88, 88, 88, 48, 128, 100, 32, 152, 96, 240, 384, 50, 384, 240, 96, 48, 160, 160, 160, 90, 42, 32, 240, 384, 32, 384, 100, 52, 80, 80, 240, 32, 384, 28, 40, 56, 39, 144, 42, 243, 243, 54, 54, 125, 121, 361, 24, 30, 32, 112, 32, 24, 32, 128, 38, 30, 44, 72, 72, 72, 24, 128, 80, 38, 30, 44, 44, 44, 128, 128, 32, 32, 144, 32, 32, 32, 144, 32, 46, 672, 128, 88, 144, 144, 144, 144, 224, 40, 32, 46, 60, 40, 32, 49, 80, 96, 80, 64, 384, 92, 144, 34, 98, 114, 98, 98, 64, 72, 56, 18, 288, 17, 20, 24, 48, 26, 208, 28, 56, 30, 120, 32, 64, 33, 38, 42, 44, 7, 240, 285, 13, 28, 8, 240, 21, 112, 11, 27, 65, 29, 288, 48, 21, 31, 192, 40, 85, 30, 960, 14, 16]))
Chev_lookup = { # (dimension, exponent to raise q in order to get actual coefficient ring)
    "G,2": (7, 1),
    "2B,2": (4, 1),
    "2F,4": (26, 2),
    "3D,4": (8, 3),
    "2G,2": (27, 1),
    "F,4": (26, 1),
    "E,6": (27, 1),
    "2E,6": (27, 2),
    "E,7": (56, 1),
}
Spor_lookup = {
    "J1": [("GLFp", 7, 11), ("Perm", 266, 0)],
    "J2": [("GLFq", 6, 2, 2), ("Perm", 100, 0)],
    "HS": [("Perm", 100, 0)],
    "J3": [("GLFq", 18, 2, 3)],
    "McL": [("Perm", 275, 0)],
    "He": [("GLFp", 51, 2)],
    "Ru": [("GLFp", 28, 2)],
    "Co3": [("GLFp", 22, 2), ("Perm", 276, 0)],
    "Co2": [("GLFp", 22, 2), ("Perm", 2300, 0)],
    "Co1": [("GLFp", 24, 2)],
}
SnT = dict(zip(range(2, 48), [1, 2, 5, 5, 16, 7, 50, 34, 45, 8, 301, 9, 63, 104, 1954, 10, 983, 8, 1117, 164, 59, 7, 25000, 211, 96, 2392, 1854, 8, 5712, 12, 2801324, 162, 115, 407, 121279, 11, 76, 306, 315842, 10, 9491, 10, 2113, 10923, 56, 6])) # The T-number for Sn in each degree; An is one less
perf_chev_spor = defaultdict(list)
with open(opj("DATA", "PerfChevSpor.txt")) as F:
    for line in F:
        desc, edesc = line.strip().split()
        perf_chev_spor[desc].append(edesc)

aliases = defaultdict(lambda: defaultdict(list))
An = {}
Sn = {}
def sortvec_from_desc(desc):
    if "Perm" in desc:
        n = int(desc.split("Perm")[0])
        # favor transitive groups of the same degree
        return "Perm", (n, 10000000, desc)
    elif "Mat" in desc or "MAT" in desc:
        if "Mat" in desc:
            d, q = desc.split("Mat")[0].split(",")[:2]
        else:
            d, q = desc.split("MAT")[0].split(",")[:2]
        d = int(d)
        if q.startswith("q"):
            # prefer Z/N to finite fields (easier to display)
            p, k = ZZ(q[1:]).is_prime_power(get_data=True)
            if k > 1:
                return "GLFq", (d, k, p, desc)
            else:
                return "GLFp", (d, p, desc)
        elif q == "0":
            return "GLZ", (d, desc)
        else:
            p, k = ZZ(q).is_prime_power(get_data=True)
            if k == 0: # not a prime power
                return "GLZN", (d, p, desc)
            elif k == 1: # prime
                return "GLFp", (d, p, desc)
            else:
                return "GLZq", (d, k, p, desc)
    elif "T" in desc:
        n, i = [int(c) for c in desc.split("T")]
        return "Perm", (n, i, desc)
    elif "(" in desc:
        cmd = desc.split("(")[0]
        lie_codes = ["GL", "SL", "Sp", "SO", "SOPlus", "SOMinus", "SU", "GO", "GOPlus", "GOMinus", "GU", "CSp", "CSO", "CSOPlus", "CSOMinus", "CSU", "CO", "COPlus", "COMinus", "CU", "Omega", "OmegaPlus", "OmegaMinus", "Spin", "SpinPlus", "SpinMinus", "PGL", "PSL", "PSp", "PSO", "PSOPlus", "PSOMinus", "PSU", "PGO", "PGOPlus", "PGOMinus", "PGU", "POmega", "POmegaPlus", "POmegaMinus", "PGammaL", "PSigmaL", "PSigmaSp", "PGammaU", "AGL", "ASL", "ASp", "AGammaL", "ASigmaL", "ASigmaSp"]
        d, q = [int(c) for c in desc.split("(")[1].split(")")[0].split(",")]
        return "Lie", (d, lie_codes.index(cmd), q, cmd, desc)
    elif "Perf" in desc:
        raise RuntimeError # Should have been intercepted in update_options by perf_chev_spor
        i = int(desc[4:])
        return "Perm", (Perf_lookup[i], 5000000, desc)
    elif "Chev" in desc:
        raise RuntimeError # Should have been intercepted in update_options by perf_chev_spor
        typ, q = desc[4:].rsplit(",", 1)
        d, k = Chev_lookup[typ]
        q = ZZ(q.replace("-D", ""))**k # remove derived subgroup code for 2F(4,2)-D
        p, k = q.is_prime_power(get_data=True)
        if k > 1:
            return "GLFq", (d, k, p, desc)
        else:
            return "GLFp", (d, p, desc)
    elif desc in Spor_lookup:
        raise RuntimeError # Should have been intercepted in update_options by perf_chev_spor
        for rec in Spor_lookup[desc]:
            return rec[0], rec[1:] + (desc,)
    else:
        raise ValueError("Unexpected description", desc)

spor_chev = {}
def update_options(label, desc):
    if desc in perf_chev_spor:
        if desc in Spor_lookup or "Chev" in desc:
            spor_chev[label] = desc
        for edesc in perf_chev_spor[desc]:
            update_options(label, edesc)
        return
    D = aliases[label]
    if "T" in desc and "MAT" not in desc:
        n, i = [int(c) for c in desc.split("T")]
        tbound[label] = min(tbound[label], n)
        if n in SnT and i == SnT[n]:
            Sn[label] = n
        elif n in SnT and i == SnT[n] - 1:
            An[label] = n
    typ, vec = sortvec_from_desc(desc)
    D[typ].append(vec)

def gens_from_desc(desc):
    # Returns a list of integers describing the generating set in an appropriate way
    for mid in ["Perm", "MAT"]:
        if mid in desc:
            gens = desc.split(mid)[1]
            if not gens: return [] # trivial group
            return [int(c) for c in gens.split(",")]
    if "T" in desc:
        return nTt_to_gens[desc]

def make_representations_dict(bob, lie):
    reps = {}
    for typ, data in bob.items():
        if typ == "Lie":
            reps["Lie"] = [{"family": cmd, "d": d, "q": q, "gens": gens_from_desc(liegens[desc])} for (d, code, q, cmd, desc) in lie]
        elif typ == "PC":
            d, pccode, compact, gens_used, desc = data
            reps["PC"] = {"code": pccode, "gens": gens_used}
            if compact is not None:
                reps["PC"]["pres"] = compact
        elif typ == "Perm":
            d, i, desc = data
            reps["Perm"] = {"d": d, "gens": gens_from_desc(desc)}
        elif typ == "GLZ":
            d, desc = data
            b = int(desc.split("MAT")[0].split(",")[2])
            reps["GLZ"] = {"d": d, "b": b, "gens": gens_from_desc(desc)}
        elif typ in ["GLZq", "GLFq"]:
            if "GLFp" not in bob:
                d, k, p, desc = data
                q = p**k
                reps[typ] = {"d": d, "q": q, "gens": gens_from_desc(desc)}
        elif typ in ["GLFp", "GLZN"]:
            if not (typ == "GLZN" and ("GLFq" in bob or "GLFp" in bob)):
                d, p, desc = data
                reps[typ] = {"d": d, "p": p, "gens": gens_from_desc(desc)}
        else:
            raise NotImplementedError
    return reps

aut = {}
with open(opj("DATA", "aliases.txt")) as F:
    for line in F:
        label, desc = line.strip().split()
        if desc.endswith("-A"):
            G0 = desc[:-2]
            assert G0 not in aut
            aut[G0] = label
        else:
            update_options(label, desc)
print("Aliases loaded in", walltime() - t0)

with open(opj("DATA", "mat_aliases.txt")) as F:
    for line in F:
        label, desc = line.strip().split()
        update_options(label, desc)
print("Matrix aliases loaded in", walltime() - t0)

with open(opj("DATA", "TinyLie.txt")) as F:
    for line in F:
        label, desc = line.strip().split()
        update_options(label, desc)
liegens = {}
with open(opj("DATA", "LieGens.txt")) as F:
    for line in F:
        desc, explicit_desc = line.strip().split()
        liegens[desc] = explicit_desc
print("Lie aliases loaded in", walltime() - t0)

nTt_to_gens = {}
with open(opj("DATA", "nTt_to_Perm.txt")) as F:
    for line in F:
        nTt, desc = line.strip().split()
        nTt_to_gens[nTt] = [int(c) for c in desc.split("Perm")[1].split(",")]

# Get polycyclic presentations from the pcreps folders
def getpc(F):
    s = F.read()
    if s.count("|") == 4:
        # strip off label
        s = s.split("|", 1)[1]
    pccode, gens_used, compact, backiso = s.strip().split("|")
    gens_used = [int(c) for c in gens_used.split(",")]
    return pccode, compact, gens_used

for label in os.listdir(opj("DATA", "pcreps")):
    # We may be overwriting pccodes from the existing database, but that's okay: we recomputed the presentation and now have the compact form
    with open(opj("DATA", "pcreps", label)) as F:
        slookup[label] = getpc(F) + (True,)
for label in os.listdir(opj("DATA", "pcreps_fast")):
    if label in slookup: continue
    with open(opj("DATA", "pcreps_fast", label)) as F:
        pccode, compact, gens_used = getpc(F)
    with open(opj("DATA", "pcreps_fastest", label)) as F:
        pccode1, compact1, gens_used1 = getpc(F)
    if len(gens_used1) < len(gens_used):
        pccode, compact, gens_used = pccode1, compact1, gens_used1
    slookup[label] = (pccode, compact, gens_used, False)
for label in os.listdir(opj("DATA", "pcreps_fastest")):
    if label in slookup: continue
    with open(opj("DATA", "pcreps_fastest", label)) as F:
        slookup[label] = getpc(F) + (False,)
# pcreps_small?

# There is a magma bug that prevents loading of pccodes in some cases.
# We retrieve the CompactPresentation output in some cases from the RePresentations folder
for label in os.listdir(opj("DATA", "RePresentations")):
    if label == "log": continue
    with open(opj("DATA", "RePresentations", label)) as F:
        N = label.split(".")[0]
        data = F.read().split("[")[1].split("]")[0].strip().replace(" ", "")
        desc = f"{N}pc{data}\n"
        if label in slookup:
            pccode, compact, gens_used, optimal = slookup[label]
            if compact is None:
                slookup[label] = (pccode, data, gens_used, optimal)
        #if ope(opj("DATA", "pcbug.todo", label)):
        #    # Magma had a bug in the loading the pccode here; we record that we have the compact presentation
        #    with open(opj("DATA", "pcbugs", label), "w") as Fout:
        #        _ = Fout.write(desc)
        #    os.unlink(opj("DATA", "pcbug.todo", label))
for label, (pccode, compact, gens_used, optimal) in slookup.items():
    N = label.split(".")[0]
    if compact is None:
        desc = f"{N}PC{pccode}"
    else:
        desc = f"{N}pc{compact}"
    aliases[label]["PC"].append((len(gens_used), pccode, compact, gens_used, desc))
print("PC reps loaded in", walltime() - t0)

# Get minimal permutation presentations from the minreps folder
minrep = {}
for label in os.listdir(opj("DATA", "minreps")):
    with open(opj("DATA", "minreps", label)) as F:
        line = F.read().strip()
        if line.count("|") == 2:
            orig, d, gens = line.split("|")
        elif line.count("|") == 3:
            duplabel, orig, d, gens = line.split("|")
            assert label == duplabel
        gens = gens.replace("{", "").replace("}", "")
        if "T" in orig and orig.split("T")[0] == d:
            desc = orig
            i = int(orig.split("T")[1])
        else:
            # Might actually be transitive, but it should show up as a T-label if d<48 and d!=32
            desc = f"{d}Perm{gens}"
            i = 1000000
        d = int(d)
        minrep[label] = (d, desc, gens)
        aliases[label]["Perm"].append((d, i, desc))
print("Minreps loaded in", walltime() - t0)

# Get set of abelian labels
with open(opj("DATA", "abelian.txt")) as F:
    ab = set(F.read().strip().split("\n"))

# Pick best representative in each category
# Abelian always PC
# Use permutations for Sn and An
# Use group of Lie type
# Then compare (#gen for pc) to (deg of permrep)^3/5 to (deg of matrix group), choosing smallest, with a penalty for more complicated coefficient rings, favoring PC to Perm to Mat in case of tie
best_of_breed = {}
best_of_show = {}
def sort_key(item):
    typ, vec = item
    n = vec[0]
    if typ == "Lie":
        # We use the sort key from liegens
        desc = vec[-1]
        explicit_desc = liegens[desc]
        newitem = sortvec_from_desc(explicit_desc)
        return sort_key(newitem)
    elif typ == "PC":
        return (n,) + (0,) + vec[1:]
    elif typ == "Perm":
        return (n**0.6,) + (1,) + vec[1:]
    elif typ == "GLZ":
        return (n,) + (2,) + vec[1:]
    elif typ == "GLFp":
        return (n,) + (3,) + vec[1:]
    elif typ == "GLZq":
        return (n+1,) + (4,) + vec[1:]
    elif typ == "GLZN":
        return (n+2,) + (5,) + vec[1:]
    elif typ == "GLFq":
        return (n+2,) + (6,) + vec[1:]
    else:
        raise NotImplementedError

special_names = []
problems = []
for label, D in aliases.items():
    B = best_of_breed[label] = {typ: min(opts) for typ, opts in D.items()}
    if label in ab:
        best_of_show[label] = ("PC", B["PC"][-1])
    elif label in An or label in Sn:
        best_of_show[label] = ("Perm", B["Perm"][-1])
        if label in An:
            family, n = "A", An[label]
        else:
            family, n = "S", Sn[label]
        special_names.append({"family": family, "parameters": {"n": n}, "label": label})
    else:
        opts = sorted(B.items(), key=sort_key)
        best = opts[0]
        typ = best[0]
        desc = best[1][-1]
        if typ in ["GLZN", "GLZq"]:
            # Want a better type to compute with; it would be nice to know if PC or Perm was the better choice
            if "PC" in B:
                comp = B["PC"][-1]
            elif "Perm" in B:
                comp = B["Perm"][-1]
            else:
                problems.append(label)
                comp = desc
            best_of_show[label] = (typ, f"{comp}---->{desc}")
        else:
            if typ == "Lie":
                # We make sure that the chosen description is first in aliases[label]["Lie"]
                lies = aliases[label]["Lie"]
                for i in range(len(lies)):
                    if lies[i][-1] == desc:
                        first = lies.pop(i)
                        aliases[label]["Lie"] = [first] + lies
                        break
            best_of_show[label] = (typ, desc)

# Find smallest degree transitive permutation representations
smalltrans = {}
for label, tbnd in tbound.items():
    N = ZZ(label.split(".")[0])
    if tbnd <= sibling_bound.get(label, 0) or N.valuation(2) < 5: # 32 is the only degree where our list is not complete
        smalltrans[label] = tbnd

# NEED
# Double check output of Minrep using intransitive and transitive groups
# Redo GL(n,Z) and small matrix representations for orders already in the LMFDB

def texify_lie(desc):
    cmd = desc.split("(")[0]
    nq = desc.split("(")[1].split(")")[0]
    n, q = [c.strip() for c in nq.split(",")]
    if len(n) > 1:
        n = "{%s}" % n
    if len(q) > 1:
        q = "{%s}" % q
    return fr"\{cmd}_{n}(\mathbb{{F}}_{q})"
def namify_sporchev(desc):
    if desc == "Chev2F,4,2-D": # Tits group
        return "2F(4,2)'"
    elif desc.startswith("Chev"):
        typ, n, q = desc[4:].split(",")
        return f"{typ}({n},{q})"
    return desc # sporadic
def texify_sporchev(desc):
    if desc == "Chev2F,4,2-D": # Tits group
        return "2F(4,2)'"
    elif desc.startswith("Chev"):
        typ, n, q = desc[4:].split(",")
        if typ[0].isdigit():
            typ = "{}^%s%s" % (typ[0], typ[1:])
        return f"{typ}_{n}({q})"
    elif desc[-1].isidigt():
        return r"\operatorname{" + desc[:-1] + "}_" + desc[-1]
    return r"\operatorname{" + desc + "}"

to_add = {}
HASH_LOOKUP = defaultdict(list)
PRELOAD = {}
with open(opj("DATA", "to_add.txt")) as F:
    for line in F:
        line = line.strip()
        if " " in line:
            label, hsh, disp, comp = line.strip().split()
            small = label.split(".")[1].isdigit()
        else:
            small = True
            disp = comp = label = line
            N, hsh = label.split(".")
        if not small and hsh != r"\N":
            os.makedirs(opj("DATA", "hash_lookup", str(N)), exist_ok=True)
            #with open(opj("DATA", "hash_lookup", str(N), str(hsh)), "a") as F:
            #    _ = F.write(label + "\n")
            HASH_LOOKUP[N, hsh].append(label)
        bob = best_of_breed[label]
        bos = best_of_show[label]
        special_names.extend([{"family": desc.split("(")[0], "parameters": {"n": n, "q": q}, "label": label} for (n, code, q, cmd, desc) in aliases[label].get("Lie", [])])
        preload = {"label": label, "hash": hsh}
        # We want to recompute transitive_degree but not permutation_degree
        if label in smalltrans:
            preload["transitive_degree"] = str(smalltrans[label])
        preload["permutation_degree"] = str(minrep.get(label, (r"\N",))[0])
        preload["linQ_degree"] = str(bob.get("GLZ", (r"\N",))[0])
        if label in slookup and slookup[label][3]:
            preload["pc_rank"] = str(len(slookup[label][2]))
        else:
            preload["pc_rank"] = r"\N"
        preload["element_repr_type"] = bos[0]
        preload["representations"] = make_representations_dict(bob, aliases[label].get("Lie"))
        if bos[0] == "Lie":
            preload["name"] = bos[1]
            preload["tex_name"] = texify_lie(bos[1])
        elif label in spor_chev:
            desc = spor_chev[label]
            preload["name"] = namify_sporchev(desc)
            preload["tex_name"] = texify_sporchev(desc)
        if label in aut:
            preload["aut_group"] = aut[label]
            preload["aut_order"] = aut[label].split(".")[0]
        # Also linC_degree, linFp_degree, linFq_degree
        PRELOAD[label] = preload
        to_add[label] = bos[1]
        #with open(opj("DATA", "descriptions", label), "w") as F:
        #    _ = F.write(bos[1])
print("Finished in", walltime() - t0)
