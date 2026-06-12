from pathlib import Path
from collections import defaultdict
import time

print("STARTING LABELTEX6")

subools = {}
SUBOOL = Path("/scratch/grp/subool")
for fname in SUBOOL.iterdir():
    with open(fname) as F:
        for line in F:
            slabel, data = line.strip().split("|",1)
            # agp, zgp, ma, mc, ssolv, simp, qnil, qagp, qma, qssolv, qsimp
            # Agroup, Zgroup, metabelian, metacyclic, supersolvable, simple, quotient_nilpotent, quotient_Agroup, quotient_metabelian, quotient_supersolvable, quotient_simple
            subools[slabel] = data
print("SUBOOL finished")
# TODO: Redo subool for pcfix

charfix = {}
CHAR = Path("/scratch/grp/char_check")
for fname in CHAR.iterdir():
    with open(fname) as F:
        for line in F:
            ambient, run, short_label, correct = line.strip().split("|")
            full_label = f"{ambient}.{short_label}"
            assert correct in "tf"
            charfix[full_label] = (correct == "t")
print("CHAR finished")

tex = {}
subtex = {}
quotex = {}
TEX = Path("/scratch/grp/texfix/UpdatedTexNames.txt")
with open(TEX) as F:
    for line in F:
        label, t = line.strip().split("|")
        tex[label] = t
SUBTEX = Path("/scratch/grp/texfix/UpdatedSubTexNames.txt")
with open(SUBTEX) as F:
    for line in F:
        label, t = line.strip().split("|")
        subtex[label] = t
QUOTEX = Path("/scratch/grp/texfix/UpdatedQuoTexNames.txt")
with open(QUOTEX) as F:
    for line in F:
        label, t = line.strip().split("|")
        quotex[label] = t
print("TEX finished")

hashes = {}
GROUP_IN = Path("/scratch/grp/bigfix/gps_groups1.txt")
GROUP_OUT = Path("/scratch/grp/bigfix/gps_groups2.txt")
GPTEX_OUT = Path("/scratch/grp/bigfix/GpTexInfo.txt")
tex_header = ["label", "tex_name", "name", "lie", "order", "cyclic", "abelian", "smith_abelian_invariants", "direct_factorization", "wreath_data"]
broken_aut = []
broken_outer = []
#special = defaultdict(dict)
with open(GROUP_OUT, "w") as Fout:
    with open(GPTEX_OUT, "w") as Ftex:
        with open(GROUP_IN) as F:
            for i, line in enumerate(F):
                cols = line.strip().split("|")
                if i == 0:
                    header = cols
                elif i > 2:
                    rec = dict(zip(header, cols))
                    label = rec["label"]
                    hashes[label] = rec["hash"]
                    if rec["aut_group"] != r"\N" and rec["aut_group"].split(".")[0] != rec["aut_order"]:
                        rec["aut_group"] = r"\N"
                        broken_aut.append(label)
                    if rec["outer_group"] != r"\N" and rec["outer_group"].split(".")[0] != rec["outer_order"]:
                        rec["outer_group"] = r"\N"
                        broken_outer.append(label)
                    #if rec["center_label"] != r"\N":
                    #    special[label]["Z"] = rec["center_label"]
                    #if rec["commutator_label"] != r"\N":
                    #    special[label]["D"] = rec["commutator_label"]
                    #if rec["frattini_label"] != r"\N":
                    #    special[label]["Phi"] = rec["frattini_label"]
                    #if rec["central_quotient"] != r"\N":
                    #    special[label]["ZQ"] = rec["central_quotient"]
                    #if rec["abelian_quotient"] != r"\N":
                    #    special[label]["DQ"] = rec["abelian_quotient"]
                    #if rec["frattini_quotient"] != r"\N":
                    #    special[label]["PhiQ"] = rec["frattini_quotient"]
                    line = "|".join(rec[col] for col in header) + "\n"

                    texrec = dict(rec)
                    if "Lie" in rec["representations"]:
                        texrec["lie"] = str(sage_eval(rec["representations"]).get("Lie", [])).replace(" ", "")
                    else:
                        texrec["lie"] = "[]"
                    texrec["name"] = r"\N"
                    _ = Ftex.write("|".join(texrec[col] for col in tex_header) + "\n")
                _ = Fout.write(line)
print("GROUP finished")

