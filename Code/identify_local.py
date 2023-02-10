#!/usr/bin/env python3

"""
Identifies groups of medium order (512, 1152, 1536, 1920, 2187, 6561, 15625, 16807, 78125, 161051)
by looking up hashes stored in a local folder.  The local folder can be created from the lmfdb by using the make_identify_folder.py script
"""

import os
import sys
import argparse
from bisect import bisect
from collections import defaultdict, Counter

opj = os.path.join
ope = os.path.exists

SMALLHASHED = {"512": 4,
               "1152": 2,
               "1536": 5,
               "1920": 2,
               "2187": 1,
               "6561": 2,
               "15625": 1,
               "16807": 1,
               "78125": 1,
               "161051": 1}

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--input", help="file containing the hashes to identify, one per line, each of the form N.hsh")
parser.add_argument("-o", "--output", help="file to write the output, lines corresponding to input")
parser.add_argument("hashes", nargs="*", help="input hashes at the command line")
args = parser.parse_args()

if args.hashes:
    hashes = args.hashes
elif args.input:
    with open(args.input) as F:
        hashes = list(F)
else:
    hashes = sys.stdin.read().split("\n")

# The following code will need to be updated once gps_groups has hashes and we support identification of larger groups

# We 0-pad so that we don't need to convert to ints for bisecting
# Hashes are taken modulo 9223372036854775783 < 2^63, so we pad to 19 digits
def pad_pair(hsh):
    if hsh.count(".") != 1:
        # Invalid hash format; print a warning and covert to something that doesn't exist (so will be skipped, but won't screw up the bijection between inputs and outputs)
        print(f"Invalid hash format (must have one period): {hsh}")
        return ("0", "0")
    N, hsh = hsh.strip().split(".")
    if len(hsh) < 19:
        hsh = "0" * (19 - len(hsh))
    return N, hsh
hashes = [pad_pair(hsh) for hsh in hashes if hsh.strip()]

# We cache the data from the file system, but only if it's going to be used again
hashcache = {}
cnts = Counter()
for N, hsh in hashes:
    if N in SMALLHASHED:
        flen = SMALLHASHED[N]
        hshkey = f"{N}.{hsh[:flen]}"
        cnts[hshkey] += 1

hashlookup = defaultdict(list)

for N, hsh in hashes:
    if N in SMALLHASHED:
        flen = SMALLHASHED[N]
        hshkey = f"{N}.{hsh[:flen]}"
        fname = opj("DATA", "smallhash_db", N, hsh[:flen])
        if hshkey in hashcache:
            gps = hashcache[hshkey]
            cnts[hshkey] -= 1
            if cnts[hshkey] == 0:
                del hashcache[hshkey]
        elif ope(fname):
            # Load from the file
            with open(fname) as F:
                gps = list(F)
            cnts[hshkey] -= 1
            if cnts[hshkey] > 0:
                hashcache[hshkey] = gps
        else:
            # No file exists, so we go to the next group
            continue
        gkey = hsh[flen:]
        i = bisect(gps, gkey)
        if i <= len(gps) and gps[i].startswith(gkey):
            # the line is of the form gkey:gapids
            hashlookup[N, hsh] = f"{N}.{gps[i][len(gkey)+1:].strip()}"

out = [hashlookup.get(pair, f"{pair[0]}.0") for pair in hashes]

if args.output:
    with open(args.output, "a") as F:
        _ = F.write("\n".join(out) + "\n")
else:
    print("\n".join(out))
