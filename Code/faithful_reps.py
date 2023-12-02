#!/usr/bin/env -S sage -python

from sage.all import PowerSeriesRing, ZZ, Poset
from collections import defaultdict, Counter
import os, sys, re, time, argparse
CHAR_LABEL_RE = re.compile(r"(\d+\.[0-9a-z]+.\d+[a-z]+)\d*")

def poset_data(group):
    mobius = {}
    E = []
    for rec in db.gps_subgroups.search({"ambient": group, "normal":True}, ["short_label", "mobius_quo", "count", "normal_contains"]):
        assert rec["count"] == 1 # The algorithm doesn't work when we only have groups up to automorphism
        if rec["mobius_quo"] is None:
            raise ValueError("Missing mobius")
        mobius[rec["short_label"]] = rec["mobius_quo"]
        E.extend([(N, rec["short_label"]) for N in rec["normal_contains"]])
    poset = Poset([list(mobius), E], cover_relations=True)
    return mobius, poset

def char_data(group):
    Cchars = defaultdict(Counter)
    kernels = {}
    irrC_degree = -1
    for rec in db.gps_char.search({"group": group}, ["label", "dim", "kernel", "faithful"]):
        K = rec["kernel"]
        Cchars[K][rec["dim"]] += 1
        m = CHAR_LABEL_RE.match(rec["label"])
        qlabel = m.group(1)
        kernels[qlabel] = K
        if rec["faithful"]:
            irrC_degree = min(rec["dim"] if irrC_degree == -1 else irrC_degree, rec["dim"])
    Qchars = defaultdict(Counter)
    irrQ_degree = -1
    for rec in db.gps_qchar.search({"group": group}, ["label", "qdim", "schur_index", "faithful"]):
        d = rec["qdim"] * rec["schur_index"]
        Qchars[kernels[rec["label"]]][d] += 1
        if rec["faithful"]:
            irrQ_degree = min(d if irrQ_degree == -1 else irrQ_degree, d)
    return Cchars, irrC_degree, Qchars, irrQ_degree

def rep_series(prec, mobius, poset, chars):
    R = PowerSeriesRing(ZZ, "x")
    x = R.gen()
    f = R(0, prec)
    for N, mquo in mobius.items():
        if mquo == 0:
            continue
        g = R(1, prec)
        for K, D in chars.items():
            if poset.le(N, K):
                for d, char_count in D.items():
                    if d < prec:
                        g *= ((1 - x**d + R(0, prec)).inverse_of_unit())**char_count
        f += mquo * g
    return f

def linC_degree(group, prec=40, irrC_degree=None, mobius=None, poset=None, chars=None):
    group_order = ZZ(group.split(".")[0])
    if mobius is None or poset is None:
        mobius, poset = poset_data(group)
    if chars is None:
        chars, irrC_degree, _, _ = char_data(group)
    if irrC_degree != -1:
        # faithful irrep
        prec = irrC_degree + 1
    f = rep_series(prec, mobius, poset, chars)
    #print(f)
    if f.is_zero():
        assert prec < group_order
        # The actual degree may be more than our estimate, so we need to search until we find a representation
        return linC_degree(group, 2*prec, irrC_degree=irrC_degree, mobius=mobius, poset=poset, chars=chars)
    v = f.valuation()
    return v, f[v]

def linQ_degree(group, prec=40, irrQ_degree=None, mobius=None, poset=None, chars=None):
    group_order = ZZ(group.split(".")[0])
    if mobius is None or poset is None:
        mobius, poset = poset_data(group)
    if chars is None:
        _, _, chars, irrQ_degree = char_data(group)
    if irrQ_degree != -1:
        # faithful Q-irrep
        prec = irrQ_degree
    f = rep_series(prec, mobius, poset, chars)
    #print(f)
    if f.is_zero():
        # The actual degree may be more than our estimate
        assert prec < group_order
        return linQ_degree(group, 2*prec, irrQ_degree=irrQ_degree, mobius=mobius, poset=poset, chars=chars)
    v = f.valuation()
    return v, f[v]

def linCQ_degree(group):
    mobius, poset = poset_data(group)
    Cchars, irrC_degree, Qchars, irrQ_degree = char_data(group)
    linC, linC_count = linC_degree(group, irrC_degree=irrC_degree, mobius=mobius, poset=poset, chars=Cchars)
    linQ, linQ_count = linQ_degree(group, irrQ_degree=irrQ_degree, mobius=mobius, poset=poset, chars=Qchars)
    return linC, linC_count, linQ, linQ_count

def linQ_todo():
    # This function tests the algorithm by comparing with the stored representations in the 
    linQ = {}
    for rec in db.gps_groups.search({"order": {"$gt": 2}}, ["label", "representations"]):
        rep = rec["representations"]
        if "GLZ" in rep:
            linQ[rec["label"]] = rep["GLZ"]["d"]
    return linQ

def write_todo(n):
    todo = list(db.gps_groups.search({"normal_subgroups_known":True, "complex_characters_known":True, "rational_characters_known":True, "outer_equivalence":False}, "label"))
    for i in range(n):
        with open(f"DATA/faithful_in/{i}", "w") as F:
            for label in todo[i::n]:
                _ = F.write(label + "\n")
    todo = set(todo)
    with open("DATA/irrQ_degree.todo", "w") as F:
        for label in db.gps_groups.search({"rational_characters_known": True, "irrQ_degree":{"$exists":True}}, "label"):
            if label not in todo:
                _ = F.write(label + "\n")

def check_linQ(linQ):
    timings = {}
    missing_mobius = []
    invalid = []
    for group, r in linQ.items():
        t0 = time.time()
        try:
            rcomp = linQ_degree(group)
        except ValueError:
            missing_mobius.append(group)
            continue
        if rcomp != r:
            print("Invalid", group, r, rcomp)
            invalid.append((group, r, rcomp))
        timings[group] = time.time() - t0
    return timings, missing_mobius, invalid

parser = argparse.ArgumentParser()
parser.add_argument("n", type=int, nargs="?")
parser.add_argument("-i", action="store_true") # to support interactive use from Sage
args = parser.parse_args()
if args.n is not None:
    sys.path.append(os.path.expanduser("~/lmfdb"))
    from lmfdb import db
    infile = f"DATA/faithful_in/{args.n}"
    outfile = f"DATA/faithful_out/{args.n}"
    mobfile = f"DATA/faithful_mob/{args.n}"
    for x in ["out", "mob"]:
        os.makedirs(f"DATA/faithful_{x}", exist_ok=True)
    with open(infile) as F:
        with open(outfile, "w") as Fout:
            with open(mobfile, "w") as Fmob:
                for label in F:
                    label = label.strip()
                    try:
                        linC, linC_count, linQ, linQ_count = linCQ_degree(label)
                    except ValueError:
                        _ = Fmob.write(label + "\n")
                    else:
                        _ = Fout.write(f"{label}|{linC}|{linQ}|{linC_count}|{linQ_count}\n")
