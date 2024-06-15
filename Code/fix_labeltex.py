# This file contains code that was run to repair invalid data in labeling subgroups and quotients, together with resulting problems in name and tex_name


import time
from collections import defaultdict
broken_aut = []
broken_outer = []
special = defaultdict(dict)
for rec in db.gps_groups.search({}, ["label", "aut_group", "aut_order", "outer_group", "outer_order", "commutator_label", "abelian_quotient", "center_label", "central_quotient", "frattini_label", "frattini_quotient"]):
    label = rec["label"]
    if rec["aut_group"] is not None and ZZ(rec["aut_group"].split(".")[0]) != rec["aut_order"]:
        broken_aut.append(label)
    if rec["outer_group"] is not None and ZZ(rec["outer_group"].split(".")[0]) != rec["outer_order"]:
        broken_outer.append(label)
    if rec["center_label"] is not None:
        special[label]["Z"] = rec["center_label"]
    if rec["commutator_label"] is not None:
        special[label]["D"] = rec["commutator_label"]
    if rec["frattini_label"] is not None:
        special[label]["Phi"] = rec["frattini_label"]
    if rec["central_quotient"] is not None:
        special[label]["ZQ"] = rec["central_quotient"]
    if rec["abelian_quotient"] is not None:
        special[label]["DQ"] = rec["abelian_quotient"]
    if rec["frattini_quotient"] is not None:
        special[label]["PhiQ"] = rec["frattini_quotient"]

pcredo = set()
with open("/home/roed/pcfixed.txt") as F:
    for line in F:
        pcredo.add(line.split("|")[0])
hashes = {}
samehash = set()
for rec in db.gps_groups.search({}, ["label", "hash"]):
    if rec["hash"] is not None:
        hashes[rec["label"]] = rec["hash"]
        ii = rec["label"].split(".")[1]
        if ii.isdigit() and rec["hash"] == int(ii):
            samehash.add(rec["label"])
broken_sub = []
broken_quo = []
broken_special = defaultdict(list)
weird_special = defaultdict(lambda:defaultdict(list))
broken_weyl = []
uhoh = set() # unneeded
missing_cent = set() # unneeded
subdata = {}
t0 = time.time()
for i, rec in enumerate(db.gps_subgroups.search({}, ["label", "ambient", "ambient_order", "subgroup", "subgroup_order", "subgroup_hash", "quotient", "quotient_order", "quotient_hash", "normal", "weyl_group", "normalizer", "centralizer", "centralizer_order", "special_labels"])):
    if i and i%500000 == 0:
        print(f"{i // 500000}({time.time()-t0:.1f})")
        t0 = time.time()
    label = rec["label"]
    ambient, amb = rec["ambient"], rec["ambient_order"]
    subdata[label] = rec
    sub, subord, shash, quo, quoord, qhash = rec["subgroup"], ZZ(rec["subgroup_order"]), rec["subgroup_hash"], rec["quotient"], ZZ(rec["quotient_order"]), rec["quotient_hash"]
    if subord == 1:
        rec["hall"] = rec["sylow"] = 1
    elif subord.gcd(quoord) == 1:
        rec["hall"] = r = subord.radical()
        if r.is_prime():
            rec["sylow"] = r
        else:
            rec["sylow"] = 0
    else:
        rec["hall"] = rec["sylow"] = 0

    if sub is not None:
        sord = int(sub.split(".")[0])
        if sord != subord or shash is not None and sub in hashes and hashes[sub] != shash and ambient not in pcredo:
            broken_sub.append(label)
    if quo is not None:
        qord = int(quo.split(".")[0])
        if qord != quoord or qhash is not None and quo in hashes and hashes[quo] != qhash and ambient not in pcredo:
            broken_quo.append(label)
    norm = rec["normalizer"]
    if norm is None:
        if rec["normal"]:
            rec["normalizer_index"] = 1
        else:
            rec["normalizer_index"] = None
    else:
        nind = int(norm.split(".")[0])
        if amb % nind != 0:
            uhoh.add((label,"norm"))
        nord = amb // nind
        rec["normalizer_index"] = nind
        cent = rec["centralizer"]
        cord = rec["centralizer_order"]
        if cent is not None:
            cind = int(cent.split(".")[0])
            if cord is None:
                missing_cent.add(label)
                cord = amb // cind
            if cind * cord != amb:
                uhoh.add((label,"cent"))
        weyl = rec["weyl_group"]
        if weyl is not None and cord is not None:
            word = int(weyl.split(".")[0])
            if word * cord != nord:
                broken_weyl.append(label)
    spec = rec["special_labels"]
    if spec == [""]:
        rec["special_labels"] = []
    elif spec:
        for code in ["Z", "D", "Phi"]:
            if code in spec:
                if code in special[ambient]:
                    if broken_sub and broken_sub[-1] == label:
                        broken_special[ambient].append(code)
                    if sub is not None and sub != special[ambient][code]:
                        weird_special[code][ambient].append((label, sub, special[ambient][code]))
                if code+"Q" in special[ambient]:
                    if broken_quo and broken_quo[-1] == label:
                        broken_special[ambient].append(code+"Q")
                    if quo is not None and quo != special[ambient][code+"Q"]:
                        weird_special[code+"Q"][ambient].append((label, quo, special[ambient][code+"Q"]))

