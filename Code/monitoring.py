# Utility functions for monitoring an ongoing computation
# These functions should be called with the current working directory set to the DATA directory

from sage.misc.cachefunc import cached_function
from sage.all import RR, ZZ
from collection import defaultdict
import os
opj = os.path.join
ope = os.path.exists

@cached_function
def num_groups(n):
    return ZZ(gap.NrSmallGroups(n))

def check_missing():
    started = []
    with open("logs/overall") as F:
        for line in F:
            started.append(line.strip().split()[3])
    Ns = sorted(set(ZZ(label.split(".")[0]) for label in started))
    maxN = max(Ns)
    maxi = max(ZZ(label.split(".")[1]) for label in started if ZZ(label.split(".")[0]) == maxN)
    unfinished = []
    for N in Ns:
        imax = num_groups(N) if N != maxN else maxi
        for i in range(1, imax+1):
            label = "%s.%s" % (N, i)
            if not ope(opj("groups", label)):
                unfinished.append(label)
    return unfinished, Ns

def write_rerun_input(filename, skip=[512,640,768,896,1024,1152,1280,1408,1536,1664,1792,1920], Nlower=None, Nupper=None):
    """
    Writes an input file for running in parallel, and returns the Nlower and Nupper to use in conjunction with it.

    For example:

    sage: write_parallel_input('inputs.txt')
    (576, 2001)

    parallel -j192 -a inputs.txt --timeout 3600 magma Folder:=DATA Nlower:=576 Nupper:=2001 Skip:=[512,640,768,896,1024,1152,1280,1408,1536,1664,1792,1920] Proc:={1} AddSmallGroups.m
    """
    labels, Ns = check_missing()
    if Nlower is None:
        Nlower = min(Ns)
    else:
        assert Nlower <= min(Ns)
    if Nupper is None:
        Nupper = max(Ns) + 1
    else:
        assert Nupper > max(Ns)
    by_N = defaultdict(list)
    for label in labels:
        N, i = label.split(".")
        N, i = ZZ(N), ZZ(i)
        by_N[N].append(i)
    Procs = []
    sofar = 0
    for N in range(Nlower, Nupper):
        if N in skip:
            continue
        for i in by_N[N]:
            Procs.append(str(sofar + i))
        sofar += num_groups(N)
    with open(filename, 'w') as F:
        F.write("\n".join(Procs))
