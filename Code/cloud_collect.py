#!/usr/bin/env python3

# Move the output file to be collected into the DATA directory, named output{n}.txt, where n is the phase.

import os
import argparse
from collections import defaultdict, Counter

opj = os.path.join

#parser = argparse.ArgumentParser("Extract results from cloud computation output file")
#parser.add_argument("phase", type=int, help="phase of computation (1 to 3)")

#args = parser.parse_args()
#datafile = opj("DATA", f"output{args.phase}")

def get_data(datafile):
    codes = {}
    data = {} # We don't use a defaultdict since we want to detect an invalid code
    data["E"] = defaultdict(list)
    data["T"] = defaultdict(list)
    if True: # args.phase > 1:
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
            if False: #args.phase == 1:
                if line.count("|") == 3:
                    # minrep data
                    os.unlink(opj("DATA", "minrep.todo", label))
                    with open(opj("DATA", "minreps", label), "w") as Fout:
                        _ = Fout.write(outdata + "\n")
                elif line.count("|") == 4:
                    # pcrep data
                    os.unlink(opj("DATA", "pcrep.todo", label))
                    with open(opj("DATA", "pcreps", label), "w") as Fout:
                        _ = Fout.write(outdata + "\n")
            else:
                # one-letter code for which output line is appended to the beginning
                code, label = label[0], label[1:]
                if code.isupper():
                    # aggregate data like subgroups, so we leave the label in
                    data[code][label].append(f"{label}|{outdata}")
                else:
                    data[code][label].append(outdata)
                # Need to create preload files, write (or rewrite) data and aggregate files,
                # create todo files for the next phase (for 2->3)
    return data

def get_timing_info(datafile):
    data = get_data(datafile)
    times = data["T"]
    unfinished = Counter()
    finished = {}
    stats = defaultdict(list)
    for label, lines in times.items():
        if lines[-1].startswith("Finished AllFinished in "):
            finished[label] = float(lines[-1].split(" in ")[1].strip())
        else:
            lastline = lines[-1]
            if " in " in lastline:
                lastline = lastline.split(" in ")[0].strip()
            unfinished[lastline] += 1
        for line in lines:
            if " in " in line:
                task = line.split(" in ")[0].replace("Starting", "").strip()
                time = float(line.split(" in ")[1].strip())
                stats[task].append(time)
    maxs = [(-max(ts), task) for (task, ts) in stats.items()]
    maxs.sort()
    avgs = [(-sum(ts)/len(ts), task) for (task, ts) in stats.items()]
    avgs.sort()
    return unfinished, finished, maxs, avgs, stats
