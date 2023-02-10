#!/usr/bin/env python

"""
Identifies groups of medium order (512, 1152, 1536, 1920, 2187, 6561, 15625, 16807, 78125, 161051)
by connecting to devmirror.lmfdb.xyz and using the stored hashes there.

Usage:

Either provide an input file with hashes to identify, one per line, each of the form N.i
./identify.py -i INPUT_FILE.txt -o OUTPUT_FILE.txt

or provide the input 

or provide the input at the command line, separated by newlines
./identify.py < echo "512.1"

Output is written to the designated output file, or sent to stdout (if no output file given)
"""

import os
import sys
import argparse
from collections import defaultdict
from psycopg2 import connect
from psycopg2.sql import SQL, Identifier

## We avoid using the LMFDB to eliminate the dependency on Sage
#opj, ops, ope = os.path.join, os.path.split, os.path.exists
#root = os.getcwd()
## This repo contains an LMFDB folder, and some OSes (like OS X) are not case sensitive
#while not (ope(opj(root, "lmfdb")) and ope(opj(root, "lmfdb", "start-lmfdb.py"))):
#    newroot = ops(root)[0]
#    if root == newroot:
#        raise ModuleNotFoundError("No path to the LMFDB in the current directory")
#    root = newroot
#sys.path.append(opj(root, "lmfdb"))
# Importing db from the LMFDB prints a bunch of garbage, so we disable printing for a bit
#savedstdout = sys.stdout
#savedstderr = sys.stderr
#with open(os.devnull, 'w') as F:
#    try:
#        sys.stdout = F
#        sys.stderr = F
#        from lmfdb import db
#    finally:
#        sys.stdout = savedstdout
#        sys.stderr = savedstderr

SMALLHASHED = [512, 1152, 1536, 1920, 2187, 6561, 15625, 16807, 78125, 161051]

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
hashlookup = defaultdict(list)

## Reduce number of database calls by grouping by order
byord = defaultdict(set)
for N, hsh in hashes:
    if N in SMALLHASHED:
        byord[N].add(hsh)
for N in list(byord):
    byord[N] = sorted(byord[N])
#if len(byord) > 1:
#    query = {"$or": [{"order": N, "hash": ({"$in": L} if len(L) > 1 else L[0])} for (N, L) in byord.items()]}
#else:
#    N = list(byord)[0]
#    L = byord[N]
#    query = {"order": N, "hash": ({"$in": L} if len(L) > 1 else L[0])}
#for rec in db.gps_smallhash.search(query, silent=True):
#    hashlookup[rec["order"], rec["hash"]].append(f'{rec["order"]}.{rec["counter"]}')

# We set up the connection manually using psycopg2 to remove dependencies on the LMFDB and Sage for code running on google cloud
conn = connect(dbname="lmfdb", user="lmfdb", password="lmfdb", host="devmirror.lmfdb.xyz")
cur = conn.cursor()
it = byord.items()
opt1 = SQL("({0} = %s AND {1} = ANY(%s))").format(Identifier("order"), Identifier("hash"))
opt2 = SQL("({0} = %s AND {1} = %s)").format(Identifier("order"), Identifier("hash"))
query = SQL(" OR ").join(opt1 if len(L) > 1 else opt2 for (N, L) in it)
values = []
for N, L in it:
    if len(L) > 1:
        values.extend([N, L])
    else:
        values.extend([N, L[0]])
query = SQL("SELECT {0}, {1}, {2} FROM gps_smallhash WHERE {3}").format(Identifier("order"), Identifier("hash"), Identifier("counter"), query)
cur.execute(query, values)
for vec in cur:
    hashlookup[vec[0], vec[1]].append(f'{vec[0]}.{vec[2]}')

out = [hashlookup.get(pair, [f"{pair[0]}.0"]) for pair in hashes]

if args.output:
    with open(args.output, "a") as F:
        for opts in out:
            _ = F.write("|".join(opts) + "\n")
else:
    for opts in out:
        print("|".join(opts))
