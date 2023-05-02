#!/usr/bin/env python3

# This script is used to control the computation of group data so that we can still get some results even when certain computations time out.
# It takes as input an integer between 1 and the number of jobs, selects the appropriate magma script to execute under parallel, then transfers the output to a top-level "output" file.
# Errors, standard out and timing information are included in the output with an "E" or "T" prefix respectively

import os
import re
import sys
import time
import argparse
import subprocess
import traceback
from collections import defaultdict
from datetime import datetime, timezone
from math import ceil
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

def utcnow():
    return datetime.now(timezone.utc).strftime("%H:%M:%S.%f")[:-4]

def run(label, codes, timeout, memlimit, subgroup_index_bound, subgroup_inclusions_known):
    if codes == "X":
        labelname = "m" # label gets in the way of the intrinsic we'd defined
    else:
        labelname = "label"
    if sys.platform == "linux":
        # 1048576B = 1MB
        subprocess.run('prlimit --as=%s --cpu=%s magma -b %s:=%s codes:=%s ComputeCodes.m >> DATA/errors/%s 2>&1' % (memlimit*1048576, ceil(timeout), labelname, label, codes, label), shell=True)
    else:
        # For now, don't enforce a memory limit
        subprocess.run('parallel -n0 --timeout %s "magma -b %s:=%s codes:=%s ComputeCodes.m >> DATA/errors/%s 2>&1" ::: 1' % (ceil(timeout), labelname, label, codes, label), shell=True)
    # Move timing and error information to the common output file and extract timeout and error information
    sublines = []
    with open("output", "a") as Fout:
        t = opj("DATA", "timings", label)
        finished = ""
        time_used = 0
        if ope(t):
            with open(t) as F:
                for line in F:
                    _ = Fout.write(f"T{label}({utcnow()})|{line}")
                    if line.startswith("Finished Code-"):
                        finished += line[14]
                        time_used += float(line.split("(")[0].strip().split()[-1])
                    last_time_line = line
            os.unlink(t) # Remove timings so that they're not copied multiple times
        else:
            last_time_line = ""
        o = opj("DATA", "computes", label)
        if ope(o):
            with open(o) as F:
                delayed = [] # Used for WriteTransitivePermutationRepresentations where we only want to copy lines of the smallest index found
                for line in F:
                    # We double check that all output lines are marked with an appropriate code, in case the computation was interrupted while data was being written to disk (and thus before the Finished Code-x was written).
                    if line and line[0] in finished:
                        if line[0] == "S":
                            sublines.append(line)
                        elif line[0] == "s":
                            # Extract the subgroup_index_bound and subgroup_inclusions_known for use in computing lattice x-values
                            sheader = read_tmpheader("sub")
                            sdata = line[1:].strip().split("|")
                            DD = dict(zip(sheader, sdata))
                            subgroup_index_bound = DD["subgroup_index_bound"]
                            subgroup_inclusions_known = (DD["subgroup_inclusions_known"] == 't')
                            if subgroup_index_bound == r"\N":
                                subgroup_index_bound = None
                            else:
                                subgroup_index_bound = int(subgroup_index_bound)
                        _ = Fout.write(line)
                    elif line[0] == "x":
                        delayed.append(line)
                if delayed:
                    min_index = min(int(line.split("|")[1]) for line in delayed)
                    _ = Fout.write("".join(line for line in delayed if int(line.split("|")[1]) == min_index))
            os.unlink(o) # Remove output so it's not copied multiple times
        e = opj("DATA", "errors", label)
        loc = None
        known = None
        if ope(e):
            with open(e) as F:
                for line in F:
                    _ = Fout.write(f"E{label}({utcnow()})|{line}")
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
    return finished, time_used, last_time_line, loc, sublines, subgroup_index_bound, subgroup_inclusions_known

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
        alabel = sdatum["aut_label"]
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
                      "tex": sdatum["subgroup_tex"],
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

