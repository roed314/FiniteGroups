#!/usr/bin/env -S sage -python
# Create the descriptions folder

import os
import sys
opj = os.path.join
ope = os.path.exists

sys.path.append(os.path.expanduser(opj("~", "lmfdb")))

from lmfdb import db
from collections import defaultdict

slookup = {rec["label"]: (rec["pc_code"], None, rec["gens_used"]) for rec in db.gps_groups.search({"solvable":True}, ["label", "pc_code", "gens_used"])}
nlookup = {rec["label"]: rec["perm_gens"] for rec in db.gps_groups.search({"solvable":False}, ["label", "perm_gens"])}
print("LMFDB data loaded")

os.makedirs(opj("DATA", "descriptions"), exist_ok=True)
os.makedirs(opj("DATA", "preload"), exist_ok=True)
os.makedirs(opj("DATA", "pcbug.todo"), exist_ok=True)
os.makedirs(opj("DATA", "pcbugs"), exist_ok=True)

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
    "J1": [("M", 7, 11), ("T", 266, 0)],
    "J2": [("M", 6, 1000004), ("T", 100, 0)],
    "HS": [("T", 100, 0)],
    "J3": [("M", 18, 1000009)],
    "McL": [("T", 275, 0)],
    "He": [("M", 51, 2)],
    "Ru": [("M", 28, 2)],
    "Co3": [("M", 22, 2), ("T", 276, 0)],
    "Co2": [("M", 22, 2), ("T", 2300, 0)],
    "Co1": [("M", 24, 2)],
}

def update_options(D, desc):
    if "Perm" in desc:
        n = int(desc.split("Perm")[0])
        # favor transitive groups of the same degree
        D["T"].append((n, 10000000, desc))
    elif "Mat" in desc:
        d, q = desc.split("Mat")[0].split(",")
        d = int(d)
        if q.startswith("q"):
            # prefer Z/N to finite fields (easier to display)
            q = int(q[1:]) + 1000000
        else:
            q = int(q)
        D["M"].append((d, q, desc))
    elif "T" in desc:
        n, i = [int(c) for c in desc.split("T")]
        D["T"].append((n, i, desc))
    elif "(" in desc:
        d, q = [int(c) for c in desc.split("(")[1].split(")")[0].split(",")]
        D["L"].append((d, q, desc))
    elif "Perf" in desc:
        i = int(desc[4:])
        D["T"].append((Perf_lookup[i], 5000000, desc))
    elif "Chev" in desc:
        typ, q = desc[4:].rsplit(",", 1)
        d, k = Chev_lookup[typ]
        q = int(q.replace("-D", ""))**k # remove derived subgroup code for 2F(4,2)-D
        if q not in [2, 3, 5, 7]:
            q += 1000000
        D["M"].append((d, q, desc))
    elif desc in Spor_lookup:
        for rec in Spor_lookup[desc]:
            D[rec[0]].append(rec[1:] + (desc,))
    else:
        raise ValueError("Unexpected description", desc)

aliases = defaultdict(lambda: defaultdict(list))
aut = {}
lies = set()
with open(opj("DATA", "aliases.txt")) as F:
    for line in F:
        label, desc = line.strip().split()
        if "(" in desc:
            lies.add(desc.split("(")[0])
        if desc.endswith("-A"):
            G0 = desc[:-2]
            assert G0 not in aut
            aut[G0] = label
        else:
            update_options(aliases[label], desc)
print("Aliases loaded")

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
        slookup[label] = getpc(F)
for label in os.listdir(opj("DATA", "pcreps_fast")):
    if label in slookup: continue
    with open(opj("DATA", "pcreps_fast", label)) as F:
        pccode, compact, gens_used = getpc(F)
    with open(opj("DATA", "pcreps_fastest", label)) as F:
        pccode1, compact1, gens_used1 = getpc(F)
    if len(gens_used1) < len(gens_used):
        pccode, compact, gens_used = pccode1, compact1, gens_used1
    slookup[label] = (pccode, compact, gens_used)
for label in os.listdir(opj("DATA", "pcreps_fastest")):
    if label in slookup: continue
    with open(opj("DATA", "pcreps_fastest", label)) as F:
        slookup[label] = getpc(F)
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
            pccode, compact, gens_used = slookup[label]
            if compact is None:
                slookup[label] = (pccode, data, gens_used)
        if ope(opj("DATA", "pcbug.todo", label)):
            # Magma had a bug in the loading the pccode here; we record that we have the compact presentation
            with open(opj("DATA", "pcbugs", label), "w") as Fout:
                _ = Fout.write(desc)
            os.unlink(opj("DATA", "pcbug.todo", label))
for label, (pccode, compact, gens_used) in slookup.items():
    N = label.split(".")[0]
    if compact is None:
        desc = f"{N}PC{pccode}"
    else:
        desc = f"{N}pc{compact}"
    aliases[label]["P"].append((len(gens_used), desc))
print("PC reps loaded")

# Get minimal permutation presentations from the minreps folder
minrep = {}
for label in os.listdir(opj("DATA", "minreps")):
    with open(opj("DATA", "minreps", label)) as F:
        orig, d, gens = F.read().strip().split("|")
        gens = gens.replace("{", "").replace("}", "")
        if "T" in orig and orig.split("T")[0] == d:
            desc = orig
            i = int(orig.split("T")[1])
        else:
            # Might actually be transitive...
            desc = f"{d}Perm{gens}"
            i = 1000000
        d = int(d)
        minrep[label] = (d, desc, gens)
        aliases[label]["T"].append((d, i, desc))
print("Minreps loaded")

# Pick best representative in each category
best = {}
for label, D in aliases.items():
    best[label] = {typ: min(opts) for typ, opts in D.items()}

spectrum = sorted(set((D.get("P",[0])[0], D.get("T",[0])[0], D.get("M",[0])[0], D.get("L",[0])[0]) for D in best.values()))

# NEED
# Double check output of Minrep using intransitive and transitive groups
# Redo GL(n,Z) and small matrix representations for orders already in the LMFDB

# RULES
# Abelian always PC
# Use permutations for Sn and An
# Use group of Lie type
# compare (#gen for pc) to (deg of permrep)^3/5 to (deg of matrix group), choosing smallest, favoring PC to Perm to Mat in case of tie

to_add = {}
with open(opj("DATA", "to_add.txt")) as F:
    for line in F:
        N, hsh = label.split(".")
        if " " in line:
            label, hsh, disp, comp = line.strip().split()
        else:
            label = line.strip()
            disp = comp = label
        pccode, compact, gens_used = slookup.get(label, (None, None, None))
        if pccode is None:
            # not solvable
            pc = None
        elif compact is None:
            pc = f"{N}PC{pccode}"
        else:
            pc = f"{N}pc{compact}"
        if label in minrep:
            mrep = minrep[label]
        to_add[label] = (hsh, disp, comp)
print("Finished")