# Fix weird
#new_weird = defaultdict(lambda: defaultdict(list))
#weird_labels = set()
#for vvv in weird_special.values():
#    for (label, x, y) in vvv:
#        weird_labels.add(label)
#for label in weird_labels:
#    rec = subdata[label]
#    ambient = rec["ambient"]
#    sub, subord, shash, quo, quoord, qhash = rec["subgroup"], ZZ(rec["subgroup_order"]), rec["subgroup_hash"], rec["quotient"], ZZ(rec["quotient_order"]), rec["quotient_hash"]
#    spec = rec["special_labels"]
#    if spec:
#        for code in ["Z", "D", "Phi"]:
#            if code in spec:
#                if code in special[ambient]:
#                    if sub is not None and sub != special[ambient][code]:
#                        new_weird[code][ambient].append((label, sub, special[ambient][code]))
#                if code+"Q" in special[ambient]:
#                    if quo is not None and quo != special[ambient][code+"Q"]:
#                        new_weird[code+"Q"][ambient].append((label, quo, special[ambient][code+"Q"]))

# Load subool and char_check data
for label in os.listdir("/scratch/grp/subool"):
    with open("/scratch/grp/subool/"+label) as F:
        for line in F:
            slabel, data = line.strip().split("|",1)
            subdata[slabel]["bools"] = data
charfix = {}
for label in os.listdir("/scratch/grp/char_check"):
    with open("/scratch/grp/char_check/"+label) as F:
        for line in F:
            ambient, run, short_label, correct = line.strip().split("|")
            full_label = f"{ambient}.{short_label}"
            charfix[full_label] = (correct == "t")

# Get generators in cases where special seems messed up
special_gens = defaultdict(dict)
char_gens = defaultdict(list)
t0 = time.time()
for i, rec in enumerate(db.gps_subgroups.search({}, ["ambient", "label", "special_labels", "generators", "characteristic"])):
    if i and i%500000 == 0:
        print(f"{i//500000}({time.time()-t0:.1f})")
        t0 = time.time()
    spec = rec["special_labels"]
    label = rec["label"]
    if spec:
        for code in ["Z", "D", "Phi"]:
            if code in spec:
                special_gens[rec["ambient"]][code] = (label, rec["generators"])
    correct_char = rec["characteristic"]
    if label in charfix:
        correct_char = charfix[label]
    subdata[label]["characteristic"] = correct_char
    if correct_char:
        char_gens[rec["ambient"]].append((label, rec["generators"]))

# Write input files for CheckSpecial.m
todo_special = set()
for x in ["in", "out"]:
    os.makedirs(f"/home/roed/FiniteGroups/Code/DATA/check_special_{x}", exist_ok=True)
for code, A in weird_special.items():
    for ambient in A:
        todo_special.add(ambient)
for ambient in todo_special:
    with open("/home/roed/FiniteGroups/Code/DATA/check_special_in/" + ambient, "w") as F:
        for code in ["Z", "D", "Phi"]:
            slabel, gens = special_gens[ambient].get(code, (r"\N", r"\N"))
            if gens != r"\N":
                gens = ",".join(str(c) for c in gens)
            sublabel = special[ambient].get(code, r"\N")
            quolabel = special[ambient].get(code+"Q", r"\N")
            _ = F.write(f"{code}|{slabel}|{sublabel}|{quolabel}|{gens}\n")

# Load original latex names
# This relies on functions from an attached cloud_collect.py
t0 = time.time()
tex_name = defaultdict(set)
tex_subdata = defaultdict(set)
with open("/home/roed/FiniteGroups/Code/subagg1.tmpheader") as F:
    head = F.read().strip().split("\n")[1].split("|")
    inds = [head.index(col) for col in ["label", "short_label", "ambient", "subgroup_tex", "ambient_tex", "quotient_tex", "subgroup_order", "quotient_order", "split", "direct"]]