broken_sub = []
broken_quo = []
#broken_special = defaultdict(list)
#weird_special = defaultdict(lambda:defaultdict(list))
broken_weyl = []
uhoh = set()
missing_cent = set()
t0 = time.time()
SUB_OUT = Path("/scratch/grp/bigfix/gps_subgroups2.txt")
SUB_IN = Path("/scratch/grp/bigfix/gps_subgroups1.txt")
SUBTEX_OUT = Path("/scratch/grp/bigfix/GpTexInfo.txt")
subtex_header = ["label", "short_label", "subgroup", "ambient", "quotient", "subgroup_tex", "ambient_tex", "quotient_tex", "subgroup_order", "quotient_order", "split", "direct"]
with open(SUB_OUT, "w") as Fout:
    with open(SUBTEX_OUT, "w") as Ftex:
        with open(SUB_IN) as F:
            for i, line in enumerate(F):
                cols = line.strip().split("|")
                if i == 0:
                    header = cols
                    new_header = header
                    #new_header = header + ["normalizer_order", "normalizer_index", "Agroup", "Zgroup", "metabelian", "metacyclic", "supersolvable", "simple", "quotient_nilpotent", "quotient_Agroup", "quotient_metabelian", "quotient_supersolvable", "quotient_simple"]
                    #line = "|".join(new_header) + "\n"
                #elif i == 1:
                #    line = "|".join(cols + 
                elif i > 2:
                    if i and i%500000 == 0:
                        print(f"{i // 500000}({time.time()-t0:.1f})")
                        t0 = time.time()
                    rec = dict(zip(header, cols))
                    label = rec["label"]
                    ambient, amb = rec["ambient"], ZZ(rec["ambient_order"])
                    sub, subord, shash, quo, quoord, qhash = rec["subgroup"], ZZ(rec["subgroup_order"]), rec["subgroup_hash"], rec["quotient"], ZZ(rec["quotient_order"]), rec["quotient_hash"]
                    if subord == 1:
                        rec["hall"] = rec["sylow"] = "1"
                    elif subord.gcd(quoord) == 1:
                        r = subord.radical()
                        rec["hall"] = str(r)
                        if r.is_prime():
                            rec["sylow"] = str(r)
                        else:
                            rec["sylow"] = "0"
                    else:
                        rec["hall"] = rec["sylow"] = "0"

                    if sub != r"\N":
                        sord = int(sub.split(".")[0])
                        if sord != subord or shash != r"\N" and sub in hashes and hashes[sub] != shash:
                            broken_sub.append(label)
                            rec["subgroup"] = r"\N"
                            # SAVE generators in a place we can try labeling?
                    if quo != r"\N":
                        qord = int(quo.split(".")[0])
                        if qord != quoord or qhash != r"\N" and quo in hashes and hashes[quo] != qhash:
                            broken_quo.append(label)
                            rec["quotient"] = r"\N"
                            # SAVE generators in a place we can try labeling?

                    norm = rec["normalizer"]
                    if norm == r"\N":
                        if rec["normal"] == "t":
                            rec["normalizer_index"] = "1"
                        else:
                            rec["normalizer_index"] = r"\N"
                    else:
                        nind = int(norm.split(".")[0])
                        if amb % nind != 0:
                            uhoh.add(label)
                        nord = amb // nind
                        rec["normalizer_index"] = str(nind)
                        cent = rec["centralizer"]
                        cord = rec["centralizer_order"]
                        if cent != r"\N":
                            cind = int(cent.split(".")[0])
                            if cord == r"\N":
                                missing_cent.add(label)
                                cord = amb // cind
                            if cind * int(cord) != amb:
                                uhoh.add(label)
                        weyl = rec["weyl_group"]
                        if weyl != r"\N" and cord != r"\N":
                            word = int(weyl.split(".")[0])
                            if word * int(cord) != nord:
                                broken_weyl.append(label)
                                rec["weyl_group"] = r"\N"

                    #spec = rec["special_labels"]
                    #if spec != "{}":
                    #    spec = spec[1:-1].split(",")
                    #    for code in ["Z", "D", "Phi"]:
                    #        if code in spec:
                    #            if code in special[ambient]:
                    #                if broken_sub and broken_sub[-1] == label:
                    #                    broken_special[ambient].append(code)
                    #                if sub != r"\N" and sub != special[ambient][code]:
                    #                    weird_special[code][ambient].append((label, sub, special[ambient][code]))
                    #            if code+"Q" in special[ambient]:
                    #                if broken_quo and broken_quo[-1] == label:
                    #                    broken_special[ambient].append(code+"Q")
                    #                if quo != r"\N" and quo != special[ambient][code+"Q"]:
                    #                    weird_special[code+"Q"][ambient].append((label, quo, special[ambient][code+"Q"]))

                    line = "|".join(rec[col] for col in new_header) + "\n"

                    texrec = dict(rec)
                    texrec["subgroup_tex"] = subtex.get(label, r"\N")
                    texrec["quotient_tex"] = quotex.get(label, r"\N")
                    _ = Ftex.write("|".join(texrec[col] for col in subtex_header) + "\n")
                _ = Fout.write(line)
print("SUB finished")