def layout_graph(label, graph, timeout, memlimit, rank_by_order=True):
    nodes = []
    edges = []
    ranks = defaultdict(list)
    for rec in graph:
        lab, tex, contains = rec["label"], rec["tex"], '","'.join(rec["contains"])
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
    if edges:
        edges += ";" # deal with no edges by moving semicolon here.
    ranks = ";\n".join('{rank=same; "%s"}' % ('" "'.join(labs)) for labs in ranks.values())
    graph = f"""strict digraph "{label}" {{
rankdir=TB;
splines=line;
{edges}
{nodes};
{ranks};
}}
"""
    infile = f"/tmp/graph{label}.in"
    outfile = f"/tmp/graph{label}.out"
    with open(infile, "w") as F:
        _ = F.write(graph)
    t = time.time()
    if sys.platform == "linux":
        # 1048576B = 1MB
        subprocess.run("prlimit --as=%s --cpu=%s dot -Tplain -o %s %s" % (memlimit*1048576, ceil(timeout), outfile, infile), shell=True, check=True)
    else:
        # For now, don't enforce a memory limit when not on linux
        subprocess.run('parallel -n0 --timeout %s "dot -Tplain -o %s %s" ::: 1' % (ceil(timeout), outfile, infile), shell=True, check=True)
    xcoord = {}
    # When there are long output lines, dot uses a backslash at the end of the line to indicate a line continuation.
    # I can't find any analogue of Magma's SetColumns(0), so it looks like we have to deal.  Ugh.
    with open(outfile) as F:
        maxx = 0
        minx = 10000
        lines = []
        continuing = False
        for line in F:
            line = line.strip()
            if continuing:
                lines[-1] += line
            else:
                lines.append(line)
            continuing = line[-1] == "\\"
            if continuing:
                lines[-1] = lines[-1][:-1]
        for line in lines:
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

def compute_diagramx(label, sublines, subgroup_index_bound, end_time, memlimit):
    start_time = time.time()
    cols = read_tmpheader("subagg1")
    with open("output", "a") as F:
        _ = F.write(f"T{label}({utcnow()})|Starting Code-D\n")
        subs = []
        norms = []
        accessors = []
        out_equiv = None
        for line in sublines:
            vals = line.strip().split("|")
            if vals[0] != "S" + label:
                _ = F.write(f"E{label}({utcnow()})|Compute diagramx-label mismatch {vals[0]}\n")
                continue
            vals[0] = vals[0][1:]
            if len(vals) != len(cols):
                _ = F.write(f"E{label}({utcnow()})|Compute diagramx-length mismatch {len(vals)} vs {len(cols)}\n")
                continue
            lookup = dict(zip(cols, vals))
            # Omit subgroups that have unusual labels (they're past the index bound)
            if out_equiv is None:
                out_equiv = lookup["outer_equivalence"] == "t"
            added = False
            if standard_label(lookup["short_label"]):
                if subgroup_index_bound in [None, 0] or lookup["quotient_order"] != r"\N" and int(lookup["quotient_order"]) <= subgroup_index_bound:
                    subs.append(lookup)
                    added = True
                if lookup["normal"] == "t":
                    norms.append(lookup)
                    added = True
            elif lookup["short_label"].endswith(".N"): # except that we want the normal ones
                norms.append(lookup)
                added = True
            if added:
                if out_equiv:
                    accessors.append([lookup["short_label"]] * 4)
                else:
                    accessors.append(([lookup["aut_label"]] * 2 + [lookup["short_label"]] * 2) * 2)
    if out_equiv:
        graphs = [get_graph(subs), get_graph(norms, normal=True)]
    else:
        graphs = [aut_graph(subs), aut_graph(norms, normal=True), get_graph(subs), get_graph(norms, normal=True)]
    xcoords = []
    try:
        for graph in graphs:
            timeout = end_time - time.time()
            if timeout < 0:
                raise subprocess.CalledProcessError(1, "dot")
            xcoords.append(layout_graph(label, graph, timeout, memlimit, rank_by_order=True))
        for graph in graphs:
            timeout = end_time - time.time()
            if timeout < 0:
                raise subprocess.CalledProcessError(1, "dot")
            xcoords.append(layout_graph(label, graph, timeout, memlimit, rank_by_order=False))
    except subprocess.CalledProcessError:
        with open("output", "a") as Fout:
            _ = Fout.write(f"E{label}({utcnow()})|Killed diagramx\n")
        return "D"
    except Exception:
        with open("output", "a") as Fout:
            errstr = traceback.format_exc().strip().replace("\n", f"\nE{label}|diagramx: ")
            _ = Fout.write(f"E{label}({utcnow()})|diagramx: {errstr}\n")
        return "D"
    else:
        with open("output", "a") as F:
            for accessor in accessors:
                slabel = accessor[-1]
                diagramx = "{" + ",".join([str(D.get(key, -1)) for (D, key) in zip(xcoords, accessor)]) + "}"
                _ = F.write(f"D{label}|{slabel}|{diagramx}\n")
            _ = F.write(f"T{label}({utcnow()})|Finished Code-D in {time.time() - start_time:.3f}\n")
        return ""


