
sys.path.append("/home/roed/lmfdb")
from lmfdb import db
from collections import defaultdict

def unbooler(x):
    if x is True:
        return "t"
    elif x is False:
        return "f"
    elif x is None:
        return r"\N"
    if isinstance(x, list):
        return "{" + ",".join(unbooler(y) for y in x) + "}"
    return str(x)

def unnone(x):
    if x is None:
        return r"\N"
    return str(x)

subin_cols = "ambient|abelian|ambient_order|ambient_tex|aut_label|central|centralizer|centralizer_order|central_factor|characteristic|complements|conjugacy_class_count|contained_in|contains|normal_contained_in|normal_contains|core|core_order|coset_action_label|count|cyclic|direct|generators|hall|label|maximal|maximal_normal|minimal|minimal_normal|nilpotent|normal|normal_closure|normalizer|outer_equivalence|perfect|proper|quotient_abelian|quotient_cyclic|quotient_fusion|quotient_hash|quotient_order|quotient_solvable|quotient_tex|short_label|solvable|special_labels|split|standard_generators|stem|subgroup_fusion|subgroup_hash|subgroup_order|subgroup_tex|sylow".split("|")
Lcols = "ambient|label|subgroup|quotient".split("|")
Wcols = "ambient|label|projective_image|quotient_action_image|quotient_action_kernel|quotient_action_kernel_order|weyl_group|aut_weyl_group|aut_weyl_index|aut_centralizer_order|aut_quo_index|aut_stab_index".split("|")

wcols = "label|wreath_data|wreath_product".split("|")
scols = "label|transitive_degree|all_subgroups_known|maximal_subgroups_known|number_subgroup_autclasses|number_subgroup_classes|number_subgroups|semidirect_product|subgroup_inclusions_known|subgroup_index_bound|almost_simple|central_product|direct_factorization|direct_product|number_characteristic_subgroups|normal_subgroups_known|complements_known|number_normal_subgroups|sylow_subgroups_known|outer_equivalence|conj_centralizers".split("|")
bcols = "label|Agroup|Zgroup|abelian|center_label|composition_factors|composition_length|counter|cyclic|derived_length|elementary|exponent|exponents_of_order|factors_of_order|gens_used|hash|hyperelementary|label|metabelian|metacyclic|ngens|nilpotency_class|nilpotent|old_label|order|perfect|pgroup|primary_abelian_invariants|quasisimple|simple|smith_abelian_invariants|solvable|supersolvable|easy_rank|representations|element_repr_type|permutation_degree|linC_degree|linQ_degree|linFp_degree|linFq_degree|pc_rank|backup_solvability_type".split("|")


def write_gp_files():
    print("Loading pcredo")
    pcredo = defaultdict(dict)
    with open("pcredo.output") as F:
        for line in F:
            pieces = line[1:].strip().split("|")
            if line[0] == "s":
                D = dict(zip(scols, pieces))
                pcredo[D["label"]].update(D)
            elif line[0] == "w":
                D = dict(zip(wcols, pieces))
                pcredo[D["label"]].update(D)
            elif line[0] == "b":
                D = dict(zip(bcols, pieces))
                pcredo[D["label"]].update(D)
    print("Loading NewGrpTexInfo")
    with open("NewGrpTexInfo.txt") as F:
        tex_name = {}
        for line in F:
            label, t = line.strip().split("|")
            tex_name[label] = t
    print("Starting main loop")
    fname = f"GpTexInfo.txt"
    with open(fname, "w") as Fout:
        for rec in db.gps_groups.search({}, ["label", "representations", "order", "cyclic", "abelian", "smith_abelian_invariants", "direct_factorization", "wreath_data"]):
            label, order = rec["label"], rec["order"]
            if label in pcredo:
                rec = pcredo[label]
                cyclic, abelian = rec["cyclic"], rec["abelian"]
                lie = "[]"
                smith = rec["smith_abelian_invariants"].replace("{", "[").replace("}", "]")
                direct = rec["direct_factorization"]
                wreath = r"\N"
            else:
                cyclic, abelian = unbooler(rec["cyclic"]), unbooler(rec["abelian"])
                lie = str(rec["representations"].get("Lie", [])).replace(" ", "")
                smith = unnone(rec["smith_abelian_invariants"])
                direct = unnone(rec["direct_factorization"])
                wreath = unnone(rec["wreath_data"])
                tex = tex_name.get(label, r"\N")
            _ = Fout.write(f"{label}|{tex}|\\N|{lie}|{order}|{cyclic}|{abelian}|{smith}|{direct}|{wreath}\n")

