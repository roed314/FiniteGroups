#!/usr/bin/env -S sage -python
# Create the descriptions folder

import os
import sys
opj = os.path.join

sys.path.append(os.path.expanduser(opj("~", "lmfdb")))

from lmfdb import db
from collections import defaultdict

slookup = {rec["label"]: (rec["pc_code"], None, rec["gens_used"]) for rec in db.gps_groups.search({"solvable":True}, ["label", "pc_code", "gens_used"])}
nlookup = {rec["label"]: rec["perm_gens"] for rec in db.gps_groups.search({"solvable":False}, ["label", "perm_gens"])}
print("LMFDB data loaded")

os.makedirs(opj("DATA", "descriptions"), exist_ok=True)
os.makedirs(opj("DATA", "preload"), exist_ok=True)

aliases = defaultdict(list)
aut = {}
with open(opj("DATA", "aliases.txt")) as F:
    for line in F:
        label, desc = line.strip().split()
        if desc.endswith("-A"):
            G0 = desc[:-2]
            assert G0 not in aut
            aut[G0] = label
        else:
            aliases[label].append(desc)
print("Aliases loaded")

# Get polycyclic presentations from the pcreps folders
def getpc(F):
    pccode, gens_used, compact, backiso = F.read().strip().split("|")
    gens_used = [int(c) for c in gens_used.split(",")]
    return pccode, compact, gens_used

for label in os.listdir(opj("DATA", "pcreps")):
    assert label not in slookup
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
print("PC reps loaded")

# Get minimal permutation presentations from the minreps folder
minrep = {}
for label in os.listdir(opj("DATA", "minreps")):
    with open(opj("DATA", "minreps", label)) as F:
        desc, d, gens = F.read().strip().split("|")
        d = int(d)
        gens = gens.replace("{", "").replace("}", "").split(",")
        minrep[label] = (d, desc, gens)
print("Minreps loaded")

unknown_pcrep = []
to_add = {}
with open(opj("DATA", "to_add.txt")) as F:
    for line in F:
        if " " in line:
            label, hsh, disp, comp = line.strip().split()
        else:
            label = line.strip()
            hsh = label.split(".")[1]
            if label not in slookup and label not in nlookup:
                unknown_pcrep.append(label)
            disp = comp = label
        to_add[label] = (hsh, disp, comp)
print("Finished")
