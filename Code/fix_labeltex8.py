# Generate input files for LoadSubgroupLattice
import time
from collections import defaultdict
sys.path.append("/home/roed/lmfdb")
from lmfdb import db

def unbooler(x):
    if x is True:
        return "t"
    elif x is False:
        return "f"
    elif x is None:
        return r"\N"
    raise RuntimeError

pcredo = set()
with open("/home/roed/pcfixed.txt") as F:
    for line in F:
        pcredo.add(line.split("|")[0])
charfix = {}
for label in os.listdir("/scratch/grp/char_check"):
    with open("/scratch/grp/char_check/"+label) as F:
        for line in F:
            ambient, run, short_label, correct = line.strip().split("|")
            full_label = f"{ambient}.{short_label}"
            charfix[full_label] = (correct == "t")
print("PREP finished")

subs = defaultdict(list)
lookup = defaultdict(dict)
subdata = defaultdict(dict)
t0 = time.time()
for i, rec in enumerate(db.gps_subgroups.search({}, ["label", "short_label", "ambient", "generators", "normal", "characteristic", "contained_in", "contains", "normal_closure", "count", "conjugacy_class_count"])):
    if i and i%500000 == 0:
        print(f"{i}({time.time()-t0:.1f})")
        t0 = time.time()
    ambient = rec["ambient"]
    label = rec["label"]
    short_label = rec["short_label"]
    subs[ambient].append(short_label)
    lookup[ambient][short_label] = len(subs[ambient])
    subdata[ambient][short_label] = (rec["generators"], rec["normal"], rec["characteristic"], rec["contained_in"], rec["contains"], rec["normal_closure"], rec["count"], rec["conjugacy_class_count"])

print("SUBDATA finished")
for i, rec in enumerate(db.gps_groups.search({}, ["label", "outer_equivalence", "subgroup_inclusions_known", "subgroup_index_bound", "complements_known", "normal_subgroups_known"])):
    ambient = rec["label"]
    if ambient in pcredo:
        continue
    if i and i%50000 == 0:
        print("W{i}({time.time()-t0:.1f)")
        t0 = time.time()
    with open("/scratch/grp/relabel2/"+ambient, "w") as F:
        oe = unbooler(rec["outer_equivalence"])
        sik = unbooler(rec["subgroup_inclusions_known"])
        sib = str(rec["subgroup_index_bound"])
        ck = unbooler(rec["complements_known"])
        nsk = unbooler(rec["normal_subgroups_known"])
        _ = F.write(f"{oe}|{sik}|{ck}|{nsk}\n{sib}\n")
        for short_label in subs[ambient]:
            label = f"{ambient}.{short_label}"
            gens, normal, characteristic, overs, unders, nc, subcnt, cccnt = subdata[ambient][short_label]
            if label in charfix:
                characteristic = charfix[label]
            gens = "{" + ",".join(str(c) for c in gens) + "}"
            normal = unbooler(normal)
            characteristic = unbooler(characteristic)
            if overs is None:
                overs = r"\N"
            else:
                overs = "{" + ",".join(str(lookup[ambient][o]) for o in overs) + "}"
            if unders is None:
                unders = r"\N"
            else:
                unders = "{" + ",".join(str(lookup[ambient][u]) for u in unders) + "}"
            if nc is None:
                nc = r"\N"
            else:
                nc = str(lookup[ambient][nc])
            _ = F.write(f"{label}|{gens}|{normal}|{characteristic}|{overs}|{unders}|{nc}|{subcnt}|{cccnt}\n")
