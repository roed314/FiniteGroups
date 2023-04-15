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
    use_compute = all(line.split()[3] == "ComputeCodes.m" for line in mlines)
    use_id = all(line.split()[3] == "IdentifyBigGroup.m" for line in mlines)
if ope(opj("DATA", "ncores")):
    with open(opj("DATA", "ncores")) as F:
        ncores = F.read().strip()
else:
    # better to use cpu_count from psutil, but that has to be pip installed
    ncores = multiprocessing.cpu_count()
if use_compute:
    subprocess.call("seq %s | parallel -j%s ./cloud_compute.py {1}" % (total, ncores), shell=True)
elif use_id:
    timeout = mlines[0].split()[7]
    memlimit = 3840 # in MB = 3.75GB
    subprocess.call("seq %s | parallel -j%s 'prlimit --as=%s --cpu=%s magma -b N:={1} IdentifyBigGroup.m'" % (total, ncores, memlimit*1048576, timeout), shell=True)
else:
    with open("output", "w") as F:
        _ = F.write("Invalid manifest %s" % (mlines,))

with open("finished", "w") as F:
    _ = F.write("t\n")
