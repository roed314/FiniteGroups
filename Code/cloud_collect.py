#!/usr/bin/env python3

# Move the output file to be collected into the DATA directory, named output{n}.txt, where n is the phase.

import os, re, string
import argparse
from collections import defaultdict, Counter

opj = os.path.join
ope = os.path.exists

def class_to_int(k):
    if k.isdigit():
        return int(k)
    elif k.isalpha() and k.islower():
        kk = [string.ascii_lowercase.index(ch) for ch in k]
    elif k.isalpha() and k.isupper():
        kk = [string.ascii_uppercase.index(ch) for ch in k]
    else:
        raise ValueError("Invalid class", k)
    kk.reverse()
    return sum(kk[i] * 26 ** i for i in range(len(kk)))

#parser = argparse.ArgumentParser("Extract results from cloud computation output file")
#parser.add_argument("phase", type=int, help="phase of computation (1 to 3)")

#args = parser.parse_args()
#datafile = opj("DATA", f"output{args.phase}")

def get_data(datafile="output"):
    data = {} # We don't use a defaultdict since we want to detect an invalid code
    data["E"] = defaultdict(list)
    data["T"] = defaultdict(list)
    if True: # args.phase > 1:
        codes = tmpheaders()
        for code in codes:
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
            elif line:
                # one-letter code for which output line is appended to the beginning
                code, label = label[0], label[1:]
                data[code][label].append(line[1:])
                # Need to create preload files, write (or rewrite) data and aggregate files,
                # create todo files for the next phase (for 2->3)
    return data

def split_output_file(infile="output", finishfile="finished.txt", skipfile="skipped.txt", errorfile="errors.txt", timingfile="timings.txt", oldcompute="DATA/compute.todo", newcompute="newcompute.todo", overwrite=False, splitsSiI=False):
    # We changed several tmpheaders so that mobius_sub doesn't halt the computation; splitsSiI adapts old output to the new tmpheaders
    if not overwrite and any(ope(fname) for fname in [finishfile, skipfile, errorfile, timingfile, newcompute]):
        raise ValueError("At least one output file exists; use overwrite or change name")
    skip = set()
    noskip = set()
    buff = defaultdict(list)
    errors = {}
    malformed = []
    def adaptsSiI(line):
        if line[0] == "s":
            pieces = line.strip().split("|")
            sline = "|".join(pieces[i] for i in range(len(pieces)) if i not in [3,8])
            iline = "|".join(pieces[i] for i in [0,3,8])
            return f"{sline}\n{iline}\n"
        elif line[0] == "S":
            pieces = line.strip().split("|")
            Sline = "|".join(pieces[:29] + pieces[31:])
            Iline = "|".join([pieces[i] for i in [0,24,29,30]])
            return f"{Sline}\n{Iline}\n"
        else:
            return line
    with open(infile) as F:
        with open(finishfile, "w") as Fns:
            with open(skipfile, "w") as Fs:
                with open(errorfile, "w") as FE:
                    with open(timingfile, "w") as FT:
                        for i, line in enumerate(F):
                            if i and i%10000000 == 0: print(i)
                            if "|" not in line[1:]:
                                malformed.append(line)
                                continue
                            label, outdata = line.split("|", 1)
                            code, label = label[0], label[1:]
                            if code == "E":
                                _ = FE.write(line)
                                if "error" in outdata and outdata not in errors:
                                    errors[outdata] = label
                            elif code == "T":
                                _ = FT.write(line)
                                if "NoSkip" in outdata:
                                    noskip.add(label)
                                    FB = Fns
                                elif "Skip" in outdata:
                                    skip.add(label)
                                    FB = Fs
                                else:
                                    continue
                                for bline in buff[label]:
                                    _ = FB.write(adaptsSiI(bline))
                                del buff[label]
                            elif label in noskip:
                                _ = Fns.write(adaptsSiI(line))
                            elif label in skip:
                                _ = Fs.write(adaptsSiI(line))
                            else:
                                buff[label].append(line)
    with open(oldcompute) as F:
        oldC = F.read().strip().split("\n")
    newC = [label for label in oldC if label not in noskip]
    with open(newcompute, "w") as Fc:
        _ = Fc.write("\n".join(newC) + "\n")
    print(f"{len(buff)} labels still in write queue")
    return buff, errors, skip, noskip, malformed

def get_timing_info(datafile="output", data=None):
    if data is None:
        data = get_data(datafile)
    times = data["T"]
    unfinished = Counter()
    skips = Counter()
    finished = {}
    stats = defaultdict(list)
    for label, lines in times.items():
        lines = [x.split("|")[-1] for x in lines] # remove labels
        # Get skipped codes:
        if lines[-1].startswith("Skip-"):
            skips[lines[-1][5:].strip()] += 1
            lines = lines[:-1]
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
    return unfinished, finished, maxs, avgs, stats, skips

