# Functions for creating the input files needed to run CheckData2.m from postgres
# Should be attached either after appending the path to the lmfdb installtion to sys.path,
# or from within the lmfdb folder

import os
opj = os.path.join

from lmfdb import db

def tf(x, noneok=False):
    if x is None:
        if noneok:
            return r"\N"
        raise RuntimeError
    if x is True:
        return "t"
    if x is False:
        return "f"
    return str(x)

def RepToString(rep_type, data, N):
    def strjoin(x):
        return ",".join(str(c) for c in x)

    if rep_type == "PC":
        if "pres" in data:
            return f"{N}pc{strjoin(data['pres'])}"
        return f"{N}PC{data['code']}"
    elif rep_type == "Perm":
        return f"{data['d']}Perm{strjoin(data['gens'])}"
    elif rep_type == "GLZ":
        return f"{data['d']},0,{data['b']}MAT{strjoin(data['gens'])}"
    elif rep_type in ["GLFp", "GLZN"]:
        return f"{data['d']},{data['p']}MAT{strjoin(data['gens'])}"
    elif rep_type == "GLZq":
        return f"{data['d']},{data['q']}MAT{strjoin(data['gens'])}"
    elif rep_type == "GLFq":
        return f"{data['d']},q{data['q']}MAT{strjoin(data['gens'])}"
    elif rep_type == "Lie":
        return f"{data['family']}({data['d']},{data['q']})"
    else:
        raise RuntimeError

def create_input_files():
    seen = set()
    bad_ert = set()
    for rec in db.gps_groups.search({}, ["label", "element_repr_type", "hash", "representatives", "aut_gens", "outer_equivalence", "subgroup_inclusions_known", "subgroup_index_bound", "complements_known", "normal_subgroups_known"]):
        if rec["outer_equivalence"] is None:
            continue
        label = rec["label"]
        N = label.split(".")[0]
        seen.add(label)
        if rec["hash"] is None:
            hsh = r"\N"
        else:
            hsh = str(rec["hash"])
        if rec["aut_gens"] is None:
            aut_gens = r"\N"
        else:
            aut_gens = str(rec["aut_gens"]).replace(" ", "").replace("[", "{").replace("]", "}")
        ert = rec['element_repr_type']
        reps = rec["representatives"]
        if ert not in reps:
            bad_ert.add(label)
            continue
        if "Lie" in reps:
            # Only check the first entry
            reps["Lie"] = reps["Lie"][0]
        reps = [(ert, reps[ert])] + [(rt, D) for (rt, D) in reps.items() if rt != ert]
        reps = "|".join(RepToString(rt, D, N) for (rt, D) in reps)
        with open(opj("/scratch", "grp", "check_input", label), "w") as F:
            _ = F.write("\n".join([ert, hsh, reps, aut_gens] + [tf(rec[x]) for x in ["outer_equivalence", "subgroup_inclusions_known", "subgroup_index_bound", "complements_known", "normal_subgroups_known"]]) + "\n")
    cur_ambient = None
    cur_lines = []
    def write(amb, lines):
        with open(opj("/scratch", "grp", "check_input", amb), "a") as F:
            _ = F.write("\n".join(lines) + "\n")
    for rec in db.gps_subgroups.search({}, ["ambient", "label", "short_label", "subgroup_order", "normal", "characteristic", "generators"]):
        if rec["ambient"] != cur_ambient:
            if cur_lines:
                write(cur_ambient, cur_lines)
                cur_lines = []
            cur_ambient = rec["ambient"]
        gens = "{" + ",".join(str(gen) for gen in rec["generators"]) + "}"
        cur_lines.append("|".join(["S"+rec["label"], rec["short_label"], str(rec["subgroup_order"]), tf(rec["normal"]), tf(rec["characteristic"], noneok=True), gens]))
    write(cur_ambient, cur_lines)
    cur_ambient = None
    cur_lines = []
    for rec in db.gps_groups_cc.search({}, ["group", "label", "size", "order", "representative"], sort=["group"]):
        if rec["group"] != cur_ambient:
            if cur_lines:
                write(cur_ambient, cur_lines)
                cur_lines = []
            cur_ambient = rec["ambient"]
        cur_lines.append("|".join(["J"+rec["label"], str(rec["size"]), str(rec["order"]), str(rec["representative"])]))
    write(cur_ambient, cur_lines)
