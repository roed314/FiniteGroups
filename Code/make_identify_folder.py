"""
Call this to create the folder used by identify_local.py
"""

from lmfdb import db
import os
from collections import defaultdict
opj = os.path.join

SMALLHASHED = {512: 4,
               1152: 2,
               1536: 5,
               1920: 2,
               2187: 1,
               6561: 2,
               15625: 1,
               16807: 1,
               78125: 1,
               161051: 1}

def make_identify_folder(folder=None, tmpfile=None):
    if folder is None:
        folder = opj("DATA", "smallhash_db")
    os.makedirs(folder, exist_ok=True)
    if tmpfile is None:
        tmpfile = opj("DATA", "smallhsh_tmp")
    for N in [512, 1152, 1536, 1920, 2187, 6561, 15625, 16807, 78125, 161051]:
        print("Starting order", N)
        flen = SMALLHASHED[N]
        os.makedirs(opj(folder, str(N)), exist_ok=True)
        db.gps_smallhash.copy_to(tmpfile, columns=["counter", "hash"], query={"order": N})
        print("Tmpfile created")
        by_hsh = defaultdict(lambda: defaultdict(list))
        with open(tmpfile) as F:
            for i, line in enumerate(F):
                if i and i%1000000 == 0:
                    print("Loading line", i)
                elif i <= 2: # header
                    continue
                ctr, hsh = line.strip().split("|")
                # We 0-pad so that we don't need to convert to ints for bisecting
                # Hashes are taken modulo 9223372036854775783 < 2^63, so we pad to 19 digits
                if len(hsh) < 19:
                    hsh = (19 - len(hsh)) * "0" + hsh
                elif len(hsh) > 19:
                    raise ValueError(N, line)
                fname = hsh[:flen]
                gkey = hsh[flen:]
                by_hsh[fname][gkey].append(int(ctr))
        for i, fname in enumerate(by_hsh):
            if i and i % 500 == 0:
                print("Writing file", i)
            with open(opj(folder, str(N), fname), "w") as Fout:
                for gkey in sorted(gkey):
                    opts = "|".join(str(ctr) for ctr in sorted(by_hsh[fname][gkey]))
                    _ = Fout.write(f"{gkey}:{opts}\n")
