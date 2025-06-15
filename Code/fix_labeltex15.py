#!/usr/bin/env -S sage -python

# Usage: parallel -j40 --results /scratch/grp/create_upload_output ./fix_labeltex15.py {} ::: {0..39}
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
    oe = (data["Grp"][label]["outer_equivalence"] == "t")
    if oe:
        canre = re.compile(r"\d+\.[0-9a-z]+\.\d+\.[a-z]+\d+")
    else:
        canre = re.compile(r"\d+\.[0-9a-z]+\.\d+\.[a-z]+\d+\.[a-z]+\d+")
    sib = int(data["Grp"][label]["subgroup_index_bound"])
    def noncanonical(ind, Ds):
        if ind == 1 or ind == N or (ind.is_prime_power() and ind.gcd(N // ind) == 1):
            return False
        if sib != 0 and ind > sib:
            return True
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
            for D in Ds:
                D["short_label"] = long_to_short(D["label"])
    old_lookup = {long_to_short(D["stored_label"]): D["short_label"] for D in data["SubGrp"].values()}
    new_lookup = {long_to_short(D["label"]): D["short_label"] for D in data["SubGrp"].values()}
    old_lookup[r"\N"] = new_lookup[r"\N"] = r"\N"
    for D in data["SubGrp"].values():
        if D.get("updated"):
            # Some columns have been updated while loading newer_collated
            lookup = new_lookup
        else:
            lookup = old_lookup
        D["label"] = f"{D['ambient']}.{D['short_label']}"
        if "_" in D["short_label"]:
            D["aut_label"] = r"\N"
        else:
            D["aut_label"] = ".".join(D["short_label"].split(".")[:2])
        for col in ["centralizer", "core", "normal_closure", "normalizer"]:
            D[col] = lookup[D[col]]
        for col in ["complements", "contained_in", "contains", "normal_contained_in", "normal_contains"]:
            if D[col] not in [r"\N", "{}"]:
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
    # Make sure _others and WebAbstractSupergroup are working with only gps_subgroup_search data.
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

    tmps = tmpheaders()
    tbl_codes = {"Grp": "abcdefghijklmnopqrstuvwzGM012345678@#%",
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
                                data[tbl][lab]["updated"] = True
                            else:
                                # We didn't succeed in relabeling, so we ignore this line
                                continue
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
                for col, val in D.items():
                    if len(val) >= 131072:
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
        def set(typ, i):
            G[f"{typ}_gens"] = G[f"{typ}_gens{i}"]
            G[f"{typ}_gen_orders"] = G[f"{typ}_gen_orders{i}"]
            G[f"{typ}_perms"] = G[f"{typ}_perms{i}"]
            if typ == "outer":
                G[f"{typ}_gen_pows"] = G[f"{typ}_gen_pows{i}"]
        for typ in ["aut", "outer"]:
            for i in [3,2,1,0]:
                if check(typ, i):
                    set(typ, i)
                    break
        # Set group_order, group_counter in GrpConjCls
        N, c = ord_counter(label)
        n = ZZ(N)
        if "GrpConjCls" in data:
            # Remove conjugacy class data when more than the limit for storing rational character tables
            if ("GrpChtrCC" not in data and "GrpChtrQQ" not in data and
                ("number_divisions" not in G or int(G["number_divisions"]) >= 512) and
                ("number_conjugacy_classes" not in G or int(G["number_conjugacy_classes"]) >= 512)):
                # No characters stored, so we delete conjugacy classes to save space
                del data["GrpConjCls"]
            else:
                L = sorted(data["GrpConjCls"].values(), key=lambda rec: int(rec["counter"]))
                if "conj_centralizers" in G:
                    Z = G["conj_centralizers"][1:-1].split(",")
                    assert len(L) == len(Z)
                else:
                    Z = [r"\N"] * len(L)
                for D, z in zip(L, Z):
                    D["group_order"], D["group_counter"] = N, c
                    if z != r"\N":
                        # We may have set this already using cent_collated, so don't want to overwrite with null
                        D["centralizer"] = z
        if "GrpChtrCC" in data:
            L = sorted(data["GrpChtrCC"].values(), key=lambda rec: int(rec["counter"]))
            if "charc_centers" in G:
                Z = G["charc_centers"][1:-1].split(",")
                assert len(L) == len(Z)
            else:
                Z = [r"\N"] * len(L)
            if "charc_kernels" in G:
                K = G["charc_kernels"][1:-1].split(",")
                assert len(L) == len(K)
            else:
                K = [r"\N"] * len(L)
            for D, z, k in zip(L, Z, K):
                D["group_order"], D["group_counter"], D["center"], D["kernel"] = N, c, z, k
                if z != r"\N":
                    D["center_index"] = ci = z.split(".")[0]
                    D["center_order"] = str(n // ZZ(ci))
                if k != r"\N":
                    D["image_order"] = io = k.split(".")[0]
                    D["kernel_order"] = str(n // ZZ(io))
                    fullk = f"{label}.{k}"
                    if fullk in data["SubGrp"]:
                        D["image_isoclass"] = data["SubGrp"][fullk].get("quotient", r"\N")
                    else:
                        D["image_isoclass"] = r"\N"
        if "GrpChtrQQ" in data:
            for D in data["GrpChtrQQ"].values():
                D["group_order"] = N
        if "SubGrp" in data:
            L = list(data["SubGrp"].values())
            L.sort(key=lambda rec: label_to_key(rec["short_label"]))
            for ctr, D in enumerate(L, 1):
                D["ambient_counter"] = c
                D["counter"] = str(ctr)
                D["ambient_tex"] = data["Grp"][label]["tex_name"]
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
        for x in ["normal_subgroups_known", "all_subgroups_known", "maximal_subgroups_known", "subgroup_inclusions_known", "sylow_subgroups_known"]:
            if G.get(x, r"\N") == r"\N":
                G[x] = "f"
        if G.get("normal_counts", r"\N") == r"\N" and G["normal_subgroups_known"] == "t":
            nctr = Counter()
            for rec in data["SubGrp"].values():
                if rec["normal"] == "t":
                    nctr[rec["subgroup_order"]] += int(rec["count"])
            G["normal_counts"] = "{" + ",".join(str(nctr[d]) for d in n.divisors()) + "}"
        for x in ["normal_index_bound", "normal_order_bound"]:
            if G.get(x, r"\N") == r"\N" and G["normal_subgroups_known"] == "t":
                G[x] = "0"
        if "GrpChtrCC" in data and "GrpChtrQQ" in data and "SubGrp" in data and G["normal_subgroups_known"] == "t" and G["outer_equivalence"] == "f" and any(G.get(x, r"\N") == r"\N" for x in ["irrR_degree", "linR_count", "linQ_degree_count", "linQ_dim_count", "irrQ_dim", "linR_degree", "linQ_dim", "linC_count"]) and all(rec.get("mobius_quo", r"\N") != r"\N" and rec.get("normal_contains", r"\N") != r"\N" for rec in data["SubGrp"].values() if rec["normal"] == "t"):
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
    except Exception:
        with open("/scratch/grp/create_upload_files_errors.txt", "a") as F:
            _ = F.write(f"Error with start={start}, step={step}\n")
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
