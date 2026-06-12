# 0. Finish computations: compute_SRB.todo, compute_CJQ.todo, pcredo (again, since labeling has been updated)
# 1. Collate computations (and db data) into folders organized by ambient group.
#    Sources: newer_30minrun, newer_60minrun, newest_60minrun, relabel.output, whereever pcredo happens.
#    Incude original latex, manual fixes (labeltex5)
# 2. Fix stuff
# a. bad labels for special subgroups in gps_groups
# b. subgroup and quotient ids with wrong order or hash
# c. sylow and hall values
# d. set normalizer_index
# e. broken weyl_group ids
# f. bad special labels (in S, have output from CheckSpecial.m)
# g. subool (load from /scratch/grp/subool, use computed B values)
# h. characteristic (load from /scratch/grp/char_check, in S)
# i. Save discarded C, J, Q
# j. Rename subgroup labels (some cases where we can find canonical labels a priori: below index bound with unique group of a given index, Sylow subgroups

import time
import os
from collections import defaultdict
from sage.misc.cachefunc import cached_function
opj = os.path.join

def original_tex():
    #with open("/home/roed/FiniteGroups/Code/subagg1.tmpheader") as F:
    #    head = F.read().strip().split("\n")[1].split("|")
    #    inds = [head.index(col) for col in ["label", "generators", "short_label", "ambient", "subgroup_tex", "ambient_tex", "quotient_tex", "subgroup_order", "quotient_order", "split", "direct"]]
    t0 = time.time()
    #tex_subdata = defaultdict(set)
    #tex_name = defaultdict(set)
    def process_file(path):
        data = defaultdict(list)
        with open(path) as F:
            for line in F:
                code = line[0]
                if code not in "TE":
                    ambient, _ = line[1:].split("|",1)
                    ambient = ambient.split("(")[0]
                    ambient = ".".join(ambient.split(".")[:2])
                    data[ambient].append(line)
                    #if code == "t":
                    #    name, tex = data.strip().split("|")
                    #    tex_name[ambient].add(tex)
                    #else:
                    #    pieces = line[1:].strip().split("|")
                    #    pieces = tuple(pieces[i] for i in inds)
                    #    slabel = pieces[0]
                    #    tex_subdata[slabel].add(pieces)
        for ambient, lines in data.items():
            with open(opj("/scratch/grp/newer_collated", ambient), "a") as F:
                _ = F.write("".join(lines))
    for folder in ["newer_30minrun", "newer_60minrun", "newest_60minrun"]:
    #for folder in os.listdir("/scratch/grp/"):
        print(f"Starting {folder} at time {time.time()-t0}")
        #if any(folder.startswith(h) for h in ["15", "60", "fixsmall", "highmem", "lowmem", "noaut", "sopt", "tex", "Xrun", "last"]):
        for sub in os.listdir(opj("/scratch/grp/",folder)):
            if sub.endswith(".txt"):
                process_file(opj("/scratch/grp", folder, sub))

    # We have updated the generators to fix element_repr_type, so we use the old upload file
    #missing = {}
    #with open("/scratch/grp/upload/SubGrp4.txt") as F:
    #    by_amb = defaultdict(list)
    #    for i, line in enumerate(F):
    #        cols = line.strip().split("|")
    #        if i == 0:
    #            ambind = cols.index("ambient")
    #            #ind2 = [cols.index(col) for col in ["label", "generators"]]
    #        elif i > 2:
    #            if i % 1000000 == 0:
    #                for ambient, lines in by_amb.items():
    #                    with open(opj("/scratch/grp/precollated", ambient), "a") as F:
    #                        _ = F.write("".join(lines))
    #                by_amb = defaultdict(list)
    #                print("SubGrp4", i // 1000000)
    #            by_amb[cols[ambind]].append(line)
    #            #slabel, gens = [cols[j] for j in ind2]
    #            #narrow = set(pieces for pieces in tex_subdata[slabel] if pieces[1] == gens)
    #            #if narrow:
    #            #    tex_subdata[slabel] = narrow
    #            #else:
    #            #    missing[slabel] = gens
    #    for ambient, lines in by_amb.items():
    #        with open(opj("/scratch/grp/precollated", ambient), "a") as F:
    #            _ = F.write("".join(lines))
    #return tex_name, tex_subdata, missing

def subool_check():
    R = {}
    def process_file(path):
        with open(path) as F:
            for line in F:
                code = line[0]
                if code in "RB":
                    ambient, data = line[1:].split("|",1)

# attach cloud_collect.py
from collections import defaultdict
from sage.databases.cremona import class_to_int
def sort_key(label):
    N, i = label.split(".")
    if i.isdigit():
        return int(N), int(i)
    return int(N), class_to_int(i)

