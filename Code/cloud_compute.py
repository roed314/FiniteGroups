#!/usr/bin/env python3

# This script is used to control the computation of group data so that we can still get some results even when certain computations time out.
# It takes as input an integer between 1 and the number of jobs, selects the appropriate magma script to execute under parallel, then transfers the output to a top-level "output" file.
# Errors, standard out and timing information are included in the output with an "E" or "T" prefix respectively

import os
import re
import time
import argparse
import subprocess
from collections import defaultdict
opj = os.path.join
ope = os.path.exists
err_location_re = re.compile(r'In file "(.*)", line (\d+), column (\d+):')
schur_re = re.compile("Runtime error in 'pMultiplicator': Cohomology failed")
basim_re = re.compile("Internal error in permc_random_base_change_basim_sub() at permc/chbase.c, line 488")
internal_re = re.compile(r'Magma: Internal error')

parser = argparse.ArgumentParser("Dispatch to appropriate magma script")
parser.add_argument("job", type=int, help="job number")

args = parser.parse_args()
job = args.job - 1 # shift from 1-based to 0-based indexing

# This sets the preload, but not the saved final values in basics
def set_preload(label, attr, value):
    fname = opj("DATA", "preload", label)
    with open(fname) as F:
        attrs, values = F.read().strip().split("\n")
        attrs = attrs.split("|")
        values = values.split("|")
        if attr in attrs:
            i = attrs.index(attr)
            values[i] = value
        else:
            attrs.append(attr)
            values.append(value)
    with open(fname, "w") as Fout:
        _ = Fout.write("|".join(attrs) + "\n" + "|".join(values) + "\n")

def read_tmpheader(name):
    with open(name + ".tmpheader") as F:
        code, cols = F.read().strip().split("\n")
        return cols.split("|")

def run(label, codes, timeout, subgroup_index_bound):
    subprocess.run('parallel -n0 --timeout %s "magma -b label:=%s codes:=%s ComputeCodes.m >> DATA/errors/%s 2>&1" ::: 1' % (timeout, label, codes, label), shell=True)
    # Move timing and error information to the common output file and extract timeout and error information
    sublines = []
    with open("output", "a") as Fout:
        t = opj("DATA", "timings", label)
        finished = ""
        time_used = 0
        if not ope(t):
            print("No timing file!", label)
            raise RuntimeError
        with open(t) as F:
            for line in F:
                _ = Fout.write(f"T{label}|{line}")
                if line.startswith("Finished Code-"):
                    finished += line[14]
                    time_used += float(line.strip().split()[-1])
                last_time_line = line
        os.unlink(t) # Remove timings so that they're not copied multiple times
        done = last_time_line.startswith("Finished AllFinished")
        o = opj("DATA", "computes", label)
        if ope(o):
            with open(o) as F:
                for line in F:
                    # We double check that all output lines are marked with an appropriate code, in case the computation was interrupted while data was being written to disk (and thus before the Finished Code-x was written).
                    if line and line[0] in finished:
                        if line[0] == "S":
                            sublines.append(line)
                        elif line[0] == "s":
                            # Extract the subgroup index bound for use in computing lattice x-values
                            sheader = read_tmpheader("sub")
                            sdata = line.strip().split("|")[1:]
                            subgroup_index_bound = dict(zip(sheader, sdata))["subgroup_index_bound"]
                            if subgroup_index_bound == r"\N":
                                subgroup_index_bound = None
                            else:
                                subgroup_index_bound = int(subgroup_index_bound)
                        _ = Fout.write(line)
            os.unlink(o) # Remove output so it's not copied multiple times
        e = opj("DATA", "errors", label)
        loc = None
        known = None
        if ope(e):
            with open(e) as F:
                for line in F:
                    _ = Fout.write(f"E{label}|{line}")
                    m = err_location_re.search(line)
                    if m:
                        loc = m.group(0)
                    elif internal_re.search(line):
                        known = "internal"
                    elif schur_re.search(line):
                        known = "schur"
                    elif basim_re.search(line):
                        known = "basim"
                if loc is None:
                    loc = known
            os.unlink(e) # Remove errors so that they're not copied multiple times
    return done, finished, time_used, last_time_line, loc, sublines, subgroup_index_bound

standard_label_re = re.compile(r"(\d+\.[a-z]+\d+)(\.[a-z]+\d+)?")
normal_label_re = re.compile(r"(\d+\.[a-z]+\d+)(\.[a-z]+\d+)?\.N")
def standard_label(label):
    return standard_label_re.fullmatch(label)
