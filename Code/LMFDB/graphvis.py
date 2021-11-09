"""
This file is used for experimenting with the Graphviz program for graph layout
"""

from lmfdb import db
from collections import defaultdict

def approx_tex(s):
    return s.replace("_","").replace(r"\times", "x").replace("\\", "").replace(" ", "").replace("{","").replace("}","").replace("rm","")

def make_dot_file(label, ofile):
    nodes = []
    edges = []
    ranks = defaultdict(list)
    for rec in db.gps_subgroups.search({"ambient": label}, ["short_label", "subgroup_tex", "subgroup_order", "contains"]):
        nodes.append((rec["short_label"], approx_tex(rec["subgroup_tex"])))
        edges.append((rec["short_label"], '" "'.join(rec["contains"])))
        ranks[rec["subgroup_order"]].append(rec["short_label"])
    edges = ";\n".join(f'"{a}" -> {{"{b}"}} [dir=none]' for (a, b) in edges)
    nodes = ";\n".join(f'"{name}" [label="{label}",shape=plaintext]' for (name, label) in nodes)
    ranks = ";\n".join('{rank=same; "%s"}' % ('" "'.join(labs)) for labs in ranks.values())
    data = f"""strict digraph "{label}" {{
rankdir=TB;
splines=line;
{edges};
{nodes};
{ranks};
}}
"""
    with open(ofile, "w") as F:
        F.write(data)