@cached_function
def fixed_latex(s, n):
    s = s.replace("\\\\", "\\")
    s = parse(s)
    if s is not None:
        if s.order is None or s.order == n:
            return s.latex
    return r"\N"


def find_origtex():
    Scols = "ambient|abelian|ambient_order|ambient_tex|aut_label|central|centralizer|centralizer_order|central_factor|characteristic|complements|conjugacy_class_count|contained_in|contains|normal_contained_in|normal_contains|core|core_order|coset_action_label|count|cyclic|direct|generators|hall|label|maximal|maximal_normal|minimal|minimal_normal|nilpotent|normal|normal_closure|normalizer|outer_equivalence|perfect|proper|quotient_abelian|quotient_cyclic|quotient_fusion|quotient_hash|quotient_order|quotient_solvable|quotient_tex|short_label|solvable|special_labels|split|standard_generators|stem|subgroup_fusion|subgroup_hash|subgroup_order|subgroup_tex|sylow".split("|")
    Slab = Scols.index("label")
    Sgen = Scols.index("generators")
    Slook = [(col, Scols.index(col)) for col in ["ambient_tex", "ambient_order", "subgroup_tex", "subgroup_order", "quotient_tex", "quotient_order", "normal"]]

    Fcols = "abelian|ambient|ambient_order|ambient_tex|aut_centralizer_order|aut_label|aut_quo_index|aut_stab_index|aut_weyl_group|aut_weyl_index|central|central_factor|centralizer|centralizer_order|characteristic|complements|conjugacy_class_count|contained_in|contains|core|core_order|coset_action_label|count|cyclic|diagram_aut_x|diagram_norm_x|diagram_x|diagramx|direct|generators|hall|label|maximal|maximal_normal|minimal|minimal_normal|mobius_quo|mobius_sub|nilpotent|normal|normal_closure|normal_contained_in|normal_contains|normalizer|outer_equivalence|perfect|projective_image|proper|quotient|quotient_abelian|quotient_action_image|quotient_action_kernel|quotient_action_kernel_order|quotient_cyclic|quotient_fusion|quotient_hash|quotient_order|quotient_solvable|quotient_tex|short_label|solvable|special_labels|split|standard_generators|stem|subgroup|subgroup_fusion|subgroup_hash|subgroup_order|subgroup_tex|sylow|weyl_group".split("|")
    Flab = Fcols.index("label")
    Fgen = Fcols.index("generators")
    Flook = [("label", Flab), ("generators", Fgen)]

    all_labels = os.listdir("precollated")
    all_labels.sort(key=sort_key)
    with open("NewGrpTexInfo.txt", "w") as FGrp:
        with open("NewSubTexInfo.txt", "w") as FSub:
            for i, label in enumerate(all_labels):
                if i and i % 10000 == 0:
                    print(i, label)
                N = int(label.split(".")[0])
                S = defaultdict(lambda: defaultdict(list))
                T = r"\N"
                F = []
                with open("precollated/" + label) as Fhand:
                    for line in Fhand:
                        if line[0] == "S":
                            pieces = line[1:].strip().split("|")
                            S[pieces[Slab]][pieces[Sgen]].append({col: pieces[i] for (col, i) in Slook})
                        elif line[0] == "t" and line[1] != "|":
                            T = fixed_latex(line[1:].strip().split("|")[-1], N)
                        else:
                            pieces = line.strip().split("|")
                            F.append({col: pieces[i] for (col, i) in Flook})
                _ = FGrp.write(f"{label}|{T}\n")
                for D in F:
                    if D["label"] in S and D["generators"] in S[D["label"]]:
                        Sdata = S[D["label"]][D["generators"]]
                        ambtex = set(dd["ambient_tex"] for dd in Sdata)
                        ambtex = [fixed_latex(y, int(Sdata[0]["ambient_order"])) for y in ambtex]
                        ambtex = "&".join(ambtex)
                        subtex = set(dd["subgroup_tex"] for dd in Sdata)
                        subtex = [fixed_latex(y, int(Sdata[0]["subgroup_order"])) for y in subtex]
                        subtex = "&".join(subtex)
                        if Sdata[0]["normal"] == "t":
                            quotex = set(dd["quotient_tex"] for dd in Sdata)
                            quotex = [fixed_latex(y, int(Sdata[0]["quotient_order"])) for y in quotex]
                            quotex = "&".join(quotex)
                        else:
                            quotex = r"\N"
                    else:
                        subtex = quotex = ambtex = "@"
                    _ = FSub.write(f"{D['label']}|{subtex}|{ambtex}|{quotex}\n")
