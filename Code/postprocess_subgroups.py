#!/usr/bin/env python3

import sys, os, re, subprocess
opj = os.path.join
from collections import defaultdict

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

def fix_latex(inp, badfile):
    check = out = inp
    for matcher, repl in latex_res:
        out = matcher.sub(repl, out)
        check = matcher.sub("", check)
    if not check_re.match(check):
        with open(badfile, "a") as F:
            F.write(inp + "\n")
    return out

def process_subgroups_line(line, tex_spots, extract_spots, badfile):
    # Fixes latex and returns the data used for laying out the subgroup diagrams
    parts = line.strip().split("|")
    for i in tex_spots:
        parts[i] = fix_latex(parts[i], badfile)
    return "|".join(parts), [parts[i] for i in extract_spots]

def induced_normal_graph(sdata):
    sdata = [list(sdatum) for sdatum in sdata] # copy so able to modify below
    sdata.sort(key=lambda x: -x[2]) # sort by index
    pos = defaultdict(set)
    neg = defaultdict(set)
    final = defaultdict(set)
    for sdatum in sdata:
        label = sdatum[0]
        normal = sdatum[4]
        subs = sdatum[3]
        for top, cur in list(pos.items()):
            if label in cur:
                cur.remove(label)
                if label not in neg[top]:
                    if normal:
                        final[top].add(label)
                        neg[top].update(subs)
                    else:
                        cur.update(subs)
                if not cur:
                    del pos[top]
                    del neg[top]
        for top, cur in list(neg.items()):
            if label in cur:
                cur.remove(label)
                cur.update(subs)
        if normal:
            pos[label] = set(subs)
    ndata = []
    for sdatum in sdata:
        if sdatum[4]:
            sdatum[3] = sorted(final[sdatum[0]], key=label_sortkey)
            ndata.append(sdatum)
    return ndata

def aut_graph(sdata):
    def aut_label(label):
        return ".".join(label.split(".")[:-1])
    final = defaultdict(set)
    for sdatum in sdata:
        alabel = aut_label(sdatum[0])
        final[alabel].update([aut_label(lab) for lab in sdatum[3]])
    adata = []
    seen = set()
    for sdatum in sdata:
        alabel = aut_label(sdatum[0])
        if alabel in seen: continue
        new_datum = list(sdatum)
        new_datum[0] = alabel
        new_datum[3] = final[alabel]
        adata.append(new_datum)
    return adata

def find_xcoords(label, sdata):
    out_equiv = sdata[0][-1]
    # Make 2 or 4 graphs, depending on the value of outer_equivalence
    # Either (subs up to aut, normals up to aut) or
    #        (subs up to aut, normals up to aut, subs up to conj, normals)
    ndata = induced_normal_graph(sdata)
    if out_equiv:
        graphs = [sdata, ndata]
    else:
        graphs = [aut_graph(sdata), aut_graph(ndata), sdata, ndata]
    for data in graphs:
        nodes = []
        edges = []
        ranks = defaultdict(list)
        for rec in data:
            nodes.append((rec[0], rec[1]))
            edges.append((rec[0], '","'.join(rec[3])))
            ranks[rec[2]].append(rec[0])
        edges = ";\n".join(f'"{a}" -> {{"{b}"}} [dir=none]' for (a, b) in edges)
        nodes = ";\n".join(f'"{name}" [label="{tex}",shape=plaintext]' for (name, tex) in nodes)
        ranks = ";\n".join('{rank=same; "%s"}' % ('" "'.join(labs)) for labs in ranks.values())
        graph = f"""strict digraph "{label}" {{
rankdir=TB;
splines=line;
{edges};
{nodes};
{ranks};
}}
"""
        infile = f"/tmp/graph{label}.in"
        outfile = f"/tmp/graph{label}.out"
        with open(infile, "w") as F:
            F.write(graph)
        subprocess.run(["dot", "-Tplain", "-o", outfile, infile], check=True)
        xcoord = {}
        with open(outfile) as F:
            for line in F:
                if line.startswith("graph"):
                    scale = float(line.split()[2])
                elif line.startswith("node"):
                    pieces = line.split()
                    short_label = pieces[1].replace('"', '')
                    diagram_x = round(10000 * float(pieces[2]) / scale)
                    xcoord[short_label] = diagram_x
        os.remove(infile)
        os.remove(outfile)
        yield xcoord

def process_all_lines():
    label = sys.argv[1]
    with open("LMFDBSubGrp.header") as F:
        header = F.read().split("\n")[0].split("|")
    infile = opj("DATA", "subgroups", label)
    outfile = opj("DATA", "subgroups_fixed", label)
    badfile = opj("DATA", "badlatex")
    tex_spots = []
    extract_spots = {}
    clist = ["short_label", "subgroup_tex", "subgroup_order", "contains", "normal", "outer_equivalence"]
    for (i, col) in enumerate(header):
        if col.endswith("_tex"):
            tex_spots.append(i)
        if col in clist:
            extract_spots[col] = i
    extract_spots = [extract_spots[col] for col in clist]
    fixed_lines = {}
    sdata = []
    nodes = []
    edges = []
    ranks = defaultdict(list)
    with open(infile) as F:
        for line in F:
            fixed_line, sdatum = process_subgroups_line(line, tex_spots, extract_spots, badfile)
            fixed_lines[sdatum[0]] = fixed_line
            sdatum[2] = int(sdatum[2]) # subgroup_order
            sdatum[3] = sdatum[3][1:-1].split(",") # contains
            sdatum[4] = (sdatum[4] == 't') # normal
            sdatum[5] = (sdatum[5] == 't') # outer_equivalence
            sdata.append(sdatum)
    graphs = find_xcoords(label, sdata)
    with open(outfile, "w") as F:
        for sdatum in sdata:
            if sdatum[4]: # normal
                x = [str(G[sdatum[0]]) for G in graphs]
            else:
                x = [str(G[sdatum[0]]) for G in graphs[0:len(graphs):2]]
            line = fixed_lines[sdatum[0]] + "|{%s}\n" % (",".join(x))
            F.write(line)

process_all_lines()