def aut_label(label, normal):
    m = standard_label(label)
    if m:
        return m.group(1)
    if normal:
        m = normal_label_re.fullmatch(label)
        if m:
            return m.group(1)
def aut_graph(sdata, normal=False):
    final = defaultdict(set)
    for sdatum in sdata:
        alabel = aut_label(sdatum["short_label"], normal)
        if alabel:
            if normal:
                contains = sdatum["normal_contains"]
            else:
                contains = sdatum["contains"]
            # This will handle the case that contains="{}" ok, since aut_label will return None for [""]
            contains = [aut_label(lab, normal) for lab in contains[1:-1].split(",")]
            final[alabel].update([lab for lab in contains if lab is not None])
    # Make sure that every "contains" node is in final
    for alabel, contains in list(final.items()):
        final[alabel] = set(lab for lab in contains if lab in final)
    adata = []
    seen = set()
    for sdatum in sdata:
        alabel = aut_label(sdatum["short_label"], normal)
        if alabel is None or alabel in seen: continue
        adata.append({"label": alabel,
                      sdatum["subgroup_tex"],
                      "order": int(sdatum["subgroup_order"]),
                      "contains": final[alabel]})
    return adata

def get_graph(sdata, normal=False):
    final = {}
    for sdatum in sdata:
        if normal:
            contains = sdatum["normal_contains"]
        else:
            contains = sdatum["contains"]
        if len(contains) > 2: # {}
            final[sdatum["short_label"]] = contains[1:-1].split(",")
        else:
            final[sdatum["short_label"]] = []
    # Make sure that every "contains" node is in final
    for label, contains in list(final.items()):
        final[label] = set(lab for lab in contains if lab in final)
    return [{"label": sdatum["short_label"],
             "tex": sdatum["subgroup_tex"],
             "order": int(sdatum["subgroup_order"]),
             "contains": final[sdatum["short_label"]]} for sdatum in sdata]

def layout_graph(label, graph, rank_by_order=True):
    nodes = []
    edges = []
    ranks = defaultdict(list)
    for rec in graph:
        lab, tex, contains = rec["label"], rec["tex"], ",".join(rec["contains"])
        nodes.append(f'"{lab}" [label="{tex}",shape=plaintext]')
        if contains:
            edges.append(f'"{lab}" -> {{"{contains}"}} [dir=none]')
        ranks[rec["order"]].append(lab)
    if rank_by_order:
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
        _ = F.write(graph)
    t = time.time()
    subprocess.run(["dot", "-Tplain", "-o", outfile, infile], check=True)
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
    if rank_by_order:
        # We have to remove the phantom nodes used to set the ranks
        margin = min(minx, 10000-maxx)
        minx -= margin
        maxx += margin
        rescale = 10000 / (maxx - minx)
        for short_label, x in list(xcoord.items()):
            xcoord[short_label] = int(round((x - minx) * rescale))
    os.remove(infile)
    os.remove(outfile)
    return xcoord

def compute_diagramx(label, sublines, subgroup_index_bound):
    cols = read_tmpheader("subagg1")
    with open("output", "a") as F:
        subs = []
        norms = []
        for line in sublines:
            vals = line.strip().split("|")
            if vals[0] != "S" + label:
                _ = F.write(f"E{label}|Compute diagramx-label mismatch {vals[0]}")
                continue
            vals = vals[1:]
            if len(vals) != len(cols):
                _ = F.write(f"E{label}|Compute diagramx-length mismatch {len(vals)} vs {len(cols)}")
                continue
            lookup = dict(zip(cols, vals))
            # Omit subgroups that have unusual labels (they're past the index bound)
            if standard_label(lookup["short_label"]):
                if subgroup_index_bound in [None, 0] or lookup["quotient_order"] != r"\N" and int(lookup["quotient_order"]) <= subgroup_index_bound:
                    subs.append(lookup)
                if lookup["normal"] == "t":
                    norms.append(lookup)
            elif lookup["short_label"].endswith(".N"): # except that we want the normal ones
                norms.append(lookup)
            #sdatum[2] = int(sdatum[2]) # subgroup_order
            #sdatum[3] = sdatum[3][1:-1].split(",") # contains
            #sdatum[4] = (sdatum[4] == 't') # normal
            #sdatum[5] = (sdatum[5] == 't') # outer_equivalence
    out_equiv = (subs[0]["outer_equivalence"] == "t")
    if out_equiv:
        graphs = [get_graph(subs), get_graph(norms)]
    else:
        graphs = [aut_graph(subs), aut_graph(norms, normal=True), get_graph(subs), get_graph(norms, normal=True)]
    xcoords = ([layout_graph(label, graph, rank_by_order=True) for graph in graphs] +
               [layout_graph(label, graph, rank_by_order=False) for graph in graphs])
    with open("output", "a") as F:
        for slabel in sublines:
            diagramx = "{" + ",".join([str(D.get(slabel, -1)) for D in xcoords]) + "}"
            _ = F.write(f"D{label}|{label}|{slabel}|{diagramx}\n")

