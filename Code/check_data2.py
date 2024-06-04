# Functions for creating the input files needed to run CheckData2.m from postgres
# Should be attached either after appending the path to the lmfdb installtion to sys.path,
# or from within the lmfdb folder

import os
opj = os.path.join
import re

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
    for rec in db.gps_groups.search({}, ["label", "element_repr_type", "hash", "representations", "aut_gens", "outer_equivalence", "subgroup_inclusions_known", "subgroup_index_bound", "complements_known", "normal_subgroups_known"]):
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
        reps = rec["representations"]
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
            cur_ambient = rec["group"]
        cur_lines.append("|".join(["J"+rec["label"], str(rec["size"]), str(rec["order"]), str(rec["representative"])]))
    write(cur_ambient, cur_lines)
    return bad_ert

perm_re = re.compile(r"[ASM]\d+")
pc_re = re.compile(r"(C|D|F|Q|SD|OD|He)\d+")
lie_re = re.compile(r"(SL|PSL|GL|PGL|SO|PSO|Omega|Sp|PSp|SU|PSU|GU|PGU)[+\-]?\(\d+,\d+\)")
lie_re = re.compile(r"(SL|GL|PSL|PGL|SO|PSO|Omega|GO|PGO|CO|CSO|Spin|Sp|PSp|CSp|SU|PSU|CSU|GU|PGU|CU|AGL|ASL|AGammaL|ASigmaL|ASigmaSp|PGammaL|PGammaU|PSigmaSp)[+\-]?\(\d+,\d+\)")
chev_re = re.compile(r"(?P<chev2twist>\d)?(?P<chev2family>[A-G])\((?P<chev2d>\d+),(?P<chev2q>\d+)\)'?")
spor_re = re.compile(r"(?:operatorname\{)?(?P<sporadicfamily>Ru|McL|He|J|Co|HS)\}?(?:(?P<sporadicN>\d))?")
def ert_preference(name, abelian):
    # If pattern matches on the name to see if there's an element_repr_type that users would strongly prefer
    if abelian or pc_re.fullmatch(name):
        return "PC"
    elif perm_re.fullmatch(name):
        return "Perm"
    elif lie_re.fullmatch(name):
        return "Lie"
    elif name == "GL(2,Z/4)":
        return "GLZq"
    if any(c in name for c in [".","*",":","wr","^"]) or chev_re.fullmatch(name) or spor_re.fullmatch(name):
        return None
    raise RuntimeError(name)

def check_name_ert():
    # Compare names for groups with element_repr_type, to find things like S5 displayed as PGL(2,5) instead.
    for rec in db.gps_groups.search({}, ["name", "element_repr_type", "representations", "abelian"]):
        
