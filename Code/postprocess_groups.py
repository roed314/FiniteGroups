#!/usr/bin/env python3

# Call with `ls DATA/groups | parallel -j128 --timeout 3600 "./postprocess_groups.py {0}"`

import sys, os, re, subprocess, time, pathlib
opj = os.path.join
from collections import defaultdict

pathlib.Path("DATA/groups_fixed").mkdir(parents=True, exist_ok=True)

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
    (re.compile(r"(?:\{\\\\rm |^)(SD|OD|He)\}?_"), r"\\\\\1_"),
    (re.compile(r"(?:\{\\\\rm |^)(AGL|ASL|PGL|PSL|GL|SL|PSU|SU|PSO|SO|PGO|GO|PSp|Sp|AGammaL|ASigmaL|PGammaL|PSigmaL|PGammaU|PSigmaU|POmega|PSigmaSp)\}?"), r"\\\\\1"),
    (re.compile(r"\{\\\\rm wr(C|S|A|D|F|Q)\}_"), r"\\\\wr \1_"),
    (re.compile(r"\{\\\\rm wr\}"), r"\\\\wr "),
    (re.compile(r"Z/4"), r"\\\\Z/4"),
    (re.compile(r"\+"), "^+"), # for PSO+ and Omega+
    (re.compile(r"\-"), "^-"), # for PGO-, etc
    (re.compile(r"\\\\times"), r"\\\\times"), # for checking
    (re.compile(r"(C|S|A|D|F|Q)_"), r"\1_"), # for checking
]
check_re = re.compile(r"^[0-9\{\}\(\),^:\. ]*$") # what should be left after replacing all of the above regular expressions with empty strings instead of their normal replacement

def fix_latex(inp, badfile):
    if inp == r"\N":
        return inp
    check = out = inp
    for matcher, repl in latex_res:
        out = matcher.sub(repl, out)
        check = matcher.sub("", check)
    if not check_re.match(check):
        print(f"Bad latex: {inp} -> {out}")
        with open(badfile, "a") as F:
            F.write(inp + "\n")
    return out

def process_groups_line(line, tex_spots, badfile):
    # Fixes latex
    parts = line.strip().split("|")
    for i in tex_spots:
        parts[i] = fix_latex(parts[i], badfile)
    return "|".join(parts) + "\n"

def process_all_lines(label=None):
    if label is None:
        label = sys.argv[1]
    print(f"Starting {label}")
    with open("LMFDBGrp.header") as F:
        header = F.read().split("\n")[0].split("|")
    infile = opj("DATA", "groups", label)
    outfile = opj("DATA", "groups_fixed", label)
    badfile = opj("DATA", "badlatex")
    tex_spots = []
    clist = ["tex_name"]
    for (i, col) in enumerate(header):
        if col in clist:
            tex_spots.append(i)
    with open(infile) as F:
        with open(outfile, "w") as Fout:
            for line in F:
                Fout.write(process_groups_line(line, tex_spots, badfile))

process_all_lines()