with open("DATA/manifest") as F:
    for line in F:
        todo, out, timings, script, cnt, per_job, timeout = line.strip().split()
        # TODO: update how timeouts are computed
        cnt, per_job, timeout = int(cnt), int(per_job), int(timeout)
        if job < cnt:
            if os.path.isdir(todo):
                L = os.listdir(todo)
                L.sort()
            else:
                with open(todo) as Fsub:
                    L = Fsub.read().strip().split("\n")
            label = L[job]
            #L = L[per_job * job: per_job * (job + 1)]
            os.makedirs(out, exist_ok=True)
            os.makedirs(timings, exist_ok=True)
            os.makedirs(opj("DATA", "errors"), exist_ok=True)
            # We want dependencies as close as possible to each other, so that failures in between don't mean we need to recompute
            dependencies = {
                "a": "JsSLhguo", # depend on MagmaAutGroup (might be possible to change subgroup labeling to function without automorphism group, but it would require a lot of work)
                "j": "JzcCrqQsSLhu", # depend on MagmaConjugacyClasses
                "J": "zCrQsSLh", # depend on ConjugacyClasses
                "z": "sSLh", # depend on conj_centralizer_gens
                "c": "CrqQh", # depend on MagmaCharacterTable
                "C": "rQh", # depend on Characters
                "r": "h", # depend on charc_center_gens/charc_kernel_gens
                "q": "cCrQh", # depend on MagmaRationalCharacterTable (TODO: back dependence bad)
                "Q": "Crh", # depend on Characters (TODO: back dependence bad)
                "s": "SLh", # depend on BestSubgroupLat
                "S": "sLh", # depend on Subgroups (TODO: back dependence bad)
            }
            # You can call tmpheaders(summarize=True) from cloud_collect.py to get a summary of the codes
            codes = "blajJzcCrqQsSLhtguomw" # Note that D = subagg3 (diagramx) is skipped since it's filled in below
            skipped = ""
            subgroup_index_bound = None
            while codes:
                done, finished, time_used, last_time_line, err, sublines, subgroup_index_bound = run(label, codes, timeout, subgroup_index_bound)
                if sublines:
                    compute_diagramx(label, sublines, subgroup_index_bound) # writes directly to output
                if done: break
                for code in finished:
                    codes = codes.replace(code, "")
                # In most cases, we'll just skip the code that caused a timeout, but there are some exceptions
                # If there was no error, and the total time used by prior codes was more than 75% of the allocated time we just retry
                # For some timeouts/errors, we can adjust the preload parameters in the hope of succeeding:
                #1 If stuck computing all subgroups, try computing them one order at a time
                #2 If stuck computing a particular order, stop before that order
                #3 When complement failing on a PC group (or more generally?), try switching to permutation representation
                #4 Backup labeling strategy (conjugacy classes, subgroups)
                if not err:
                    if last_time_line == "Starting SubGrpLst":
                        set_preload("AllSubgroupsOk", "f")
                    elif (last_time_line.startswith("Starting SubGrpLstSplitDivisor ") or
                          last_time_line.startswith("Starting SubGrpLstDivisor ")):
                        set_preload("SubGrpLstByDivisorTerminate", last_time_line.split("(")[1].split(")")[0])
                    #elif last_time_line == "Starting ComputeLatticeEdges":
                    #    # Screws up labeling....
                    #    set_preload("subgroup_inclusions_known", "f")
                    #elif last_time_line == "ComputeComplements":
                    #    # Try to find a permutation rep to run on
                    elif time_used <= 0.75 * timeout:
                        for code in codes[0] + dependencies.get(codes[0], ""):
                            skipped += code
                            codes = codes.replace(code, "")
                else:
                    # Ideally, we'd have some known errors that are possible to work around here
                    for code in codes[0] + dependencies.get(codes[0], ""):
                        skipped += code
                        codes = codes.replace(code, "")
            if skipped:
                with open("output", "a") as Fout:
                    _ = Fout.write(f"T{label}|Skip-{skipped}\n")
            break
        else:
            job -= cnt
