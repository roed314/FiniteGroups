from pathlib import Path

tex = {}
TEX = Path("/scratch/grp/texfix/UpdatedTexNames.txt")
with open(TEX) as F:
    for line in F:
        label, t = line.strip().split("|")
        tex[label] = t
print("TEX finished")

hashes = {}
GROUP_IN = Path("/scratch/grp/bigfix/gps_groups1.txt")
GPTEX_OUT = Path("/scratch/grp/bigfix/GpTexInfo.txt")
tex_header = ["label", "tex_name", "name", "lie", "order", "cyclic", "abelian", "smith_abelian_invariants", "direct_factorization", "wreath_data"]
with open(GPTEX_OUT, "w") as Ftex:
    with open(GROUP_IN) as F:
        for i, line in enumerate(F):
            cols = line.strip().split("|")
            if i == 0:
                header = cols
            elif i > 2:
                rec = dict(zip(header, cols))
                label = rec["label"]

                texrec = dict(rec)
                if "Lie" in rec["representations"]:
                    texrec["lie"] = str(sage_eval(rec["representations"]).get("Lie", [])).replace(" ", "")
                else:
                    texrec["lie"] = "[]"
                texrec["tex_name"] = tex.get(label, r"\N")
                texrec["name"] = r"\N"
                texrec["smith_abelian_invariants"] = texrec["smith_abelian_invariants"].replace("{","[").replace("}", "]")
                wd = texrec["wreath_data"]
                if wd != r"\N":
                    wd = wd[1:-1].split(",")
                    for j in range(len(wd)):
                        wd[j] = '"' + wd[j].replace('"', '') + '"'
                    texrec["wreath_data"] = "[" + ",".join(wd) + "]"
                _ = Ftex.write("|".join(texrec[col] for col in tex_header) + "\n")
print("GROUP finished")
