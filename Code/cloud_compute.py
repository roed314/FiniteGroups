#!/usr/bin/env python3

# This script is used to control the computation of group data so that we can still get some results even when certain computations time out.
# It takes as input an integer between 1 and the number of jobs, selects the appropriate magma script to execute under parallel, then transfers the output to a top-level "output" file.
# Errors, standard out and timing information are included in the output with an "E" or "T" prefix respectively

import os
import re
import argparse
import subprocess
# defhikpruvxyz
opj = os.path.join
ope = os.path.exists
err_location_re = re.compile(r'In file "(.*)", line (\d+), column (\d+):')
schur_re = re.compile("Runtime error in 'pMultiplicator': Cohomology failed")
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

def run(label, codes, timeout):
    subprocess.run('parallel -n0 --timeout %s "magma -b label:=%s codes:=%s ComputeCodes.m >> DATA/errors/%s 2>&1" ::: 1' % (timeout, label, codes, label), shell=True)
    # Move timing and error information to the common output file and extract timeout and error information
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
    return done, finished, time_used, last_time_line, loc

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
            codes = "blajgqcqtsJCQSLm"
            skipped = ""
            while codes:
                done, finished, time_used, last_time_line, err = run(label, codes, timeout)
                if done: break
                for code in finished:
                    codes = codes.replace(code, "")
                # In most cases, we'll just skip the code that caused a timeout, but there are some exceptions
                # If there was no error, and the total time used by prior codes was more than 75% of the allocated time we just retry
                # For some timeouts/errors, we can adjust the preload parameters in the hope of succeeding:
                #1 When complement failing on a PC group (or more generally?), try switching to permutation representation
                #2 Backup labeling strategy (conjugacy classes, subgroups)
                #3 If failing on 
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
                        skipped += codes[0]
                        codes = codes[1:]
                else:
                    # Ideally, we'd have some known errors that are possible to work around here
                    skipped += codes[0]
                    codes = codes[1:]
            if skipped:
                with open("output", "a") as Fout:
                    _ = Fout.write(f"T{label}|Skip-{skipped}")
            break
        else:
            job -= cnt
