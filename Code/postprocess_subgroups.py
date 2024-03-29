#!/usr/bin/env python3

# You need to first install graphviz, eg `sudo apt install graphviz`
# Call with `ls DATA/subgroups | parallel -j128 --timeout 3600 "./postprocess_subgroups.py {0}"`

import sys, os, re, subprocess, time, pathlib
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

def aut_label(label):
    return ".".join(label.split(".")[:-1])
def aut_graph(sdata):
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

def find_xcoords(label, sdata, alt=False):
    out_equiv = sdata[0][-1]
    # Make 2 or 4 graphs, depending on the value of outer_equivalence
    # Either (subs up to aut, normals up to aut) or
    #        (subs up to aut, normals up to aut, subs up to conj, normals)
    t = time.time()
    if not alt:
        ndata = induced_normal_graph(sdata)
        print(f"Normal graph computed in {time.time() - t:.3f}s")
    ida = lambda x: x
    if alt:
        if out_equiv:
            graphs = [(sdata, ida)]
        else:
            graphs = [(aut_graph(sdata), aut_label), (sdata, ida)]
    else:
        if out_equiv:
            graphs = [(sdata, ida), (ndata, ida)]
        else:
            graphs = [(aut_graph(sdata), aut_label), (aut_graph(ndata), aut_label), (sdata, ida), (ndata, ida)]
    for data, accessor in graphs:
        nodes = []
        edges = []
        ranks = defaultdict(list)
        for rec in data:
            nodes.append((rec[0], rec[1]))
            edges.append((rec[0], '","'.join(rec[3])))
            ranks[rec[2]].append(rec[0])
        nodes = [f'"{name}" [label="{tex}",shape=plaintext]' for (name, tex) in nodes]
        edges = [f'"{a}" -> {{"{b}"}} [dir=none]' for (a, b) in edges]
        if alt:
            R = sorted(ranks)
            for i in range(len(R)):
                order = R[i]
                nodes.append(f'"order{order}" [style="invis"]')
                if i > 0:
                    edges.append(f'"order{order}" -> "order{R[i-1]}" [style="invis"]')
                ranks[order].append(f'order{order}')
        nodes = ";\n".join(nodes)
        edges = ";\n".join(edges)
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
        t = time.time()
        subprocess.run(["dot", "-Tplain", "-o", outfile, infile], check=True)
        print(f"Graphvis ran in {time.time() - t:.3f}s")
        xcoord = {}
        with open(outfile) as F:
            maxx = 0
            minx = 10000
            for line in F:
                if line.startswith("graph"):
                    scale = float(line.split()[2])
                elif line.startswith("node"):
                    pieces = line.split()
                    short_label = pieces[1].replace('"', '')
                    if not short_label.startswith("order"):
                        diagram_x = int(round(10000 * float(pieces[2]) / scale))
                        xcoord[short_label] = diagram_x
                        if diagram_x > maxx:
                            maxx = diagram_x
                        if diagram_x < minx:
                            minx = diagram_x
        if alt:
            # We have to remove the phantom nodes used to set the ranks
            margin = min(minx, 10000-maxx)
            minx -= margin
            maxx += margin
            rescale = 10000 / (maxx - minx)
            for short_label, x in xcoord.items():
                xcoord[short_label] = int(round((x - minx) * rescale))
        os.remove(infile)
        os.remove(outfile)
        yield xcoord, accessor
    if alt and out_equiv:
        yield {sdatum[0]: 0 for sdatum in sdata}, ida

def process_all_lines(label=None, alt=True):
    if label is None:
        label = sys.argv[1]
    print(f"Starting {label}")
    with open("LMFDBSubGrp.header") as F:
        header = F.read().split("\n")[0].split("|")
    infile = opj("DATA", "subgroups", label)
    pathlib.Path(opj("DATA", "subgroups_fixed")).mkdir(parents=True, exist_ok=True)
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
    with open(infile) as F:
        for line in F:
            fixed_line, sdatum = process_subgroups_line(line, tex_spots, extract_spots, badfile)
            fixed_lines[sdatum[0]] = fixed_line
            sdatum[2] = int(sdatum[2]) # subgroup_order
            sdatum[3] = sdatum[3][1:-1].split(",") # contains
            sdatum[4] = (sdatum[4] == 't') # normal
            sdatum[5] = (sdatum[5] == 't') # outer_equivalence
            sdata.append(sdatum)
    graphs = list(find_xcoords(label, sdata, alt=alt))
    with open(outfile, "w") as F:
        for sdatum in sdata:
            if alt:
                label = sdatum[0]
                line = "|".join(str(G[access(label)]) for G,access in graphs)
                line = f"{label}|{line}\n"
            else:
                if sdatum[4]: # normal
                    x = [str(G[access(sdatum[0])]) for G,access in graphs]
                else:
                    x = [str(G[access(sdatum[0])]) for G,access in graphs[0:len(graphs):2]]
                line = fixed_lines[sdatum[0]] + "|{%s}\n" % (",".join(x))
            F.write(line)

process_all_lines()
