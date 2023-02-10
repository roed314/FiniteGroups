#!/usr/bin/env python3

# This script sets up the files used in the computation of group data on google cloud.
# For the most part, it just adds a selected set of files to a tarball,
# but it also records the number of groups in each todo folder.

import os
import argparse
import subprocess

parser = argparse.ArgumentParser("Create tarball for cloud computation")
parser.add_argument("phase", type=int, help="phase of computation (1 to 3)")

args = parser.parse_args()

if args.phase == 1:
    todos = [
        ("MinReps4", "minrep", 1, 9*3600),
        #("PCreps_fast", "pcrep_fast", 1, 3600),
        ("PCreps", "pcrep", 1, 4*3600),
    ]
else:
    todos = [
        ("ComputeCodes.m", "compute", 1, 7200), # Production run
    ]

total = 0
manifest = []
include = [
    "spec",
    "*.m",
    "*.py",
    "*.header",
    "*.tmpheader",
    "Polredabs/*",
    "DATA/manifest",
]
if args.phase > 1:
    include.extend([
        "DATA/preload", # saved attributes from previous runs
        "DATA/descriptions",
        "DATA/hash_lookup",
        "DATA/smallhash_db",
        #"DATA/fromhash",
    ])
for mag, todo, per_job, timeout in todos:
    D = f"DATA/{todo}.todo"
    Dout = f"DATA/{todo}s"
    Dtiming = f"DATA/timings"
    include.append(D)
    if os.path.isdir(D):
        n = (len(os.listdir(D)) - 1) // per_job + 1
    else:
        n = 0
        with open(D) as FD:
            for jb in FD:
                n += 1
    total += n
    manifest.append(f"{D} {Dout} {Dtiming} {mag} {n} {per_job} {timeout}")
with open("DATA/manifest", "w") as F:
    _ = F.write("\n".join(manifest))

subprocess.run(f"tar -cf DATA/phase{args.phase}_{total}.tar " + " ".join(include), shell=True)

print(f"DATA/phase{args.phase}_{total}.tar created")
print(f"{total} jobs to run")
