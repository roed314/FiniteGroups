#!/usr/bin/env python3

# This script is used to call cloud_compute.py on many inputs by reading the contents of DATA/manifest.  It is designed for the context where many jobs are run on a single server.  To specify the number of cores to use, use DATA/ncores

import os
import subprocess
import multiprocessing
opj = os.path.join
ope = os.path.exists

try:
    os.remove("finished")
except FileNotFoundError:
    pass
with open(opj("DATA", "manifest")) as F:
    mlines = F.read().strip().split("\n")
    total = sum([int(line.split()[4]) for line in mlines])
if ope(opj("DATA", "ncores")):
    with open(opj("DATA", "ncores")) as F:
        ncores = F.read().strip()
else:
    # better to use cpu_count from psutil, but that has to be pip installed
    ncores = multiprocessing.cpu_count()
subprocess.call("seq %s | parallel -j%s --memfree 16G ./cloud_compute.py {1}" % (total, ncores), shell=True)

with open("finished", "w") as F:
    _ = F.write("t\n")