def write_sub_files():
    texout_cols = ["label", "short_label", "subgroup", "ambient", "quotient", "subgroup_tex", "ambient_tex", "quotient_tex", "subgroup_order", "quotient_order", "split", "direct"]
    dataout_cols = ["label", "subgroup", "quotient", "sylow", "hall", "normalizer_index", "weyl_group"]
    Slook = {col: subin_cols.index(col) for col in subin_cols}
    idout_cols = ["label", "subgroup", "quotient"]
    hashes = {}
    print("Loading hashes")
    for rec in db.gps_groups.search({}, ["label", "hash"]):
        if rec["hash"] is not None and not rec["label"].split(".")[1].isdigit():
            hashes[rec["label"]] = rec["hash"]
    # Need to load pcredo data separately
    print("Loading NewGrpTexInfo")
    with open("NewGrpTexInfo.txt") as F:
        tex_name = {}
        for line in F:
            label, t = line.strip().split("|")
            tex_name[label] = t
    print("Loading NewSubTexInfo")
    with open("NewSubTexInfo.txt") as F:
        subtex_data = {}
        for line in F:
            label, A, B, C = line.strip().split("|")
            subtex_data[label] = (A, B, C)
    pcredo = defaultdict(lambda: defaultdict(dict))
    print("Loading pcredo")
    with open("pcredo.output") as F:
        for line in F:
            pieces = line[1:].strip().split("|")
            if line[0] == "S":
                D = dict(zip(subin_cols, pieces))
                norm = D["normalizer"]
                if norm == r"\N":
                    D["normalizer_index"] = norm
                else:
                    D["normalizer_index"] = norm.split(".")[0]
                pcredo[D["ambient"]][D["short_label"]].update(D)
            elif line[0] == "L":
                D = dict(zip(Lcols, pieces))
                short_label = ".".join(D["label"].split(".")[2:])
                pcredo[D["ambient"]][short_label].update(D)
            elif line[0] == "W":
                D = dict(zip(Wcols, pieces))
                short_label = ".".join(D["label"].split(".")[2:])
                pcredo[D["ambient"]][short_label].update(D)
    print("Starting main loop")
    with open("TexInfo.txt", "w") as Ftex:
        with open("SubData.txt", "w") as Fdata:
            seen = set()
            for i, rec in enumerate(db.gps_subgroups.search({}, ["label", "short_label", "ambient", "ambient_order", "subgroup", "subgroup_order", "subgroup_hash", "quotient", "quotient_order", "quotient_hash", "normal", "weyl_group", "normalizer", "centralizer", "centralizer_order", "split", "direct"])):
                if i and i % 1000000 == 0:
                    print("output", i // 1000000)
                ambient, amb = rec["ambient"], rec["ambient_order"]
                if ambient in pcredo:
                    if ambient not in seen:
                        for D in pcredo[ambient].values():
                            _ = Ftex.write("|".join(unbooler(D[col]) for col in texout_cols) + "\n")
                            _ = Fdata.write("|".join(unbooler(D[col]) for col in dataout_cols) + "\n")
                        seen.add(ambient)
                    continue
                sub, subord, shash, quo, quoord, qhash = rec["subgroup"], ZZ(rec["subgroup_order"]), rec["subgroup_hash"], rec["quotient"], ZZ(rec["quotient_order"]), rec["quotient_hash"]
                if sub is not None:
                    sord, isub = sub.split(".")
                    sord = int(sord)
                    if sord != subord or shash is not None and not isub.isdigit() and sub in hashes and hashes[sub] != shash:
                        rec["subgroup"] = None
                if quo is not None:
                    qord, iquo = quo.split(".")
                    qord = int(qord)
                    if qord != quoord or qhash is not None and not iquo.isdigit() and quo in hashes and hashes[quo] != qhash:
                        rec["quotient"] = None
                rec["subgroup_tex"], rec["ambient_tex"], rec["quotient_tex"] = subtex_data[rec["label"]]
                _ = Ftex.write("|".join(unbooler(rec[col]) for col in texout_cols) + "\n")

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
                norm = rec["normalizer"]
                if norm is None:
                    if rec["normal"]:
                        rec["normalizer_index"] = 1
                    else:
                        rec["normalizer_index"] = None
                else:
                    nind = int(norm.split(".")[0])
                    assert amb % nind == 0
                    nord = amb // nind
                    rec["normalizer_index"] = nind
                    cent = rec["centralizer"]
                    cord = rec["centralizer_order"]
                    if cent is not None:
                        cind = int(cent.split(".")[0])
                        if cord is None:
                            missing_cent.add(label)
                            cord = amb // cind
                            assert cind * cord == amb
                    weyl = rec["weyl_group"]
                    if weyl is not None and cord is not None:
                        word = int(weyl.split(".")[0])
                        if word * cord != nord:
                            rec["weyl_group"] = None
                _ = Fdata.write("|".join(unbooler(rec[col]) for col in dataout_cols) + "\n")
