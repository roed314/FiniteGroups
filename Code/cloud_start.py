#!/usr/bin/env python3

# This script is used to control the computation of group data so that we can still get some results even when certain computations time out.
# It takes as input an integer and selects the appropriate magma script to execute under parallel

import os
import argparse
import subprocess

parser = argparse.ArgumentParser("Dispatch to appropriate magma script")
parser.add_argument("job", type=int, help="job number")

args = parser.parse_args()

job = args.job
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
            subprocess.run("parallel --timeout %s magma -b label:={1} %s ::: %s" % (timeout, script, " ".join(L)), shell=True)
            # Move the results to the standard output location
            os.rename(out, os.path.expanduser("~/output"))
            os.rename(timings, os.path.expanduser("~/timings"))
            break
        else:
            job -= cnt
