#!/usr/bin/env python3

# This script is used to control the computation of group data so that we can still get some results even when certain computations time out.
# It takes as input an integer between 1 and the number of jobs, selects the appropriate magma script to execute under parallel, then transfers the output to a top-level "output" file.
# Errors and standard out are redirected to an "errors" file.

import os
import argparse
import subprocess

opj = os.path.join
ope = os.path.exists
parser = argparse.ArgumentParser("Dispatch to appropriate magma script")
parser.add_argument("job", type=int, help="job number")

args = parser.parse_args()

job = args.job - 1 # shift from 1-based to 0-based indexing
with open("DATA/manifest") as F:
    for line in F:
        todo, out, timings, script, cnt, per_job, timeout = line.strip().split()
        cnt, per_job = int(cnt), int(per_job)
        if job < cnt:
            if os.path.isdir(todo):
                L = os.listdir(todo)
                L.sort()
            else:
                with open(todo) as Fsub:
                    L = Fsub.read().strip().split("\n")
            L = L[per_job * job: per_job * (job + 1)]
            os.makedirs(out, exist_ok=True)
            os.makedirs(timings, exist_ok=True)
            os.makedirs(opj("DATA", "errors"), exist_ok=True)
            subprocess.run('parallel --timeout %s "magma -b label:={1} %s >> DATA/errors/{1} 2>&1" ::: %s' % (timeout, script, " ".join(L)), shell=True)
            # Move the results to the standard output location
            with open(os.path.expanduser("output"), "a") as Fout:
                for label in L:
                    o = opj(out, label)
                    if ope(o):
                        with open(o) as F:
                            _ = Fout.write(F.read())
                    e = opj("DATA", "errors", label)
                    if ope(e):
                        with open(e) as F:
                            for line in F:
                                _ = Fout.write(f"E{label}|{line}")
                    t = opj(timings, label)
                    if ope(t):
                        with open(t) as F:
                            for line in F:
                                _ = Fout.write(f"T{label}|{line}")
            break
        else:
            job -= cnt