for folder in os.listdir("/scratch/grp/"):
    print(f"Starting {folder} at time {time.time()-t0}")
    def process_file(path):
        with open(path) as F:
            for line in F:
                code = line[0]
                if code in "tS":
                    ambient, data = line[1:].split("|",1)
                    ambient = ambient.split("(")[0]
                    if code == "t":
                        name, tex = data.strip().split("|")
                        tex_name[ambient].add(tex)
                    else:
                        pieces = line[1:].strip().split("|")
                        pieces = tuple(pieces[i] for i in inds)
                        slabel = pieces[0]
                        tex_subdata[slabel].add(pieces)
    if any(folder.startswith(h) for h in ["15", "60", "fixsmall", "highmem", "lowmem", "noaut", "sopt", "tex", "Xrun", "last"]):
        for sub in os.listdir(folder):
            if sub == "raw":
                for fname in os.listdir(opj(folder, "raw")):
                    if fname.startswith("grp-") and fname.endswith(".txt"):
                        process_file(opj("/scratch/grp", folder, "raw", fname))
            elif sub.startswith("output"):
                process_file(opj("/scratch/grp", folder, sub))

tex_name1 = {}
for label, texs in tex_name.items():
    texs = [x.replace("\\\\", "\\") for x in texs]
    if len(texs) > 1:
        texs = [tokenize(t) for t in texs]
        for t in texs:
            fix_latex(t)
        texs = [parse_tokens(t) for t in texs]
        texs.sort(key=lambda t: (t.value, t.latex))
        texs = [t.latex for t in texs]
    tex_name1[label] = texs[0]

tex_subname1 = {}
tex_quoname1 = {}
missing_ambient = []
def choose_one_tex(texs):
    if len(texs) > 1:
        texs = [tokenize(t) for t in texs]
        for t in texs:
            fix_latex(t)
        texs = [parse_tokens(t) for t in texs]
        texs.sort(key=lambda t: (t.value, t.latex))
        texs = [t.latex for t in texs]
    return texs[0]
for label, tups in tex_subdata.items():
    s = set()
    q = set()
    for tup in tups:
        _, short_label, ambient, subgroup_tex, ambient_tex, quotient_tex, subgroup_order, quotient_order, split, direct = tup
        if subgroup_tex != r"\N":
            s.add(subgroup_tex.replace("\\\\", "\\"))
        if quotient_tex != r"\N":
            q.add(quotient_tex.replace("\\\\", "\\"))
        if ambient_tex != r"\N" and ambient_tex not in tex_name[ambient]:
            missing_ambient.append((label, ambient, ambient_tex, tex_name[ambient]))
    if s:
        tex_subname1[label] = choose_one_tex(list(s))
    if q:
        tex_quoname1[label] = choose_one_tex(list(q))

# Load from /scratch/grp/subtex
new_subtex = {}
new_quotex = {}
for ambient in os.listdir("/scratch/grp/subtex/subout"):
    with open("/scratch/grp/subtex/subout/"+ambient) as F:
        for line in F:
            slabel, stex = line.strip().split("|")
            new_subtex[slabel] = stex
for ambient in os.listdir("/scratch/grp/subtex/quoout"):
    with open("/scratch/grp/subtex/quoout/"+ambient) as F:
        for line in F:
            slabel, qtex = line.strip().split("|")
            new_quotex[slabel] = qtex

for (D, new) in [(tex_subname1, new_subtex), (tex_quoname1, new_quotex)]:
    for label, x in new:
        y = D.get(label)
        if y is not None:
            texs = [tokenize(t) for t in [x, y]]
            for t in texs:
                fix_latex(t)
            texs = [parse_tokens(t) for t in texs]
            texs.sort(key=lambda t: (t.value, t.latex))
            y = texs[0].latex
            D[label] = y

def _make_gps_data_file():
    fname = f"GpTexInfo.txt"
    with open(fname, "w") as Fout:
        for rec in db.gps_groups.search({}, ["label", "representations", "order", "cyclic", "abelian", "smith_abelian_invariants", "direct_factorization", "wreath_data"]):
            label, order = rec["label"], rec["order"]
            cyclic, abelian = unbooler(rec["cyclic"]), unbooler(rec["abelian"])
            representations = unnone(rec["representations"])
            smith = unnone(rec["smith_abelian_invariants"])
            direct = unnone(rec["direct_factorization"])
            wreath = unnone(rec["wreath_data"])
            _ = Fout.write(f"{label}|{tex_name1[label]}|\\N|{representations}|{order}|{cyclic}|{abelian}|{smith}|{direct}|{wreath}\n")



#sage: Counter(x[0] for x in noted)
#Counter({'Phi': 98, 'PhiQ': 95, 'PhiG': 25, 'ZQ': 1, 'D': 1})
#[('ZQ', '81920.dml'), ('D', '31104.el')] should be \N, \N
# Load output files from CheckSpecial.m
#ope = os.path.exists
#for ambient in todo_special:
#    fname = "DATA/check_special_out/" + ambient
#    if ope(fname):
#        with open(fname) as F:
#            pass

# Fix broken frattini_label, frattini_quotient (plus the one central_quotient and commutator_label)
# Upload subool, characteristic, sylow, hall, normalizer_order from subdata
# Write tex input files, then run 
