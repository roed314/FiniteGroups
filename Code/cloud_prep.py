#!/usr/bin/env python3

# This script sets up the files used in the computation of group data on google cloud.
# For the most part, it just adds a selected set of files to a tarball,
# but it also records the number of groups in each todo folder.

import os
import argparse
import subprocess

parser = argparse.ArgumentParser("Create tarball for cloud computation")
parser.add_argument("phase", type=int, help="phase of computation (1 or 2)")

args = parser.parse_args()

if args.phase == 1:
    todos = [
        ("MinReps4", "minrep", 2, 3600),
        ("PCreps_fast", "pcrep_fast", 2, 3600),
        ("PCreps", "pcrep", 2, 3600),
    ]
elif args.phase == 2:
    todos = [
        ("ComputeAll", "compute", 2, 1800),
    ]
elif args.phase == 3:
    todos = [
        ("ComputeBasic", "basic", 2, 43200),
        ("ComputeLabeling", "labeling", 2, 3600),
        ("ComputeAut", "aut", 2, 3600),
        ("ComputeConj", "conj", 2, 7200),
        ("ComputeSchur", "schur", 2, 1800),
        ("ComputeWreath", "wreath", 2, 1800),
        ("ComputeCharC", "charc", 2, 7200),
        ("ComputeCharQ", "charq", 2, 7200),
        ("ComputeSubs", "subgroups", 2, 7200),
        ("ComputeName", "name", 2, 7200),
    ]

total = 0
manifest = []
include = [
    "spec",
    "*.m",
    "*.py",
    "*.header",
    "*.tmpheader",
    "DATA/manifest",
]
if args.phase > 1:
    include.extend([
        "DATA/preload", # saved attributes from previous runs
        "DATA/descriptions",
        "DATA/fromhash",
        "DATA/tohash",
    ])
for mag, todo, per_job, timeout in todos:
    D = f"DATA/{todo}.todo"
    Dout = f"DATA/{todo}s"
    Dtiming = f"DATA/{todo}.timings"
    include.append(D)
    n = (len(os.listdir(D)) - 1) // per_job + 1
    total += n
    manifest.append(f"{D} {Dout} {Dtiming} {mag}.m {n} {per_job} {timeout}")
with open("DATA/manifest", "w") as F:
    _ = F.write("\n".join(manifest))

subprocess.run(f"tar -cf DATA/phase{args.phase}_{total}.tar " + " ".join(include), shell=True)

print(f"DATA/phase{args.phase}_{total}.tar created")
print(f"{total} jobs to run")
