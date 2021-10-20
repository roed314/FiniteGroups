#!/usr/bin/env sage

# This file handles computations that are more easily done in Sage using the output of the Magma computations

# It should only be called after all data has been been computed, and currently isn't parallelized, so don't do anything too expensive

group_header_addition = [
    "faithful_cdim",
    "faithful_rdim",
    "faithful_qdim",
    "faithful_ccnt",
    "faithful_rcnt",
    "faithful_qcnt",
]
group_type_addition = ["integer"] * 6

import os, re
opj = os.path.join
from collections import defaultdict, Counter
from sage.rings.power_series_ring import PowerSeriesRing
from sage.rings.integer_ring import ZZ
from sage.misc.misc_c import prod
from sage.misc.cachefunc import cached_function

# Modified from lmfdb/utils/utilities.py
def letters2num(s):
    r"""
    Convert a string into a number
    """
    if s.isdigit():
        return int(s)
    ssum = 0
    for z in s:
        ssum = ssum*26+(ord(z)-96)
    return ssum

def label_sortkey(label):
    return tuple(letters2num(c) for c in label.split("."))

latex_res = [
    (re.compile(r"(?:\{\\rm |^)(SD|OD|He)\}?_"), r"\\\1_"),
    (re.compile(r"(?:\{\\rm |^)(AGL|ASL|PGL|PSL|GL|SL|PSU|SU|PSO|SO|PGO|GO|PSp|Sp|AGammaL|ASigmaL|PGammaL|PSigmaL|PGammaU|PSigmaU|POmega|PSigmaSp)\}?"), r"\\\1"),
    (re.compile(r"\{\\rm wr(C|S|A|D|F|Q)\}_"), r"\\wr \1_"),
    (re.compile(r"\{\\rm wr\}"), r"\\wr "),
    (re.compile(r"Z/4"), r"\\Z/4"),
    (re.compile(r"\+"), "^+"), # for PSO+ and Omega+
    (re.compile(r"\-"), "^-"), # for PGO-, etc
    (re.compile(r"\\times"), r"\\times"), # for checking
    (re.compile(r"(C|S|A|D|F|Q)_"), r"\1_"), # for checking
]
check_re = re.compile(r"^[0-9\{\}\(\),^:\. ]*$") # what should be left after replacing all of the above regular expressions with empty strings instead of their normal replacement

@cached_function
def fix_latex(inp, badfile):
    check = out = inp
    for matcher, repl in latex_res:
        out = matcher.sub(repl, out)
        check = matcher.sub("", check)
    if not check_re.match(check):
        with open(badfile, "a") as F:
            F.write(inp + "\n")
    return out

def faithful_generating_function(normal_subgroups, character_dims):
    R = PowerSeriesRing(ZZ, 'x', 200) ## FIX ME!
    x = R.gen()
    f = R(0)
    for N, Ndata in normal_subgroups.items():
        count, quotient, mobius = Ndata
        f += count * mobius * prod([(1 - x**d).inverse_of_unit()**m for (d,m) in character_dims[quotient].items()])
    return f

def old_faithful(group_data, normal_subgroups, character_data):
    for field in ["c", "r", "q"]:
        f = faithful_generating_function(normal_subgroups, character_data[field])
        group_data[f"faithful_{field}dim"] = str(f.valuation())
        group_data[f"faithful_{field}cnt"] = str(f[f.valuation()])

def process_group_line(line, old_header, normal_subgroups, character_data, badfile):
    parts = line.strip().split("|")
    assert len(parts) == len(old_header)
    data = dict(zip(old_header, parts))
    old_faithful(data, normal_subgroups[data["label"]], character_data)
    data["tex_name"] = fix_latex(data["tex_name"], badfile)
    new_header = old_header + group_header_addition
    return "|".join(data[col] for col in new_header) + "\n"

def process_subgroups_line(line, spots, badfile):
    parts = line.strip().split("|")
    for i in spots[0]:
        parts[i] = fix_latex(parts[i], badfile)
    line = "|".join(parts) + "\n"
    if parts[spots[1]] == 't':
        return line, {parts[spots[2]]: (int(parts[spots[3][0]]), parts[spots[3][1]], int(parts[spots[3][2]]))}
    else:
        return line, {}

def process_cchar_line(line, spots, character_data, label):
    parts = line.strip().split("|")
    dim = int(parts[spots[0]])
    character_data["c"][label][dim] += 1
    if parts[spots[1]] == '1': # real valued representation
        character_data["r"][label][dim] += 1
    elif parts[spots[1]] == '0': # complex valued character, so only one rep per conjugate pair
        character_data["r"][label][2*dim] += ZZ(1) / 2
    else: # quaternionic: real valued character, but complex valued rep
        character_data["r"][label][2*dim] += 1
    return line

