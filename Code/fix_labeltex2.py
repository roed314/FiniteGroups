# This file contains code that was run to repair invalid data in labeling subgroups and quotients, together with resulting problems in name and tex_name


import time
from collections import defaultdict
opj = os.path.join


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
        for sub in os.listdir(opj("/scratch/grp/",folder)):
            if sub == "raw":
                for fname in os.listdir(opj("/scratch/grp/",folder, "raw")):
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
            x = texs[0].latex
        D[label] = x

def _make_gps_data_file2():
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