# We want dependencies as close as possible to each other, so that failures in between don't mean we need to recompute
dependencies = {
    "a": "JsSDLWhguoIi", # depend on MagmaAutGroup (might be possible to change subgroup labeling to function without automorphism group, but it would require a lot of work)
    "j": "JzcCrqQsSDLWhuIi", # depend on MagmaConjugacyClasses
    "J": "zCrQsSDLWhIi", # depend on ConjugacyClasses
    "z": "sSDLWhIi", # depend on conj_centralizer_gens
    "c": "CrqQvh", # depend on MagmaCharacterTable
    "C": "rQh", # depend on Characters
    "r": "h", # depend on charc_center_gens/charc_kernel_gens
    "q": "cCrQh", # depend on MagmaRationalCharacterTable (TODO: back dependence bad)
    "Q": "Crh", # depend on Characters (TODO: back dependence bad)
    "s": "SDLWvhIin", # depend on BestSubgroupLat
    "S": "sDLWhIin", # depend on Subgroups (TODO: back dependence bad)
    "I": "i", # depend on Mobius
}
# You can call tmpheaders(summarize=True) from cloud_collect.py to get a summary of the codes
codes = "blajJzcCrqQsvSLWhtguoIimw" # Note that D = subagg3 (diagramx) is skipped since it's filled in below
# By default we skip XxYy (used in labeling subgroups that were postponed until later) and n (which is used only to save some information about which normal subgroups were saved
def skip_codes(codes, skipped):
    if codes[0] in dependencies:
        skipped += f"{codes[0]}({dependencies[codes[0]]})"
    else:
        skipped += codes[0]
    for c in skipped:
        codes = codes.replace(c, "")
    return codes, skipped

def load_sublines(label):
    # This function is used for computing subgroup diagram layouts when a previous run died during that step.
    with open(opj("DATA", "sublines", label)) as F:
        sublines = list(F)
    subgroup_index_bound, sublines = sublines[0], sublines[1:]
    if subgroup_index_bound == r"\N":
        subgroup_index_bound = None
    else:
        subgroup_index_bound = int(subgroup_index_bound)
    return sublines, subgroup_index_bound

