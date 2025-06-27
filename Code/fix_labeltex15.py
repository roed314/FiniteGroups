#!/usr/bin/env -S sage -python

# Usage: parallel -j80 --results /scratch/grp/create_upload_output ./fix_labeltex15.py {} ::: {0..79}
import sys
import re
import shutil
from collections import defaultdict, Counter
from itertools import islice
from pathlib import Path
if "/home/roed/lmfdb" not in sys.path:
    sys.path.append("/home/roed/lmfdb")
from lmfdb import db
from sage.databases.cremona import class_to_int, cremona_letter_code
from sage.all import ZZ
from faithful_reps import poset_data, char_data, linC_degree, linR_degree, linQ_degree, linQ_dim
from sage.misc.cachefunc import cached_function

def long_to_short(label):
    if label.startswith("NULL"):
        return label
    return ".".join(label.split(".")[2:])

# BCDIJLQRSWabcghijlmnoqrstuvwzTE GHMXYZ dek : used AUfFKNeOPVp
def tmpheaders():
    # Return a dictionary giving the columns included in each tmpheader, indexed by the one-letter code included at the beginning of each corresponding output line
    base = Path("/home/roed/FiniteGroups/Code")
    codes = {}
    heads = {}
    for head in base.iterdir():
        if head.name.endswith(".tmpheader"):
            with open(head) as F:
                code, attrs = F.read().strip().split("\n")
            assert code not in codes
            codes[code] = attrs.split("|")
    return codes

def headers():
    headers = {}
    # Return a dictionary giving the the columns and types in each header, indexed by the header name
    for name, tbl in [("Grp", "gps_groups"), ("SubGrp", "gps_subgroups"), ("GrpConjCls", "gps_conj_classes"), ("GrpChtrCC", "gps_char"), ("GrpChtrQQ", "gps_qchar")]:
        tbl = db[tbl]
        cols = tbl.search_cols
        if name == "SubGrp":
            search_cols = "Agroup, Zgroup, abelian, ambient, ambient_counter, ambient_order, ambient_tex, central, characteristic, core_order, counter, cyclic, direct, hall, label, maximal, maximal_normal, metabelian, metacyclic, minimal, minimal_normal, nilpotent, normal, outer_equivalence, perfect, proper, quotient, quotient_Agroup, quotient_abelian, quotient_cyclic, quotient_hash, quotient_metabelian, quotient_nilpotent, quotient_order, quotient_simple, quotient_solvable, quotient_supersolvable, quotient_tex, simple, solvable, special_labels, split, stem, subgroup, subgroup_hash, subgroup_order, subgroup_tex, supersolvable, sylow".split(", ")
            data_cols = ["label"] + [col for col in cols if col not in search_cols]
            headers["SubGrpSearch"] = (search_cols, [tbl.col_type[col] for col in search_cols])
            headers["SubGrpData"] = (data_cols, [tbl.col_type[col] for col in data_cols])
        else:
            types = [tbl.col_type[col] for col in cols]
            headers[name] = (cols, types)
    return headers

breaker = re.compile(r"([a-z]+)([A-Z]+)")
canpiece = re.compile(r"([a-z]+)(\d+)")
def revise_subgroup_labels(label, data):
    # Set subgroup labels to their final form, update other columns where they appear
    N = ZZ(data["Grp"][label]["order"])
    if "SubGrp" not in data or not data["SubGrp"]:
        return
    solv = (data["Grp"][label]["solvable"] == "t")
    oe = (data["Grp"][label]["outer_equivalence"] == "t")
    if oe:
        canre = re.compile(r"\d+\.[0-9a-z]+\.\d+\.[a-z]+\d+")
    else:
        canre = re.compile(r"\d+\.[0-9a-z]+\.\d+\.[a-z]+\d+\.[a-z]+\d+")
    sib = int(data["Grp"][label]["subgroup_index_bound"])
    def noncanonical(ind, Ds):
        sub_ord = N // ind
        if ind == 1 or ind == N or (ind.gcd(sub_ord) == 1 and (sub_ord.is_prime_power() or solv)):
            return False
        if sib != 0 and ind > sib:
            return True
        if len(Ds) == 1:
            return False
        if all(canre.fullmatch(D["label"]) for D in Ds):
            return False
        return True
    by_index = defaultdict(list)
    for D in data["SubGrp"].values():
        by_index[ZZ(D["quotient_order"])].append(D)
    for ind, Ds in by_index.items():
        if noncanonical(ind, Ds):
            # Despite being non-canonical, we use the existing labels to sort since they will sometimes group by meaningful quantities
            if any(D["label"].startswith("NULL") for D in Ds):
                Ds.sort(key=lambda D: label_to_key(D["stored_label"]))
            else:
                Ds.sort(key=lambda D: label_to_key(D["label"]))
            if oe:
                pattern = "{}.{}"
            else:
                pattern = "{}._.{}"
            for ctr, D in enumerate(Ds):
                D["short_label"] = pattern.format(ind, cremona_letter_code(ctr).upper())
        else:
            if len(Ds) == 1:
                Ds[0]["short_label"] = f"{ind}.a1"
                if not oe:
                    Ds[0]["short_label"] += ".a1"
            else:
                for D in Ds:
                    D["short_label"] = long_to_short(D["label"])
            if any("NULL" in D["short_label"]) for D in Ds:
                with open("/scratch/grp/NULLsub.txt", "a") as F:
                    _ = F.write(f"{label}|{ind}\n")
    old_lookup = {long_to_short(D["stored_label"]): D["short_label"] for D in data["SubGrp"].values()}
    new_lookup = {long_to_short(D["label"]): D["short_label"] for D in data["SubGrp"].values()}
    old_lookup[r"\N"] = new_lookup[r"\N"] = r"\N"
    for D in data["SubGrp"].values():
        # Some columns have been updated while loading newer_collated
        updated = D.get("updated", set())
        D["label"] = f"{D['ambient']}.{D['short_label']}"
        if "_" in D["short_label"]:
            D["aut_label"] = r"\N"
        else:
            D["aut_label"] = ".".join(D["short_label"].split(".")[:2])
        for col in ["centralizer", "core", "normal_closure", "normalizer"]:
            if col in D:
                lookup = new_lookup if col in updated else old_lookup
                D[col] = lookup[D[col]]
        for col in ["complements", "contained_in", "contains", "normal_contained_in", "normal_contains"]:
            if D.get(col, r"\N") not in [r"\N", "{}"]:
                lookup = new_lookup if col in updated else old_lookup
                D[col] = "{" + ",".join(lookup[x] for x in D[col][1:-1].split(",")) + "}"
    for C in data["GrpConjCls"].values():
        if "centralizer" in C:
            C["centralizer"] = old_lookup[C["centralizer"]]
    for R in data["GrpChtrCC"].values():
        for col in ["center", "kernel"]:
            if col in R:
                if R[col] in new_lookup:
                    R[col] = new_lookup[R[col]]
                else:
                    # We didn't successfully compute the subgroup renames, so we don't know how to match this with a new label.
                    R[col] = r"\N"