def process_qchar_line(line, spots, character_data, label):
    parts = line.strip().split("|")
    dim = int(parts[spots[0]]) * int(parts[spots[1]])
    character_data["q"][label][dim] += 1
    return line

def collate_all(code_dir):
    raw_header, header = {}, {}
    for name, fname in [("groups", "Grp"), ("subs", "SubGrp"), ("ccs", "GrpConjCls"), ("cchar", "GrpChtrCC"), ("qchar", "GrpChtrQQ")]:
        with open(opj(code_dir, f"LMFDB{fname}.header")) as F:
            raw_header[name] = head = F.read()
            header[name] = head.split("\n")[0].split("|")
    parts = raw_header["groups"].split("\n")
    parts[0] += "|" + "|".join(group_header_addition)
    parts[1] += "|" + "|".join(group_type_addition)
    raw_header["groups"] = "\n".join(parts)
    data_dir = opj(code_dir, "DATA")
    output_dir = opj(code_dir, "LMFDB")
    badfile = opj(output_dir, "badlatex")
    normal_subgroups = defaultdict(dict)
    with open(opj(output_dir, "subs.data"), "w") as Fout:
        Fout.write(raw_header["subs"])
        subgroup_dir = opj(data_dir, "subgroups")
        labels = os.listdir(subgroup_dir)
        labels.sort(key=label_sortkey)
        tex_spots = []
        extract_spots = {}
        clist = ["count", "quotient", "mobius_quo"]
        for (i, col) in enumerate(header["subs"]):
            if col.endswith("_tex"):
                tex_spots.append(i)
            elif col == "short_label":
                short_label_spot = i
            elif col == "normal":
                normal_spot = i
            elif col in clist:
                extract_spots[col] = i
        extract_spots = [extract_spots[col] for col in clist]
        spots = (tex_spots, normal_spot, short_label_spot, extract_spots)
        for i, label in enumerate(labels):
            if i and i%100 == 0:
                print(f"processing subgroups: {i}/{len(labels)}")
            with open(opj(subgroup_dir, label)) as F:
                for line in F:
                    updated, N = process_subgroups_line(line, spots, badfile)
                    normal_subgroups[label].update(N)
                    Fout.write(updated)
    character_data = {field: defaultdict(Counter) for field in ["c", "r", "q"]}
    with open(opj(output_dir, "cchar.data"), "w") as Fout:
        Fout.write(raw_header["cchar"])
        cchar_dir = opj(data_dir, "characters_cc")
        labels = os.listdir(cchar_dir)
        labels.sort(key=label_sortkey)
        for (i, col) in enumerate(header["cchar"]):
            if col == "dim":
                dspot = i
            elif col == "indicator":
                ispot = i
        spots = (dspot, ispot)
        for i, label in enumerate(labels):
            if i and i%100 == 0:
                print(f"processing C-characters: {i}/{len(labels)}")
            with open(opj(cchar_dir, label)) as F:
                for line in F:
                    Fout.write(process_cchar_line(line, spots, character_data, label))
    with open(opj(output_dir, "qchar.data"), "w") as Fout:
        Fout.write(raw_header["qchar"])
        qchar_dir = opj(data_dir, "characters_qq")
        labels = os.listdir(qchar_dir)
        labels.sort(key=label_sortkey)
        for (i, col) in enumerate(header["qchar"]):
            if col == "qdim":
                dspot = i
            elif col == "schur_index":
                ispot = i
        spots = (dspot, ispot)
        for i, label in enumerate(labels):
            if i and i%100 == 0:
                print(f"processing Q-characters: {i}/{len(labels)}")
            with open(opj(qchar_dir, label)) as F:
                for line in F:
                    Fout.write(process_qchar_line(line, spots, character_data, label))
    with open(opj(output_dir, "groups.data"), "w") as Fout:
        Fout.write(raw_header["groups"])
        groups_dir = opj(data_dir, "groups")
        labels = os.listdir(groups_dir)
        labels.sort(key=label_sortkey)
        for i, label in enumerate(labels):
            if i and i%100 == 0:
                print(f"processing groups: {i}/{len(labels)}")
            with open(opj(groups_dir, label)) as F:
                for line in F:
                    updated = process_group_line(line, header["groups"], normal_subgroups, character_data, badfile)
                    Fout.write(updated)
    # Nothing to do for ccs except collate
    with open(opj(output_dir, "ccs.data"), "w") as Fout:
        Fout.write(raw_header["ccs"])
        ccs_dir = opj(data_dir, "groups_cc")
        labels = os.listdir(ccs_dir)
        labels.sort(key=label_sortkey)
        for i, label in enumerate(labels):
            if i and i%100 == 0:
                print(f"processing conjugacy classes: {i}/{len(labels)}")
            with open(opj(ccs_dir, label)) as F:
                Fout.write(F.read())

#collate_all(os.getcwd())
