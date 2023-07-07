#!/usr/bin/env -S sage -python

# Usage: parallel -j100 ./fix_tex_info.py {1} 100 /scratch/grp/smallid/TexInfo.txt ::: {1..100}

from cloud_collect import parse
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("n", type=int)
parser.add_argument("total", type=int)
parser.add_argument("fname")
args = parser.parse_args()
n, total, fname = args.n, args.total, args.fname

with open(fname) as F:
    with open(f"{fname}.{n}", "w") as Fout:
        for i, line in enumerate(F):
            if i % total == n:
                pieces = line.split("|")
                for j in range(3):
                    label = pieces[2+j]
                    tex = parse(pieces[5+j])
                    if j == 0:
                        size = int(pieces[8])
                    elif j == 1:
                        size = int(pieces[8]) * int(pieces[9])
                    else:
                        size = int(pieces[9])
                    if tex is not None and tex.order not in [None, size]:
                        pieces[5+j] = r"\N"
                    if label != r"\N" and not label.startswith(pieces[8+j] + "."):
                        pieces[2+j] = r"\N"
                _ = Fout.write("|".join(pieces))