def label_to_key(label):
    ans = []
    pieces = []
    for blob in label.split("."):
        if blob == "_":
            continue
        # This is kind of ugly: we break into parts based on substrings of lower case, upper case and digits
        parts = ["".join(c for c in blob if getattr(c, meth)()) for meth in ["islower", "isupper", "isdigit"]]
        assert blob == "".join(parts)
        pieces.extend([part for part in parts if part])
    for piece in pieces:
        if piece.isdigit():
            ans.append(int(piece))
        elif piece.isupper():
            ans.append(class_to_int(piece.lower()))
        else:
            ans.append(class_to_int(piece))
    return ans

def create_upload_files(start=None, step=None, overwrite=False):
    # TODO: Make sure we're actually wiping out bad char, qchar and conj_classes
    # TODO: Save old_label for checking purposes
    # TODO: Review and test psycodict PR #36 (reload resorting columns)
    # TODO: Should check consistency, e.g. subgroup_tex = tex_name[subgroup]
    # TODO: Standardize subgroup_tex and quotient_tex in virtual cases (e.g. 2187.5299 not in database, but appears several times); insert into this function
    # SOON TODO: Change _sort for gps_subgroup to ambient_order, ambient_counter, counter
    # SOON TODO: Update subgroup downloader to get data from gps_subgroups_data
    # LATER TODO: Port attributes in fill back to Magma when possible
    # LATER TODO: Compute more data for automorphism groups
    if (start is None) != (step is None):
        raise ValueError("Must specify both start and step, or neither")
    badK = set()
    badQ = set()
    changed_cols = {}
    # gps_subgroups (text): aut_label, centralizer, core, label, normal_closure, normalizer, short_label
    # gps_subgroups (text[]): complements, contained_in, contains, normal_contained_in, normal_contains
    # gps_char (text): center, kernel
    # gps_conj_classes (text): centralizer
    # We create files for conjugacy classes, complex characters, rational characters
    # We update the file for subgroups
    base = Path("/scratch/grp")
    home = Path("/home/roed")
    DATA = home / "FiniteGroups" / "Code" / "DATA"
    bigfix = base / "bigfix"
    new_coll = base / "newer_collated"
    rep_coll = base / "replace_collated"
    cur_coll = base / "cur_collated"
    fix_coll = base / "fix_collated"
    ren_coll = base / "relabel_collated"
    aut_coll = base / "aut_collated"
    cen_coll = base / "cent_collated"
    boo_coll = base / "subool_collated"
    out_coll = base / "out_collated"
    con_coll = base / "conj_centralizers"

    tmps = tmpheaders()
    tbl_codes = {"Grp": "abcdefghijklmnopqrstuvwzGM012345678@#%9",
                 "SubGrp": "ABDFIKLNPRSUVW",
                 "GrpConjCls": "JO",
                 "GrpChtrCC": "C",
                 "GrpChtrQQ": "Q"}
    tbl_lookup = {}
    for tbl, codes in tbl_codes.items():
        for code in codes:
            tbl_lookup[code] = tbl
    finals = headers()
    if not overwrite and any((bigfix / (final+".txt")).exists() for final in finals):
        raise ValueError("An output file already exists; you can use overwrite to proceed anyway")

    curhead = defaultdict(tuple)
    Jlookup = {}
    hash_lookup = {}
    for rec in db.gps_groups.search({}, ["label", "order", "counter", "hash"]):
        Jlookup[rec["order"], rec["counter"]] = rec["label"]
        hash_lookup[rec["label"]] = rec["hash"]
    cyclic_lookup = {rec["order"]: rec["label"] for rec in db.gps_groups.search({"cyclic":True}, ["order", "label"])}
    special_names = defaultdict(list)
    for rec in db.gps_special_names.search({}, ["label", "family", "parameters"]):
        params = rec["parameters"]
        if "q" in params and "fam" not in params:
            special_names[rec["label"]].append((rec["family"], rec["parameters"]))
    fam_sort = {rec["family"]: rec["priority"] for rec in db.gps_families.search({}, ["family", "priority"])}

    elt_repr_to_perm = set(["3170119680.a", "103675594014720.a", "756000.a"])
    solvable_rep_additions = {
        "1600.6242": {"pres": [8,-2,-2,-2,-2,-5,-2,-2,-5,16,6409,1250,442,66,771,1163,91,1924,1292,49925,17293,8661,141,26886,40334,20182,166,61447,40975,20503]},
        "1600.6263": {"pres": [8,-2,-2,-2,-2,-5,-2,-2,-5,16,6409,20450,442,66,771,1163,91,1924,1292,49925,17293,8661,141,26886,40334,20182,166,61447,40975,20503]},
        "1600.6441": {"pres": [8,-2,-2,-2,-2,-2,-5,-2,-5,16,41,4355,1163,91,4484,2892,116,3077,3085,62726,40334,10110,166,40967,40975,10271]},
        "1600.6443": {"pres": [8,2,2,2,2,2,5,2,5,16,66,91,789,797,86918,15702,10110,166,83975,10263,10271]},
        "1600.6446": {"pres": [8,2,2,2,2,2,5,2,5,16,482,66,91,1173,797,83334,17046,10110,166,86023,10775,10271]},
        "1600.6456": {"pres": [8,2,2,2,2,2,5,2,5,41,498,8075,3795,91,972,1460,116,2317,1557,15694,20182,10110,166,30735,20503,10271]},
        "1600.7169": {"pres": [8,-2,-2,-2,-2,-5,-2,-2,-5,16,329,674,442,66,1795,1163,91,1284,1292,11525,17293,141,26886,40334,166,61447,40975]},
        "1600.7170": {"pres": [8,-2,-2,-2,-2,-5,-2,-2,-5,16,6409,19874,442,66,1795,1163,91,1284,1292,11525,17293,141,26886,40334,166,61447,40975]},
        "1600.7212": {"pres": [8,-2,-2,-2,-5,-2,-2,-2,-5,16,6409,290,442,66,771,523,43204,7212,116,26885,17293,141,62726,40334,166,40967,40975]},
        "1600.7233": {"pres": [8,-2,-2,-2,-2,-5,-2,-2,-5,16,41,4818,27395,1163,91,1284,1292,11525,17293,141,26886,40334,166,61447,40975]},
        "1600.7241": {"pres": [8,-2,-2,-2,-5,-2,2,-2,-5,16,6409,19490,442,66,771,523,67205,17293,141,62726,40334,166,40967,40975]},
        "1600.7243": {"pres": [8,2,2,2,2,5,2,2,5,16,41,1795,1163,91,1284,1292,13061,17293,141,30470,40334,166,64519,40975]},
        "1600.7259": {"pres": [8,-2,-2,-2,-5,-2,-2,2,-5,16,19490,1402,66,771,523,1220,116,67206,40334,166,40967,40975]},
        "1600.7286": {"pres": [8,-2,-2,-2,-2,2,-5,-2,-5,16,2018,154,66,4804,2892,1460,116,3077,3085,1557,26886,40334,20182,166,61447,40975,20503]},
        "1600.7287": {"pres": [8,-2,-2,-2,-2,2,-5,-2,-5,16,41,2244,2892,116,4613,3085,62726,40334,166,40967,40975]},
        "1600.7288": {"pres": [8,-2,-2,-2,-2,-2,-5,-2,-5,161,41,66,18252,1460,116,1549,1557,13454,20182,166,30735,20503]},
        "148176.a": {"pres": [10,2,3,3,2,3,2,2,7,7,7,20,15131,2922842,1950582,260302,3344403,475573,874943,113,6352204,1059314,957924,178544,8628125,1027095,452005,211355,141345,175,952566,68056,758546,10956,206,241927,34577,1693467,11557,77768,272178,25948,90758,15178,8467209,2116819,252029,117659], "gens": [1,3,4,6,9,10], "code": 7658187531002579172047763624271374619209509878509065634825289678510947644402632670036756247091168030701542431428252997732269294880028298921050129727719495619574110458902772078518922553542451511082476903457972663}
    }
    print("Initial setup complete")
    if not cur_coll.exists():
        cur_coll.mkdir()
        for tbl, code, ambient in [("groups", "p", "label"), ("subgroups", "P", "ambient")]:
            path = bigfix / f"gps_{tbl}.txt"
            with open(path) as F:
                curamb = None
                buff = []
                for j, line in enumerate(F):
                    pieces = line.strip().split("|")
                    if j%10000 == 0:
                        print(f"Collating gps_{tbl} {j}...", end="\r")
                    if j == 0:
                        loc = pieces.index(ambient)
                    elif j > 2:
                        amb = pieces[loc]
                        if curamb is not None and amb != curamb:
                            with open(cur_coll / curamb, "a") as Fout:
                                _ = Fout.write("".join(buff))
                            buff = []
                        curamb = amb
                        buff.append(code + line)
                with open(cur_coll / curamb, "a") as Fout:
                    _ = Fout.write("".join(buff))
            print(f"Collating gps_{tbl} done!            ")
    if not fix_coll.exists():
        fix_coll.mkdir()
        # Assemble all of the fixes into collation files by ambient group
        with open(base / "NewTexNames.txt") as F:
            for j, line in enumerate(F):
                if j%10000 == 0:
                    print(f"Collating group latex {j}...", end="\r")
                if j > 2:
                    label, tex_name, name = line.strip().split("|")
                    with open(fix_coll / label, "a") as Fout:
                        _ = Fout.write(f"t{label}|{name}|{tex_name}\n")
        print("Collating group latex done!            ")
        with open(base / "NewSubgroupTexNames.txt") as F:
            for j, line in enumerate(F):
                if j%10000 == 0:
                    print(f"Collating subgroup latex {j}...", end="\r")
                if j > 2:
                    N, i, _ = line.split(".", 2)
                    with open(fix_coll / f"{N}.{i}", "a") as Fout:
                        _ = Fout.write(f"V{line}")
        print("Collating subgroup latex done!            ")
        with open(base / "NewQuotientTexNames.txt") as F:
            for j, line in enumerate(F):
                if j%10000 == 0:
                    print(f"Collating quotient latex {j}...", end="\r")
                if j > 2:
                    N, i, _ = line.split(".", 2)
                    with open(fix_coll / f"{N}.{i}", "a") as Fout:
                        _ = Fout.write(f"U{line}")
        print("Collating quotient latex done!            ")
        # Since check_special_out needs to modify subgroup special_labels, we save to PhiG for later
        PhiG = []
        for j, path in enumerate((DATA / "check_special_out").iterdir()):
            if j%1000 == 0:
                print(f"Collating special_out {j}...", end="\r")
            label = path.name
            with open(path) as F:
                cso_data = {}
                for line in F:
                    pieces = line.strip().split("|")
                    cso_data[pieces[0]] = pieces[1:]
                if "PhiG" in cso_data and cso_data["PhiG"][1] == "f":
                    PhiG.append(cso_data["PhiG"][0])
                if "Phi" in cso_data and cso_data["Phi"][0] == "f" or "PhiQ" in cso_data and cso_data["PhiQ"][0] == "f":
                    with open(fix_coll / label, "a") as Fout:
                        Phi, PhiQ = cso_data["Phi"][1], cso_data["PhiQ"][1]
                        _ = Fout.write(f"f{label}|{Phi}|{PhiQ}\n")
        with open(base / "PhiG.txt", "w") as Fout:
            _ = Fout.write("\n".join(PhiG) + "\n")
        print("Collating special_out done!            ")
        with open(base / "SubData.txt") as F:
            for j, line in enumerate(F):
                if j%10000 == 0:
                    print(f"Collating SubData {j}...", end="\r")
                N, i, _ = line.split(".", 2)
                with open(fix_coll / f"{N}.{i}", "a") as Fout:
                    _ = Fout.write(f"F{line}")
        print("Collating SubData done!            ")
        for j, path in enumerate((base / "char_check").iterdir()):
            if j%10000 == 0:
                print(f"Collating char_check {j}...", end="\r")
            label = path.name
            with open(path) as F:
                with open(fix_coll / label, "a") as Fout:
                    for line in F:
                        _, _, short_label, ch = line.strip().split("|")
                        _ = Fout.write(f"K{label}.{short_label}|{ch}\n")
        print("Collating char_check done!            ")
        with open(base / "NewRankData.txt") as F:
            for j, line in enumerate(F):
                if j%100000 == 0:
                    print(f"Collating ranks {j}...", end="\r")
                label = line[1:].split("|")[0]
                with open(fix_coll / label, "a") as Fout:
                    _ = Fout.write(line)
        print("Collating ranks done!                 ")
        with open(base / "FixPres.txt") as F:
            for line in F:
                label = line[1:].split("|")[0]
                with open(fix_coll / label, "a") as Fout:
                    _ = Fout.write(line)
        print("Collating fixpres done!               ")

    #if not ren_coll.exists():
    #    ren_coll.mkdir()
    #    with open(bigfix / "sub_relabel.txt") as F:
    #        amb = None
    #        buff = []
    #        for j, line in enumerate(F):
    #            if j%10000 == 0:
    #                print(f"Collating sub_relabel {j}...", end="\r")
    #            old_label, _, new_label = line.strip().split("|")
    #            N, i, _ = old_label.split(".", 2)
    #            ambient = f"{N}.{i}"
    #            if amb is not None and ambient != amb:
    #                with open(ren_coll / amb, "a") as Fout:
    #                    _ = Fout.write("".join(buff))
    #                buff = []
    #            amb = ambient
    #            buff.append(f"N{old_label}|{new_label}\n")
    #        with open(ren_coll / amb, "a") as Fout:
    #            _ = Fout.write("".join(buff))
    #        print("Collating sub_relabel done!            ")
    if not boo_coll.exists():
        boo_coll.mkdir()
        for j, path in enumerate((base / "subool").iterdir()):
            if j%10000 == 0:
                print(f"Collating subool {j}...", end="\r")
            label = path.name
            with open(path) as F:
                with open(boo_coll / label, "w") as Fout:
                    for line in F:
                        _ = Fout.write("B" + line)
        print("Collating subool done!            ")

    #with open(home / "pcfixed.txt") as F:
    #    pcredo = set(line.split("|")[0] for line in F)
    with open(base / "PhiG.txt") as F:
        PhiG = {".".join(x.split(".")[:2]): x.strip() for x in F}
    pcredo = set(path.name for path in rep_coll.iterdir())
    if start is None:
        writers = {final: open(bigfix / (final+".txt"), "w") for final in finals}
    cc_tbls = set(["GrpConjCls", "GrpChtrCC", "GrpChtrQQ"])

    def load_file(data, path, skip_cc=False, reset_labels=False, cache_labels=False, loading_new=False):
        if reset_labels and "SubGrp" in data:
            for D in data["SubGrp"].values():
                D["stored_label"] = D["label"]
                D["label"] = None
        if path.exists():
            old_sub_lookup = None
            with open(path) as F:
                # Note that this correctly handles duplicate lines
                for line in F:
                    code, line = line[0], line[1:].strip()
                    if reset_labels and code != "R" or not reset_labels and code == "R":
                        continue
                    tbl = tbl_lookup[code]
                    if skip_cc and tbl in cc_tbls:
                        continue
                    line = line.split("|")
                    assert len(line) == len(tmps[code])
                    line = dict(zip(tmps[code], line))
                    if reset_labels:
                        lab = line["stored_label"]
                        if "," in lab:
                            # The new subgroup matched multiple old ones
                            # These should have been diverted into replace_collated
                            raise RuntimeError
                        assert lab in data[tbl]
                    elif code == "D":
                        # D uses short_label and ambient rather than full label
                        lab = f"{line['ambient']}.{line['short_label']}"
                    else:
                        lab = line["label"] # Every tmpheader has a label column
                        if code == "O":
                            if old_sub_lookup is None:
                                old_sub_lookup = {rec["stored_label"]: rec["label"] for rec in data["SubGrp"].values()}
                            line["centralizer"] = old_sub_lookup.get(line["centralizer"], r"\N") # Also fixes the "None" mixup
                        if code == "B":
                            if loading_new:
                                # There was an error in the code for computing quotient_supersolvable
                                del line["quotient_supersolvable"]
                                if lab not in data[tbl]:
                                    # We didn't succeed in relabeling this group, so we skip updating B
                                    continue
                            #if line["metacyclic"] == r"\N":
                            #    del line["metacyclic"]
                        elif code == "S" and loading_new:
                            if lab in data[tbl]:
                                data[tbl][lab]["updated"] = set([col for col in ["centralizer", "core", "normal_closure", "normalizer", "complements", "contained_in", "contains", "normal_contained_in", "normal_contains"] if line.get(col, r"\N") != r"\N"])
                            else:
                                # We didn't succeed in relabeling, so we ignore this line
                                continue
                            if line["special_labels"] == "{}":
                                # For some reason, special labels didn't get computed in this run so we don't want to overwrite valid special labels with an empty list
                                del line["special_labels"]
                        elif code == "P":
                            # Special labels are {""} when they should be {}
                            if line["special_labels"] == '{""}':
                                line["special_labels"] = "{}"
                        elif code == "K" and lab not in data[tbl]:
                            badK.add(".".join(lab.split(".")[:2]))
                            continue
                        #elif code == "i" and line["eulerian_function"] == r"\N":
                        #    # We recomputed rank but not Eulerian function; don't want to wipe out old data
                        #    del line["eulerian_function"]
                    to_update = data[tbl][lab]
                    for col, val in line.items():
                        if val != r"\N":
                            if to_update.get(col, r"\N") != r"\N" and to_update[col] != val:
                                if (tbl,col) not in changed_cols:
                                    changed_cols[tbl,col] = lab
                            to_update[col] = val
        if reset_labels and "SubGrp" in data:
            # Need label to be unique since we're reseting keys below
            # Since these subgroups did not show up in results in newer_collated, we set them to arbitrary unique values for now; we will reset these in revise_subgroup_labels
            ctr = 0
            for D in data["SubGrp"].values():
                if D["label"] is None:
                    D["label"] = f"NULL{ctr}"
                    ctr += 1
            data["SubGrp"] = {E["label"]: E for E in data["SubGrp"].values()}
        if cache_labels and "SubGrp" in data:
            # We need to set stored_label so that revise_subgroup_labels works
            for D in data["SubGrp"].values():
                D["stored_label"] = D["label"]

    def wipe_bad_tex(label, data):
        for D in data["SubGrp"].values():
            H = D.get("subgroup", r"\N")
            if H != r"\N":
                if H.split(".")[0] != D["subgroup_order"] or r"\N" != hash_lookup.get(H, r"\N") != D.get("subgroup_hash", r"\N") != r"\N":
                    # Bad subgroup identification
                    D["subgroup"] = D["subgroup_tex"] = r"\N"
            Q = D.get("quotient", r"\N")
            if Q != r"\N":
                if Q.split(".")[0] != D["quotient_order"] or r"\N" != hash_lookup.get(Q, r"\N") != D.get("quotient_hash", r"\N") != r"\N":
                    # Bad quotient identification
                    D["quotient"] = D["quotient_tex"] = r"\N"

    def ord_counter(group):
        N, i = group.split(".")
        if i.isdigit():
            return N, i
        else:
            return N, str(class_to_int(i) + 1)

    def fill(label, data):
        # First we delete entries that don't fit within numeric's 131072 digit limit
        for tbl, X in data.items():
            for D in X.values():
                for col, val in list(D.items()):
                    if isinstance(val, str) and len(val) >= 131072:
                        parts = re.split(r"(\D+)", val)
                        if any(len(part) >= 131072 for part in parts):
                            del D[col]
        # Now fill in aut and outer gens with the best option computed
        G = data["Grp"][label]
        def check(typ, i):
            stubs = ["gens", "gen_orders", "perms"]
            if typ == "outer":
                stubs.append("gen_pows")
            return all(f"{typ}_{x}{i}" in G for x in stubs)
        def set_by_type(typ, i):
            G[f"{typ}_gens"] = G[f"{typ}_gens{i}"]
            G[f"{typ}_gen_orders"] = G[f"{typ}_gen_orders{i}"]
            G[f"{typ}_perms"] = G[f"{typ}_perms{i}"]
            if typ == "outer":
                G[f"{typ}_gen_pows"] = G[f"{typ}_gen_pows{i}"]
        for typ in ["aut", "outer"]:
            for i in [3,2,1,0]:
                if check(typ, i):
                    set_by_type(typ, i)
                    break
        # Set group_order, group_counter in GrpConjCls
        N, G_ctr = ord_counter(label)
        n = ZZ(N)
        if "GrpConjCls" in data:
            # Remove conjugacy class data when more than the limit for storing rational character tables
            if ("GrpChtrCC" not in data and "GrpChtrQQ" not in data and
                ("number_divisions" not in G or int(G["number_divisions"]) >= 512) and
                ("number_conjugacy_classes" not in G or int(G["number_conjugacy_classes"]) >= 512)):
                # No characters stored, so we delete conjugacy classes to save space
                del data["GrpConjCls"]
                G["conjugacy_classes_known"] = "f";
            else:
                cc_by_counter = sorted(data["GrpConjCls"].values(), key=lambda rec: int(rec["counter"]))
                cc_sizes = [int(cc["size"]) for cc in cc_by_counter]
                if "conj_centralizers" in G:
                    Z = G["conj_centralizers"][1:-1].split(",")
                    assert len(cc_by_counter) == len(Z)
                else:
                    Z = [r"\N"] * len(cc_by_counter)
                for D, z in zip(cc_by_counter, Z):
                    D["group_order"], D["group_counter"] = N, G_ctr
                    if z != r"\N":
                        # We may have set this already using cent_collated, so don't want to overwrite with null
                        D["centralizer"] = z
                G["conjugacy_classes_known"] = "t";
        else:
            G["conjugacy_classes_known"] = "f";
        if "GrpChtrCC" in data:
            char_by_counter = sorted(data["GrpChtrCC"].values(), key=lambda rec: int(rec["counter"]))
            if "charc_centers" in G:
                Z = G["charc_centers"][1:-1].split(",")
                assert len(char_by_counter) == len(Z)
            else:
                Z = [r"\N"] * len(char_by_counter)
            if "charc_kernels" in G:
                K = G["charc_kernels"][1:-1].split(",")
                assert len(char_by_counter) == len(K)
            else:
                K = [r"\N"] * len(char_by_counter)
            nib = G.get("normal_index_bound", r"\N")
            if nib == r"\N" and G.get("normal_subgroups_known") == "t":
                nib = "0"
            if nib != r"\N":
                nib = int(nib)
            nob = G.get("normal_order_bound", r"\N")
            if nob == r"\N" and G.get("normal_subgroups_known") == "t":
                nob = "0"
            if nob != r"\N":
                nob = int(nob)
            for D, z, k in zip(char_by_counter, Z, K):
                D["group_order"], D["group_counter"], D["center"], D["kernel"] = N, G_ctr, z, k
                d = D["dim"]
                if z != r"\N" and k != r"\N":
                    D["center_index"] = ci = z.split(".")[0]
                    D["center_order"] = str(n // ZZ(ci))
                    D["image_order"] = io = k.split(".")[0]
                    D["kernel_order"] = str(n // ZZ(io))
                    fullk = f"{label}.{k}"
                    if fullk in data["SubGrp"]:
                        D["image_isoclass"] = data["SubGrp"][fullk].get("quotient", r"\N")
                    else:
                        D["image_isoclass"] = r"\N"
                elif "GrpConjCls" in data:
                    # Reconstruct orders from values
                    values = D["values"][3:-3].split("]],[[")
                    if len(values) == len(cc_sizes):
                        ksize = csize = 0
                        for val, size in zip(values, cc_sizes):
                            if "],[" in val:
                                # Not a scalar times a root of unity
                                continue
                            if val.count(",") != 1:
                                with open("/scratch/grp/bad_charvalue", "a") as Fbad:
                                    _ = Fbad.write(f"C{label}|{D['label']}|{val}\n")
                                    break
                            c, i = val.split(",")
                            if c == d and i == "0":
                                ksize += size
                            if c == d or c == "-"+d:
                                csize += size
                        if ksize == 0 or n % ksize != 0 or csize == 0 or n % csize != 0:
                            with open("/scratch/grp/bad_charvalue", "a") as Fbad:
                                _ = Fbad.write(f"S{label}|{D['label']}|{ksize}|{csize}\n")
                        else:
                            D["center_order"] = str(csize)
                            D["center_index"] = str(n // csize)
                            D["kernel_order"] = str(ksize)
                            isize = n // ksize
                            D["image_order"] = str(isize)
                            if ksize == 1:
                                D["image_isoclass"] = label
                            elif isize == 1 or isize.is_prime():
                                D["image_isoclass"] = f"{isize}.1"
                            elif d == "1" and isize in cyclic_lookup:
                                D["image_isoclass"] = cyclic_lookup[isize]
                            elif "SubGrp" in data and nib != r"\N" and nob != r"\N" and (nib == 0 or isize <= nib or ksize <= nob):
                                opts = set(S.get("quotient",r"\N") for S in data["SubGrp"].values() if S["normal"] == "t" and S["quotient_order"] == str(isize))
                                if len(opts) == 1:
                                    D["image_isoclass"] = list(opts)[0]
                    else:
                        with open("/scratch/grp/bad_charvalue", "a") as Fbad:
                            _ = Fbad.write(f"Z{label}|{D['label']}|{len(values)}|{len(cc_size)}\n")
        if "GrpChtrQQ" in data:
            for D in data["GrpChtrQQ"].values():
                D["group_order"] = N
        if "SubGrp" in data:
            L = list(data["SubGrp"].values())
            L.sort(key=lambda rec: label_to_key(rec["short_label"]))
            for ctr, D in enumerate(L, 1):
                D["ambient_counter"] = G_ctr
                D["counter"] = str(ctr)
                D["ambient_tex"] = data["Grp"][label]["tex_name"]
                # Subgroups and quotient groups being marked cyclic without being identified was causing problems
                # In these cases, we can often find the id, so we do that here
                subord, quoord = ZZ(D["subgroup_order"]), ZZ(D["quotient_order"])
                if D.get("subgroup_cyclic") == "t" and subord in cyclic_lookup:
                    if D.get("subgroup", r"\N") == r"\N":
                        D["subgroup"] = cyclic_lookup[subord]
                    elif D["subgroup"] != cyclic_lookup[subord]:
                        with open("/scratch/grp/bad_cylic", "a") as Fbad:
                            _ = Fbad.write(f"S{label}|{D['short_label']}\n")
                if D.get("quotient_cyclic") == "t" and quoord in cyclic_lookup:
                    assert D["normal"] == "t"
                    if D.get("quotient", r"\N") == r"\N":
                        D["quotient"] = cyclic_lookup[quoord]
                    elif D["quotient"] != cyclic_lookup[quoord]:
                        with open("/scratch/grp/bad_cylic", "a") as Fbad:
                            _ = Fbad.write(f"Q{label}|{D['short_label']}\n")
                if D.get("central", r"\N") == "t" and D.get("abelian", r"\N") == "f":
                    D["central"] = "f"
        if label in elt_repr_to_perm:
            G["element_repr_type"] = "Perm"
        if label in special_names:
            repdic = eval(G["representations"])
            if "Lie" in repdic:
                lies = [(fam_sort[rec["family"]], rec["d"], rec["q"], rec["family"], tuple(rec.get("gens", []))) for rec in repdic["Lie"]]
                first = lies[0]
            else:
                lies = []
            lies = sorted(set(lies + [(fam_sort[fam], params["n"], params["q"], fam, ()) for (fam, params) in special_names[label]]))
            if G["element_repr_type"] == "Lie":
                assert "Lie" in repdic
                # Preserve first element
                lies = [first] + [lie for lie in lies if lie != first]
            def makeD(tup):
                D = {"d": tup[1], "q": tup[2], "family": tup[3]}
                if tup[4]:
                    D["gens"] = list(tup[4])
                return D
            repdic["Lie"] = [makeD(tup) for tup in lies]
            G["representations"] = str(repdic).replace(" ", "").replace("'", '"')
        if label in solvable_rep_additions:
            repdic = eval(G["representations"])
            if "PC" in repdic:
                repdic["PC"].update(solvable_rep_additions[label])
            else:
                repdic["PC"] = solvable_rep_additions[label]
            G["representations"] = str(repdic).replace(" ", "").replace("'", '"')
        if G.get("simple") == "t" and G.get("abelian") == "f":
            G["almost_simple"] = "t"
        if G.get("rank", r"\N") == r"\N" and G.get("easy_rank", "-1") != "-1":
            G["rank"] = G["easy_rank"]
        if G.get("solvability_type", r"\N") == r"\N" and G.get("backup_solvability_type", r"\N") != r"\N":
            G["solvability_type"] = G["backup_solvability_type"]
        if G.get("order_factorization_type", r"\N") == r"\N":
            F = n.factor()
            if len(F) == 0:
                G["order_factorization_type"] = "0"
            else:
                m, M = min(e for (p,e) in F), max(e for (p,e) in F)
                if len(F) == 1:
                    if 4 <= M <= 6:
                        M = 3
                    elif M > 7:
                        M = 7
                    G["order_factorization_type"] = str(M)
                elif M == 1:
                    G["order_factorization_type"] = "11"
                elif len(F) == 2:
                    if M == 2:
                        G["order_factorization_type"] = "22"
                    elif m == 1 and M < 5:
                        G["order_factorization_type"] = "31"
                    elif m == 1:
                        G["order_factorization_type"] = "51"
                    elif m == 2:
                        G["order_factorization_type"] = "32"
                    else:
                        G["order_factorization_type"] = "33"
                elif M == 2:
                    G["order_factorization_type"] = "222"
                elif len([p for (p,e) in F if e > 1]) == 1:
                    G["order_factorization_type"] = "311"
                else:
                    G["order_factorization_type"] = "321"
        #for x in ["normal_subgroups_known", "all_subgroups_known", "maximal_subgroups_known", "subgroup_inclusions_known", "sylow_subgroups_known"]:
        #    if G.get(x, r"\N") == r"\N":
        #        G[x] = "f"
        if G.get("normal_counts", r"\N") == r"\N" and G.get("normal_subgroups_known") == "t":
            nctr = Counter()
            for rec in data["SubGrp"].values():
                if rec["normal"] == "t":
                    nctr[rec["subgroup_order"]] += int(rec["count"])
            G["normal_counts"] = "{" + ",".join(str(nctr[d]) for d in n.divisors()) + "}"
        for x in ["normal_index_bound", "normal_order_bound"]:
            if G.get(x, r"\N") == r"\N" and G.get("normal_subgroups_known") == "t":
                G[x] = "0"
        if "GrpChtrCC" in data and "GrpChtrQQ" in data and "SubGrp" in data and G.get("normal_subgroups_known") == "t" and G["outer_equivalence"] == "f" and any(G.get(x, r"\N") == r"\N" for x in ["irrR_degree", "linR_count", "linQ_degree_count", "linQ_dim_count", "irrQ_dim", "linR_degree", "linQ_dim", "linC_count"]) and all(rec.get("mobius_quo", r"\N") != r"\N" and rec.get("normal_contains", r"\N") != r"\N" for rec in data["SubGrp"].values() if rec["normal"] == "t"):
            sub_in = [{"short_label": rec["short_label"], "count": ZZ(rec["count"]), "mobius_quo": ZZ(rec["mobius_quo"]), "normal_contains": rec["normal_contains"][1:-1].split(",")} for rec in data["SubGrp"].values() if rec["normal"] == "t"]
            cchars_in = [{"label": rec["label"], "dim": ZZ(rec["dim"]), "kernel": rec["kernel"], "faithful": rec["faithful"] == "t", "indicator": ZZ(rec["indicator"])} for rec in data["GrpChtrCC"].values()]
            qchars_in = [{"label": rec["label"], "qdim": ZZ(rec["qdim"]), "schur_index": ZZ(rec["schur_index"]), "faithful": rec["faithful"] == "t"} for rec in data["GrpChtrQQ"].values()]
            mobius, poset = poset_data(sub_in=sub_in)
            Cchars, irrC_degree, Rchars, irrR_degree, Qchars_deg, irrQ_degree, Qchars_dim, irrQ_dim = char_data(cchars_in=cchars_in, qchars_in=qchars_in)
            linC, linC_count = linC_degree(label, irrC_degree=irrC_degree, mobius=mobius, poset=poset, chars=Cchars)
            linR, linR_count = linR_degree(label, irrR_degree=irrR_degree, mobius=mobius, poset=poset, chars=Rchars)
            Q_deg, Qdeg_count = linQ_degree(label, irrQ_degree=irrQ_degree, mobius=mobius, poset=poset, chars=Qchars_deg)
            Q_dim, Qdim_count = linQ_dim(label, irrQ_dim=irrQ_dim, mobius=mobius, poset=poset, chars=Qchars_dim)
            G["irrC_degree"], G["linC_degree"], G["linC_count"], G["irrR_degree"], G["linR_degree"], G["linR_count"], G["irrQ_degree"], G["linQ_degree"], G["linQ_degree_count"], G["irrQ_dim"], G["linQ_dim"], G["linQ_dim_count"] = [str(x) for x in [irrC_degree, linC, linC_count, irrR_degree, linR, linR_count, irrQ_degree, Q_deg, Qdeg_count, irrQ_dim, Q_dim, Qdim_count]]

    try:
        label_source = db.gps_groups.search({}, "label")
        if start is None:
            for oname, (final_cols, final_types) in finals.items():
                _ = writers[oname].write("|".join(final_cols) + "\n" + "|".join(final_types) + "\n\n")
        else:
            label_source = islice(label_source, start, db.gps_groups.count(), step)
        for j, label in enumerate(label_source): # Fixes the ordering correctly
            if j % 1000 == 0:
                print(f"Writing {j} ({label})...         ", end="\r")
            # Load data
            data = defaultdict(lambda: defaultdict(dict))
            if label in pcredo:
                load_file(data, rep_coll / label, cache_labels=True)
            else:
                load_file(data, cur_coll / label, skip_cc=True)
                wipe_bad_tex(label, data)
                load_file(data, fix_coll / label, skip_cc=True)

                # The PhiG data needs to be fixed before changing subgroup labels
                if label in PhiG:
                    special = PhiG[label]
                    for old_label, rec in data["SubGrp"].items():
                        if "Phi" in rec["special_labels"]:
                            rec["special_labels"] = rec["special_labels"].replace("Phi", "").replace(",,", ",").replace(",}", "}").replace("{,", "{")
                        if old_label == special:
                            if rec["special_labels"] == "{}":
                                rec["special_labels"] = "{Phi}"
                            else:
                                rec["special_labels"] = rec["special_labels"].replace("}", ",Phi}")
                # Do central_quotient and commutator manually
                if label == "81920.dml":
                    data["Grp"][label]["central_quotient"] = r"\N"
                elif label == "31104.el":
                    data["Grp"][label]["commutator_label"] = r"\N"

                load_file(data, boo_coll / label)
                load_file(data, new_coll / label, reset_labels=True) # Here we change the keys for data["SubGrp"] to use the labels computed in the new run
                load_file(data, cen_coll / label)
                #load_file(data, con_coll / label) # Load centralizers of conjugacy classes into conj_centralizers in data["Grp"]; these are in the new conjugacy class order but use old subgroup labels, which are corrected in revise_subgroup_labels
                load_file(data, new_coll / label, loading_new=True)
                load_file(data, aut_coll / label) # Load new automorphism group data
            fill(label, data)
            revise_subgroup_labels(label, data) # Here we change subgroup labels to the new format
            # Note that we don't bother to reset the keys in data["SubGrp"]

            # TODO: check invalid subgroup label matches in comparing new and old subool data
            for tbl, (cols, types) in finals.items():
                dtbl = "SubGrp" if tbl.startswith("SubGrp") else tbl
                D = data[dtbl]
                if tbl == "Grp":
                    L = list(D.values())
                else:
                    L = sorted(D.values(), key=lambda rec: rec["counter"])
                if not L:
                    continue
                if start is None:
                    F = writers[tbl]
                else:
                    F = open(out_coll / f"{tbl}_{label}", "w")
                try:
                    for rec in L:
                        line = "|".join(rec.get(col, r"\N") for col in cols) + "\n"
                        if "?" in line:
                            badQ.add(label)
                        _ = F.write(line)
                finally:
                    if start is not None:
                        F.close()
        print("Writing done!            ")
    except Exception as err:
        with open("/scratch/grp/create_upload_files_errors.txt", "a") as F:
            _ = F.write(f"Error with start={start}, step={step}\n" + str(err))
        print(f"Writing {j} ({label})...             ") # Don't overwrite status message earlier
        raise
    finally:
        if start is None:
            for F in writers.values():
                F.close()
    return badK, badQ, changed_cols

"""
TODO
Broken groups recomputed: /scratch/grp/pcredo.output
- needs to be collated - done, in /scratch/grp/replace_collated (along with 43 of the bad 47)
Subgroup relabel: /scratch/grp/bigfix/sub_relabel.txt
- there were some groups with the wrong number of subgroups; these probably need to be completely recomputed (done to the extent possible)
- make sure that the pcredo cases are handled correctly
Corrected latex: /scratch/grp/NewTexNames.txt, /scratch/grp/NewSubgroupTexNames.txt, /scratch/grp/NewAmbientTexNames.txt, /scratch/grp/NewQuotientTexNames.txt
- these are in terms of the old labels; the cases with wrong number of subgroups needs to be addressed
- Make sure names appropriately propogated to subgroups


* Some broken special labels have been recomputed (stored in /home/roed/FiniteGroups/Code/DATA/check_special_out/)
- db.gps_groups.lookup("81920.dml", "central_quotient") should be null, not 1024.dkf - done
- db.gps_groups.lookup("31104.el", "commutator_label") should be null, not 3888.cz - done
- various Frattini problems
* New boolean quantities for subgroups are computed (stored in /scratch/grp/subool in terms of old labels, and for most groups in /scratch/grp/new_collated/)
- for metacyclic, take the non-null value
- for quotient_supersolvable, recomputation had a bug so use the old one or leave null.
* Incorrect subgroup, quotient labels have been deleted, and sylow and hall recomputed with the results stored in /scratch/grp/SubData.txt
* Recomputed characteristic subgroup data is stored in /scratch/grp/char_check
* New complex and rational characters, and conjugacy class data is stored in /scratch/grp/newer_collated
"""

@cached_function
def can_identify(N):
    if N <= 2000:
        return N not in [512, 1024, 1152, 1536, 1920]
    return bool(magma.CanIdentifyGroup(N))

def set_preload_label_info():
    os.makedirs("DATA/preload_label_info", exist_ok=True)
    def make_label_info(subs):
        # Sanitize subs by removing entries where v={None}, and changing None to be last
        newsubs = {}
        for k, v in subs.items():
            if None in v:
                if len(v) == 1:
                    continue
                v = [x for x in v if x is not None] + [r"\N"]
            newsubs[k] = v
        return "{" + ",".join(f'''[{k[0]},{k[1]}]:["{'","'.join(v)}"]''' for (k,v) in newsubs.items()) + "}"
    def set_for_amb(ambient, subs, quos):
        # Need to make sure file exists, but I think they all do
        with open("DATA/preload/" + ambient) as F:
            keys, vals = F.read().strip().split("\n")
            keys += "|subgroup_label_info|quotient_label_info"
            vals += f"|{make_label_info(subs)}|{make_label_info(quos)}"
            with open("DATA/preload_label_info/" + ambient, "w") as Fout:
                _ = Fout.write(f"{keys}\n{vals}\n")
    amb = None
    hash_lookup = {rec["label"]: rec["hash"] for rec in db.gps_groups.search({}, ["label", "hash"])}
    for rec in db.gps_subgroups.search({"outer_equivalence":True, "ambient_order":{"$or":[{"$gt":2000}, {"$in":[512,1024,1152,1536,1920]}]}}, ["ambient", "subgroup", "subgroup_hash", "subgroup_order", "quotient", "quotient_hash", "quotient_order", "normal"]):
        if rec["ambient"] != amb:
            if amb is not None:
                set_for_amb(amb, subs, quos)
            subs = defaultdict(set)
            quos = defaultdict(set)
            amb = rec["ambient"]
        sub = rec["subgroup"]
        sash = rec["subgroup_hash"]
        if sub is not None:
            # Check that the order and hash are sane
            sord = int(sub.split(".")[0])
            gash = hash_lookup.get(sub)
            if sord != rec["subgroup_order"] or gash is not None and sash is not None and gash != sash:
                # broken identification
                sub = None
        sord = rec["subgroup_order"]
        if sash is None:
            sash = 0
        quo = rec["quotient"]
        qash = rec["quotient_hash"]
        if quo is not None:
            # Check that order and hash are sane
            qord = int(quo.split(".")[0])
            gash = hash_lookup.get(quo)
            if qord != rec["quotient_order"] or gash is not None and qash is not None and gash != qash:
                # broken identification
                quo = None
        qord = rec["quotient_order"]
        if qash is None:
            qash = 0
        if not can_identify(sord):
            subs[sord, sash].add(sub)
        if rec["normal"] and not can_identify(qord):
            quos[qord, qash].add(quo)
    set_for_amb(amb, subs, quos)
    for fname in os.listdir("DATA/preload"):
        if not os.path.exists("DATA/preload_label_info/" + fname):
            shutil.copy("DATA/preload/"+fname, "DATA/preload_label_info/"+fname)

def collate_upload_files():
    from cloud_collect import parse
    base = Path("/scratch/grp")
    out_coll = base / "out_collated"
    bigfix = base / "bigfix"
    H = headers()
    labels = list(db.gps_groups.search({}, "label"))
    labelset = set(labels)
    sub_pos, stex_pos, quo_pos, qtex_pos = [H["SubGrpSearch"][0].index(col) for col in ["subgroup", "subgroup_tex", "quotient", "quotient_tex"]]
    dup_tex = defaultdict(set)
    for i, label in enumerate(labels):
        if i%10000 == 0:
            print(f"Finding dup tex {i} ({label})...", end="\r")
        fname = out_coll / ("SubGrpSearch_" + label)
        if fname.exists():
            with open(fname) as F:
                for line in F:
                    pieces = line.split("|")
                    sub, sub_tex = pieces[sub_pos], pieces[stex_pos]
                    if sub != r"\N" and sub_tex != r"\N" and sub.split(".")[-1].isdigit() and sub not in labelset:
                        dup_tex[sub].add(sub_tex)
                    quo, quo_tex = pieces[quo_pos], pieces[qtex_pos]
                    if quo != r"\N" and quo_tex != r"\N" and quo.split(".")[-1].isdigit() and quo not in labelset:
                        dup_tex[quo].add(quo_tex)
    print(f"Done finding dup tex ({len(dup_tex)} found)              ")
    common_tex = {}
    for label, S in dup_tex.items():
        if len(S) > 1:
            opts = [parse(s.replace("\\\\", "\\")) for s in S]
            opts.sort(key=lambda s: (s.value, 1000000000 if s.order is None else s.order, s.latex))
            common_tex[label] = opts[0].latex.replace("\\", "\\\\") # double backslashes for loading into postgres
    for tbl in ["Grp", "SubGrpSearch", "SubGrpData", "GrpConjCls", "GrpChtrCC", "GrpChtrQQ"]:
        print("Starting", tbl)
        with open(bigfix / (tbl + ".txt"), "w") as Fout:
            _ = Fout.write("|".join(H[tbl][0]) + "\n" + "|".join(H[tbl][1]) + "\n\n")
            for i, label in enumerate(labels):
                if i%10000 == 0:
                    print(f"Writing {i} ({label})....", end="\r")
                fname = out_coll / f"{tbl}_{label}"
                if fname.exists():
                    with open(fname) as F:
                        for line in F:
                            if tbl == "SubGrpSearch":
                                pieces = line.split("|")
                                sub, quo = pieces[sub_pos], pieces[quo_pos]
                                if sub in common_tex:
                                    pieces[stex_pos] = common_tex[sub]
                                if quo in common_tex:
                                    pieces[qtex_pos] = common_tex[quo]
                                line = "|".join(pieces)
                            _ = Fout.write(line)
        print(f"Done writing {tbl}!                          ")


if sys.argv[0] == "./fix_labeltex15.py":
    start = int(sys.argv[1])
    with open("/scratch/grp/step") as F:
        step = int(F.read())
    badK, badQ, changed_cols = create_upload_files(start=start, step=step, overwrite=True)
    if badK:
        with open("/scratch/grp/badK", "a") as F:
            _ = F.write("\n".join(badK)+"\n")
    if badQ:
        with open("/scratch/grp/badQ", "a") as F:
            _ = F.write("\n".join(badQ)+"\n")

    if changed_cols:
        with open("/scratch/grp/changed_cols", "a") as F:
            for (tbl, col), lab in changed_cols.items():
                _ = F.write(f"{tbl}:{col}: {lab}\n")