err_location_re = re.compile(r'In file "(.*)", line (\d+), column (\d+):')
schur_re = re.compile("Runtime error in 'pMultiplicator': Cohomology failed")
basim_re = re.compile("Internal error in permc_random_base_change_basim_sub() at permc/chbase.c, line 488")
aut_closed_re = re.compile("Runtime error: subgroups not closed under automorphism")
internal_re = re.compile(r'Magma: Internal error')
myquo_re = re.compile(r"Degree \d+=[\d\+]+ \(prior best")
def get_errors(datafile="output", data=None):
    if data is None:
        data = get_data(datafile)
    errors = data["E"]
    located = defaultdict(list)
    #internalD = defaultdict(list)
    knownD = defaultdict(list)
    unknown = []
    # Search for the last occurence of a file number
    for label, errlines in errors.items():
        lastloc = None
        internal = False
        for i, line in enumerate(errlines):
            if myquo_re.search(line): continue
            m = err_location_re.search(line)
            if m:
                lastloc = i
                loc = m.groups()
                continue
            if internal_re.search(line):
                internal = True
                continue
            elif schur_re.search(line):
                known = "schur"
                break
            elif basim_re.search(line):
                known = "basim"
                break
            elif aut_closed_re.search(line):
                known = "autclosed"
                break
        else:
            if lastloc is not None:
                located[loc].append((label, errlines[lastloc+1:]))
            elif internal:
                unknown.append((label, errlines))
            continue
        knownD[known].append(label)
    return located, knownD, unknown

def show_errors(label, data):
    print("\n".join(data["E"][label]))

def sort_key(label):
    return [class_to_int(c) for c in label.split(".")]

def labels_by_type(data):
    # Return three lists:
    # 1. the labels that finished with no errors
    # 2. the labels that did not finish but had no errors
    # 3. the labels with some error output
    E = set(data["E"])
    finished = []
    unfinished = []
    for label, lines in data["T"].items():
        if label in E: continue
        lines = [x.split("|")[-1] for x in lines] # remove labels
        if lines[-1].startswith("Finished AllFinished in "):
            finished.append(label)
        else:
            unfinished.append(label)
    errors = list(E)
    for L in [finished, unfinished, errors]:
        L.sort(key=sort_key)
    return finished, unfinished, errors

def tmpheaders(summarize=False):
    # Return a dictionary giving the columns included in each tmpheader, indexed by the one-letter code included at the beginning of each corresponding output line
    codes = {}
    heads = {}
    for head in os.listdir():
        if head.endswith(".tmpheader"):
            with open(head) as F:
                code, attrs = F.read().strip().split("\n")
            if summarize:
                heads[head[:-10]] = code
            else:
                assert code not in codes
            codes[code] = attrs.split("|")
    if summarize:
        for head, code in sorted(heads.items()):
            print(code, head, "|".join(codes[code]))
            print()
    else:
        return codes

def headers():
    # Return a dictionary giving the the columns and types in each header, indexed by the header name
    headers = {}
    for head in os.listdir():
        if head.endswith(".header") and head.startswith("LMFDB"):
            name = head[5:-7]
            with open(head) as F:
                cols, types = F.read().strip().split("\n")
            cols = cols.split("|")
            types = types.split("|")
            assert len(cols) == len(types)
            headers[name] = (cols, types)
    return headers

def write_upload_files(data, overwrite=False):
    finished, unfinished, errors = labels_by_type(data)
    tmps = tmpheaders()
    finals = headers()
    final_to_tmp = {
        "SubGrp": "SLDI",
        "GrpConjCls": "J",
        "GrpChtrCC": "C",
        "GrpChtrQQ": "Q",
        "Grp": "blajcqshtguomwi" # skip zr since they're just used internally
    }
    out = defaultdict(lambda: defaultdict(lambda: defaultdict(dict)))
    for oname, codes in final_to_tmp.items():
        if not overwrite and ope(oname+".txt"):
            raise ValueError("File %s.txt already exists" % oname)
        for code in codes:
            cols = tmps[code]
            label_loc = cols.index("label")
            #missing = [gp_label for gp_label in finished if gp_label not in data[code]]
            #if missing:
            #    raise ValueError("Missing %s entries for %s: %s..." % (len(missing), code, missing[0]))
            for gp_label, lines in data[code].items():
                if gp_label in finished:
                    for line in lines:
                        line = line.split("|")
                        assert len(line) == len(cols)
                        label = line[label_loc]
                        # subagg3 accidentally used short_labels rather than labels
                        D = dict(zip(cols, line))
                        if code == "D":
                            label = "%s.%s" % (D["ambient"], D["label"])
                            D["label"] = label
                        out[oname][gp_label][label].update(D)
    # Sort them....
    # Update centers, kernels and centralizers from the corresponding columns
    for gp_label, gpD in out["Grp"].items():
        # only new groups for now
        gpD = gpD[gp_label]
        if "charc_centers" in gpD:
            centers = gpD["charc_centers"][1:-1].split(",")
            for label, D in out["GrpChtrCC"][gp_label].items():
                D["center"] = centers[int(D["counter"])-1]
        if "charc_kernels" in gpD:
            kernels = gpD["charc_kernels"][1:-1].split(",")
            for label, D in out["GrpChtrCC"][gp_label].items():
                D["kernel"] = kernels[int(D["counter"])-1]
        if "conj_centralizers" in gpD:
            centralizers = gpD["conj_centralizers"][1:-1].split(",")
            for label, D in out["GrpConjCls"][gp_label].items():
                D["centralizer"] = centralizers[int(D["counter"])-1]
    for oname, (final_cols, final_types) in finals.items():
        with open(opj("DATA", oname+".txt"), "w") as F:
            _ = F.write("|".join(final_cols) + "\n" + "|".join(final_types) + "\n\n")
            for gp_label, gpD in out[oname].items():
                for label, D in gpD.items():
                    _ = F.write("|".join(D.get(col, r"\N") for col in final_cols) + "\n")
