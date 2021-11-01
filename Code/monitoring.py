# Utility functions for monitoring an ongoing computation

from sage.misc.cachefunc import cached_function
from sage.all import RR, ZZ
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
    return unfinished