with open("DATA/manifest") as F:
    for line in F:
        todo, out, timings, script, cnt, per_job, job_timeout, total_timeout = line.strip().split()
        # Hard code memlimit for now
        memlimit = 7936 # in MB = 7.75GB
        #memlimit = 3840 # in MB = 3.75GB
        # TODO: update how timeouts are computed
        cnt, per_job, job_timeout, total_timeout = int(cnt), int(per_job), int(job_timeout), int(total_timeout)
        if job < cnt:
            if os.path.isdir(todo):
                L = os.listdir(todo)
                L.sort()
            else:
                with open(todo) as Fsub:
                    L = Fsub.read().strip().split("\n")
            label = L[job]
            # We allow for encoding the codes to do in the todo file
            if " " in label:
                label, codes = label.split()
            #L = L[per_job * job: per_job * (job + 1)]
            os.makedirs(out, exist_ok=True)
            os.makedirs(timings, exist_ok=True)
            os.makedirs(opj("DATA", "errors"), exist_ok=True)
            skipped = ""
            subgroup_index_bound = None
            subgroup_inclusions_known = None
            start_time = time.time()
            if codes == "D":
                # A previous computation was interrupted while trying to compute the subgroup lattice layout
                # We need to retrieve the stored subgroups, and subgroup_index_bound
                sublines, subgroup_index_bound = load_sublines(label)
                end_time = start_time + total_timeout
                skipped = compute_diagramx(label, sublines, subgroup_index_bound, end_time, memlimit) # writes directly to output, handles timeouts
                codes = "" # Don't execute the while loop
            while codes:
                timeout = min(job_timeout, total_timeout - (time.time() - start_time))
                #print("Loop with timeout %s" % timeout)
                finished, time_used, last_time_line, err, sublines, subgroup_index_bound, subgroup_inclusions_known = run(label, codes, timeout, memlimit, subgroup_index_bound, subgroup_inclusions_known)
                if sublines and subgroup_inclusions_known:
                    end_time = start_time + total_timeout # Don't allow the layout processes to go past the total time allowed
                    skipped += compute_diagramx(label, sublines, subgroup_index_bound, end_time, memlimit) # writes directly to output
                for code in finished:
                    codes = codes.replace(code, "")
                if not codes:
                    # Everything finished!
                    break
                # In most cases, we'll just skip the code that caused a timeout, but there are some exceptions
                # If there was no error, and the total time used by prior codes was more than 75% of the allocated time we just retry
                # For some timeouts/errors, we can adjust the preload parameters in the hope of succeeding:
                #1 If stuck computing all subgroups, try computing them one order at a time
                #2 If stuck computing a particular order, stop before that order
                #3 When complement failing on a PC group (or more generally?), try switching to permutation representation
                #4 Backup labeling strategy (conjugacy classes, subgroups)
                if time.time() - start_time > total_timeout:
                    with open("output", "a") as Fout:
                        _ = Fout.write(f"T{label}({utcnow()})|HitTotalTimeout({time.time() - start_time})\n")
                    skipped += f"[{codes}]"
                    codes = ""
                    break
                elif not err:
                    if last_time_line == "Starting SubGrpLst":
                        set_preload(label, "AllSubgroupsOk", "f")
                    #elif (last_time_line.startswith("Starting SubGrpLstSplitDivisor ") or
                    #      last_time_line.startswith("Starting SubGrpLstDivisor ")):
                    #    set_preload(label, "SubGrpLstByDivisorTerminate", last_time_line.split("(")[1].split(")")[0])
                    #elif last_time_line == "Starting ComputeLatticeEdges":
                    #    # Screws up labeling....
                    #    set_preload("subgroup_inclusions_known", "f")
                    #elif last_time_line == "ComputeComplements":
                    #    # Try to find a permutation rep to run on
                    elif time_used <= 0.5 * timeout:
                        codes, skipped = skip_codes(codes, skipped)
                else:
                    # Ideally, we'd have some known errors that are possible to work around here
                    codes, skipped = skip_codes(codes, skipped)
            if skipped:
                with open("output", "a") as Fout:
                    _ = Fout.write(f"T{label}({utcnow()})|Skip-{skipped}\n")
            else:
                with open("output", "a") as Fout:
                    _ = Fout.write(f"T{label}({utcnow()})|NoSkip\n")
            break
        else:
            job -= cnt
    else:
        # job number was larger than the number of lines; write an empty file so that google cloud doesn't try to restart.
        with open("output", "a") as Fout:
            _ = Fout.write("")
