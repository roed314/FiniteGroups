#!/usr/bin/env sage -python
import os
import sys
import argparse
from collections import defaultdict

opj, ops = os.path.join, os.path.split
root = ops(ops(os.getcwd())[0])[0]
sys.path.append(opj(root, "lmfdb"))
# Importing db from the LMFDB prints a bunch of garbage, so we disable printing for a bit
savedstdout = sys.stdout
savedstderr = sys.stderr
with open(os.devnull, 'w') as F:
    try:
        sys.stdout = F
        sys.stderr = F
        from lmfdb import db
    finally:
        sys.stdout = savedstdout
        sys.stderr = savedstderr

SMALLHASHED = [512, 1152, 1536, 1920]

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

hashes = [tuple(int(c) for c in hsh.split(".")) for hsh in hashes if hsh.strip()]
# Reduce number of database calls by grouping by order
byord = defaultdict(set)
for N, hsh in hashes:
    if N in SMALLHASHED:
        byord[N].add(hsh)
for N in list(byord):
    byord[N] = sorted(byord[N])
if len(byord) > 1:
    query = {"$or": [{"order": N, "hash": ({"$in": L} if len(L) > 1 else L[0])} for (N, L) in byord.items()]}
else:
    N = list(byord)[0]
    L = byord[N]
    query = {"order": N, "hash": ({"$in": L} if len(L) > 1 else L[0])}
hashlookup = defaultdict(list)
for rec in db.gps_smallhash.search(query, silent=True):
    hashlookup[rec["order"], rec["hash"]].append(f'{rec["order"]}.{rec["counter"]}')
out = [hashlookup.get(pair, [f"{pair[0]}.0"]) for pair in hashes]

if args.output:
    with open(args.output, "a") as F:
        for opts in out:
            _ = F.write("|".join(opts) + "\n")
else:
    for opts in out:
        print("|".join(opts))
