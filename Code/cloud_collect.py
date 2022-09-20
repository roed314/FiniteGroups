#!/usr/bin/env python3

# Move the output file to be collected into the DATA directory, named output{n}.txt, where n is the phase.

import os
import argparse
from collections import defaultdict

opj = os.path.join

parser = argparse.ArgumentParser("Extract results from cloud computation output file")
parser.add_argument("phase", type=int, help="phase of computation (1 to 3)")

args = parser.parse_args()
datafile = opj("DATA", f"output{args.phase}")
codes = {}
data = {}
if args.phase > 1:
    for head in os.listdir():
        if head.endswith(".tmpheader"):
            with open(head) as F:
                code, attrs = F.read().strip().split("\n")
            assert code not in codes
            codes[code] = attrs.split("|")
            data[code] = defaultdict(list)

with open(datafile) as F:
    for line in F:
        line = line.strip()
        if not line: continue
        label, outdata = line.split("|", 1)
        if args.phase == 1:
            if line.count("|") == 3:
                # minrep data
                os.unlink(opj("DATA", "minrep.todo", label))
                with open(opj("DATA", "minreps", label)) as Fout:
                    _ = Fout.write(outdata + "\n")
            elif line.count("|") == 4:
                # pcrep data
                os.unlink(opj("DATA", "pcrep.todo", label))
                with open(opj("DATA", "pcreps", label)) as Fout:
                    _ = Fout.write(outdata + "\n")
        else:
            # one-letter code for which output line is appended to the beginning
            code, label = label[0], label[1:]
            if code.isupper():
                # aggregate data like subgroups, so we leave the label in
                data[code][label].append(line)
            else:
                data[code][label].append(outdata)
            # Need to create preload files, write (or rewrite) data and aggregate files,
            # create todo files for 
            raise NotImplementedError
