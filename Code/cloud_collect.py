#!/usr/bin/env python3

# Move the output file to be collected into the DATA directory, named output{n}.txt, where n is the phase.

import sys, os, re, string, time
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

def label_charconj(out):
    # Updates the "out" dictionary, moving labels for character kernels and centers and for conjugacy class centralizers to the right columns
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

def update_output_file(infile, outfile, overwrite=False):
    # Update output files based on several changes to tmpheaders (moving monomial and solvability from Code-c to Code-v, rank and eulerian_function from Code-s to Code-i, etc)
    if not overwrite and ope(outfile):
        raise ValueError(f"{outfile} already exists")
    with open(infile) as F:
        with open(outfile, "w") as Fout:
            for line in F:
                if line[0] == "c" and line.count("|") == 6: # old format for monomial and solvability
                    pieces = line.split("|")
                    label = pieces[0][1:]
                    _ = Fout.write("|".join(pieces[:3] + pieces[5:])) # last piece includes \n
                    _ = Fout.write("|".join(["v" + pieces[0][1:], pieces[3], pieces[4]]) + "\n")
                elif line[0] == "L" and line.count("|") == 13: # old format for a bunch of Weyl subgroup quantities
                    pieces = line.split("|")
                    _ = Fout.write("|".join(pieces[:4]) + "\n")
                    _ = Fout.write("|".join(["W" + pieces[0][1:], pieces[1]] + pieces[4:])) # last piece includes \n
                elif line[0] == "s" and line.count("|") == 22: # old format for rank and eulerian_function
                    pieces = line.split("|")
                    _ = Fout.write("|".join(pieces[:3] + pieces[4:8] + pieces[9:])) # last piece includes \n
                    _ = Fout.write("|".join(["i" + pieces[0][1:], pieces[3], pieces[8]]) + "\n")
                elif line[0] == "S" and line.count("|") == 55: # old format for mobius_quo and mobius_sub
                    pieces = line.split("|")
                    _ = Fout.write("|".join(pieces[:29] + pieces[31:])) # last piece includes \n
                    _ = Fout.write("|".join(["I" + pieces[0][1:], pieces[24], pieces[29], pieces[30]]) + "\n")
                else:
                    _ = Fout.write(line)

def update_all_outputs(outfolder, overwrite=False):
    # Should be run inside the input folder
    for root, dirs, files in os.walk("."):
        os.makedirs(opj(outfolder, root[2:]), exist_ok=True)
        if "TE" in dirs:
            os.rename(opj(root[2:], "TE"), opj(outfolder, root[2:], "TE"))
        for fname in files:
            update_output_file(opj(root[2:], fname), opj(outfolder, root[2:], fname), overwrite=overwrite)

def extract_unlabeled_groups(infolders, outfolder, skipfile, todofile, curfolder=None, codes={0:"XH", 1:"XTH"}):
    seen = set()
    os.makedirs(outfolder, exist_ok=True)
    if curfolder is None:
        curfolder = outfolder
    existing = os.listdir(curfolder)
    starti = len(existing)
    for i, fname in enumerate(existing):
        if i and (i%10000 == 0):
            print("Reading curfolder", i)
        with open(opj(curfolder, fname)) as F:
            for line in F:
                line = line.strip()
                if line:
                    label, x  = line.split("|")
                    seen.add(x)
    matcher = re.compile(r"\?([^\?]+)\?")
    unlabeled = defaultdict(set)
    if isinstance(infolders, str):
        infolders = [infolders]
    with open(skipfile, "w") as Fskip:
        for inum, infolder in enumerate(infolders):
            for root, dirs, files in os.walk(infolder):
                for fname in files:
                    if fname.startswith("output") or fname.startswith("grp-"):
                        with open(opj(root, fname)) as F:
                            for j, line in enumerate(F):
                                label = line[1:].split("|")[0].split("(")[0]
                                for x in matcher.findall(line):
                                    if len(x) > 10000 and "Perm" in x:
                                        d = int(x[:x.index("P")])
                                        if d > 8192:
                                            Fskip.write(f"{root}/{fname}: line {j}, {d}Perm\n")
                                            continue
                                    if x not in seen:
                                        unlabeled[x].add((label, inum))
                                        if len(unlabeled) % 1000000 == 0:
                                            print("Reading infolder", len(unlabeled))
    print("Done reading infolder")
    for x, labels in unlabeled.items():
        minlabel = min(labels, key=lambda y: sort_key(y[0]))
        inums = set(y[1] for y in labels)
        unlabeled[x] = (minlabel[0], inums)
    print("Done changing unlabeled")
    UL = defaultdict(list)
    for x, (label, inums) in unlabeled.items():
        UL[label].append((x, inums))
    del unlabeled
    print("Done creating UL")
    i = starti*1000
    try:
        with open(todofile, "w") as Ftodo:
            Fout = None
            for label in sorted(UL, key=sort_key):
                for x, inums in UL[label]:
                    if i % 1000 == 0:
                        if Fout is not None:
                            Fout.close()
                        Fout = open(opj(outfolder, str(i//1000)), "w")
                    if i%1000000 == 0:
                        print("Writing outfolder", i)
                    _ = Fout.write(f"{label}|{x}\n")
                    _ = Ftodo.write(f"{i} {codes[max(inums)]}\n")
                    i += 1
    finally:
        Fout.close()
        os.sync() # We wrote a lot of stuff
    print(f"First: {starti*1000}\nLast: {i-1}")

def extract_unfinished_file(infolder, outfile):
    finished = defaultdict(set)
    allcodes = "blajJzcCrqQsvSDLWhtguoIimw"
    sik = defaultdict(bool)
    for root, dirs, files in os.walk(infolder):
        for fname in files:
            if fname.startswith("output") or fname.startswith("grp-"):
                    with open(opj(root, fname)) as F:
                        for line in F:
                            pieces = line[1:].split("|")
                            label = pieces[0].split("(")[0]
                            finished[label].add(line[0])
                            if line[0] == "s":
                                sik[label] = sik[label] or (pieces[8] == "t")
    with open(outfile, "w") as F:
        for label in sorted(finished, key=sort_key):
            missing_codes = "".join(c for c in allcodes if c not in finished[label])
            if label in sik and not sik[label]:
                # Don't need D here
                missing_codes = missing_codes.replace("D", "")
            if missing_codes:
                _ = F.write(f"{label} {missing_codes}\n")

def build_treps(datafolder="/scratch/grp", alias_file="DATA/aliases.txt", descriptions_folder="DATA/descriptions"):
    all_labels = set(os.listdir(descriptions_folder))
    sys.path.append(os.path.expanduser("~/lmfdb"))
    from lmfdb import db
    import itertools
    manual_old = {
        "20T272": "3420.a",
        "22T15": "2420.x",
        "22T17": "2420.bl",
        "22T18": "2420.b",
        "22T21": "6050.m",
        "22T25": "12100.o",
        "30T808": "12180.a",
        "33T19": "3630.b",
        "33T20": "3630.p",
        "33T21": "3630.p",
        "33T25": "7260.bg",
        "38T18": "4332.g",
        "38T29": "12996.p",
        "38T33": "25308.a",
        "44T55": "2420.ba",
        "44T56": "2420.y",
        "44T57": "2420.p",
        "44T58": "2420.q",
        "44T59": "2420.x",
        "44T61": "2420.bl",
        "44T62": "2420.b",
        "44T136": "12100.q",
        "44T137": "12100.n",
        "44T139": "12100.o",
        "44T233": "39732.a",
    }
    manual_new = {
        "26T21": "2028.q",
        "26T22": "2028.r",
        "26T23": "2028.s",
        "39T34": "2028.s",
        "26T24": "2028.t",
        "39T35": "2028.t",
        "39T32": "2028.u",
        "39T33": "2028.v",
        "22T16": "2420.bn",
        "44T60": "2420.bn",
        "26T27": "3042.e",
        "39T39": "3042.e",
        "39T40": "3042.e",
        "39T38": "3042.f",
        "42T334": "3276.h",
        "42T335": "3276.h",
        "38T16": "4332.n",
        "38T17": "4332.o",
        "38T19": "4332.p",
        "26T40": "6084.i",
        "39T46": "6084.i",
        "26T41": "6084.j",
        "39T45": "6084.j",
        "39T44": "6084.k",
        "38T20": "6498.m",
        "38T21": "6498.n",
        "38T22": "6498.o",
        "22T24": "12100.bk",
        "44T138": "12100.bk",
        "38T25": "12996.z",
        "38T26": "12996.ba",
        "38T27": "12996.bb",
        "38T28": "12996.bc",
        "38T30": "12996.bd",
        "46T13": "23276.a",
        "46T14": "23276.b",
        "46T15": "23276.c",
        "46T16": "23276.d",
    }
    taliases = defaultdict(list)
    tre = re.compile(r"(\d+)T(\d+)")
    tseen = defaultdict(set)
    with open(alias_file) as F:
        for line in F:
            label, desc = line.strip().split()
            m = tre.fullmatch(desc)
            if m:
                n, t = [int(c) for c in m.groups()]
                taliases[label].append(desc)
                tseen[n].add(t)
    for desc, label in itertools.chain(manual_old.items(), manual_new.items()):
        taliases[label].append(desc)
        n, t = [int(c) for c in tre.fullmatch(desc).groups()]
        tseen[n].add(t)
    tgid = {}
    tneeded = defaultdict(list)
    tneeded[32] = range(2799324, 2801325)
    for rec in db.gps_transitive.search({"order":{"$or":[512, 640, 768, 896, 1024, 1152, 1280, 1408, 1536, 1664, 1792, 1920, {"$gt": 2000}]}, "n":{"$ne": 32}}, ["n", "t", "order", "label", "gapid"]):
        tneeded[rec["n"]].append(rec["t"])
        if rec["gapid"] != 0:
            tgid[rec["label"]] = f"{rec['order']}.{rec['gapid']}"
    tmissing = {}
    lmissing = []
    for n in range(1, 48):
        v = []
        for t in tneeded[n]:
            if t not in tseen[n]:
                tlabel = f"{n}T{t}"
                if tlabel in tgid:
                    label = tgid[tlabel]
                    taliases[label].append(tlabel)
                    if label not in all_labels:
                        lmissing.append(label)
                else:
                    v.append(t)
        if v:
            v.sort()
            tmissing[n] = v
    labeled32 = []
    unlabeled32 = []
    for rec in db.gps_transitive.search({"order": {"$or":[512, 640, 768, 896, 1024, 1152, 1280, 1408, 1536, 1664, 1792, 1920]}, "n": 32}, ["t", "order", "label", "gapid"]):
        if rec["t"] in tseen[32]:
            continue
        if rec["gapid"] == 0:
            unlabeled32.append((rec["order"], rec["t"]))
            continue
        label = f"{rec['order']}.{rec['gapid']}"
        if label not in all_labels:
            labeled32.append(label)

    transitive_subs = defaultdict(list)
    for root, dirs, files in os.walk(datafolder):
        for fname in files:
            if fname.startswith("output") or fname.startswith("grp"):
                sib = {}
                tsubs = defaultdict(list)
                with open(opj(root, fname)) as F:
                    for line in F:
                        if line[0] == "S" and line.count("|") == 53:
                            pieces = line[1:].split("|")
                            N, i = pieces[0].split(".")
                            if not i.isdigit(): # Not a small group
                                ambient_order = int(pieces[2])
                                core_order = int(pieces[17])
                                index = int(pieces[40])
                                if core_order == 1 and (index >= 48 or index == 32 and (512 <= ambient_order <= 40000000000)):
                                    ambient = pieces[0]
                                    generators = pieces[22]
                                    label = pieces[24]
                                    last = label.split(".")[-1]
                                    if last.startswith("CF") or last[0].isdigit() or last[0].islower():
                                        # regular label or corefree label rather than label for a normal subgroup
                                        transitive_subs[ambient].append((index, label, generators))
                        elif line[0] == "s" and line.count("|") == 20:
                            pieces = line[1:].split("|")
                            label = pieces[0]
                            N, i = label.split(".")
                            if not i.isdigit():
                                sbound = int(pieces[9])
                                sib[label].append(sbound)

    return tmissing, lmissing, taliases, unlabeled32, labeled32, transitive_subs

def update_todo_and_preload(datafolder="/scratch/grp/noaut1/raw", oldtodo="DATA/compute_noaut1.todo", newtodo="DATA/compute_noaut2.todo", old_preload_folder="/home/roed/cloud_groups_debug/DATA/preload", new_preload_folder="/home/roed/cloud_groups_debug/DATA/preload2", TEdir="/scratch/grp/noaut1/TE"):
    have = defaultdict(set)
    subtime = defaultdict(float)
    noskips = set()
    skips = defaultdict(list)
    terminate = {}
    shortdivs = set()
    noauth = set()
    maxmem = defaultdict(float)
    started_normal = set()
    normal_time = {}
    errors = defaultdict(list)
    memerrored = set()
    errored = set()
    TElines = defaultdict(list)
    known_errors = [
        'Runtime error in quo< ... >: Index of subgroup is too large',
        "Runtime error: Variable 'lowtop' has not been initialized",
    ]
    for fname in os.listdir(datafolder):
        divs = []
        empty_div_expected = False
        if fname.endswith(".log"):
            # ignore for now
            continue
        with open(opj(datafolder, fname)) as F:
            for line in F:
                label, text = line[1:].strip().split("|", 1)
                if line[0] in "TE":
                    label = label.split("(")[0]
                    TElines[label].append(line)
                    if "GB used" in text:
                        mem = float(text.split("GB used")[0].rsplit("(",1)[1])
                        maxmem[label] = max(maxmem[label], mem)
                    if "SubGrpLstConjDivisor" in text:
                        label = label.split("(")[0]
                        if text.startswith("Starting"):
                            divs.append(int(text.split("(")[1].split(":")[0]))
                        else:
                            tinc = float(text.split(" in ")[1].split()[0])
                            subtime[label] += tinc
                    elif text == "NoSkip":
                        # Yay!
                        noskips.add(label)
                    elif text.startswith("Skip-"):
                        codes = text[5:]
                        skips[codes].append(label)
                    elif text == "Starting IncludeNormalSubgroups":
                        started_normal.add(label)
                    elif text.startswith("Finished IncludeNormalSubgroups"):
                        normal_time[label] = float(text.split(" in ")[1].split()[0])
                    elif line[0] == "E" and "error" in text:
                        errors[text].append(label)
                        # Often want to continue for memory errors, since these can be addressed by setting terminate
                        if text == 'System error: Out of memory.':
                            memerrored.add(label)
                        elif text not in known_errors:
                            # Fixed thes bugs after the 15 minute run
                            errored.add(label)
                    elif line[0] == "E" and text == "Magma is not authorised for use on this machine.":
                        N = int(fname.replace("grp-", "").replace(".txt", "").split("v")[0])
                        noauth.add(N)
                        empty_div_expected = True
                else:
                    have[line[0]].add(label)
        # Either last order shown took us over the limit, so we can actually skip it next time, or the last order timed out, so we want to skip it.  The only case where we want to go all the way down is if we actually finished.
        if empty_div_expected:
            continue
        if len(divs) < 2:
            # Something's weird
            shortdivs.add(label)
        elif divs[-1] == 1:
            # Made it all the way to the end!
            terminate[label] = 1
        else:
            terminate[label] = divs[-2]
    noauth = sorted(noauth)
    print("Checking NoSkip consistency")
    for label in noskips:
        if not all(label in have[c] for c in "sSnL"):
            print("Inconsistent NoSkip", label)
            break
    print("Making TE")
    if not ope(TEdir):
        os.makedirs(TEdir)
        for label, lines in TElines.items():
            with open(opj(TEdir, label), "w") as F:
                _ = F.write("".join(lines))
    preloads = {}
    print("Loading preloads")
    for label in os.listdir(old_preload_folder):
        with open(opj(old_preload_folder, label)) as F:
            heads, vals = F.read().strip().split("\n")
            heads = heads.split("|")
            vals = vals.split("|")
            preloads[label] = dict(zip(heads, vals))
    print("Loading old todo")
    unseen = set()
    with open(oldtodo) as F:
        with open(newtodo, "w") as Fout:
            for line in F:
                label, codes = line.strip().split()
                if label not in TElines:
                    unseen.add(label)
                if label in noskips or label in errored or label in memerrored and label in started_normal and label not in normal_time:
                    continue
                _ = Fout.write(line)
                if label in terminate:
                    preloads[label]["SubGrpLstByDivisorTerminate"] = str(terminate[label])
                with open(opj(new_preload_folder, label), "w") as Fp:
                    L1, L2 = zip(*preloads[label].items())
                    L1 = "|".join(L1)
                    L2 = "|".join(L2)
                    _ = Fp.write(f"{L1}\n{L2}\n")
    return have, noskips, skips, maxmem, subtime, normal_time, started_normal, errors, errored, terminate, shortdivs, noauth, unseen

#def improve_names(out):
#    names = {label: D[label].get("name") for (label, D) in out["Grp"].items()}
#    tex_names = {label: D[label].get("tex_name") for (label, D) in out["Grp"].items()}
#    for gp_label, gpD in out["SubGrp"].items():
#        for label, D in gpD.items():
#            if D.get("normal") == "t" and D.get("subgroup", r"\N") != r"\N" and D.get("quotient", r"\N") != r"\N":
#                

merge_errors = []
subquo_nodivide = []
labelset_mismatch = []
othercode_mismatch = []
aggid_mismatch = defaultdict(list)
noncanonical = set()
extra_cols = set() # expected: {'backup_solvability_type', 'charc_centers', 'charc_kernels', 'conj_centralizers', 'easy_rank', 'gens_used'}
multiG = []
def collate_sources(sources, lines, tmps, ambient_label):
    def todict(code, line):
        return dict(zip(tmps[code], line.split("|")))
    def merge(code, Ds, arbitrary=[], known_conflict=[]):
        merged = defaultdict(lambda: r"\N")
        for col in tmps[code]:
            for D in Ds:
                if D[col] != r"\N":
                    if col in ["central_quotient", "center_label", "frattini_quotient", "frattini_label", "abelian_quotient", "commutator_label"]:
                        # Something weird is happening here, but at least we can rule out labels where the order doesn't divide the ambient order
                        ambientN = ZZ(ambient_label.split(".")[0])
                        thisN = ZZ(D[col].split(".")[0])
                        if not thisN.divides(ambientN):
                            subquo_nodivide.append((ambient_label, D[col]))
                            continue
                    if col in merged:
                        # merged[col]=\N means actively added due to known_conflict
                        if merged[col] != D[col] and col not in arbitrary:
                            if col in ["primary_abelian_invariants", "smith_abelian_invariants"]:
                                # Some incorrect info was manually entered for large GL(2,p)s.  We pick the right one
                                if D[col] == "{2}":
                                    continue
                                else:
                                    merged[col] = D[col]
                                    continue
                            if col in known_conflict:
                                merged[col] = r"\N"
                                break
                            merge_errors.append((code, Ds, col))
                    else:
                        merged[col] = D[col]
        return merged
    out = {}
    for code, src_list in sources.items():
        # Don't include z or r, since they're only used internally
        if code in "zr":
            continue
        src_list = list(src_list)
        if code == "s":
            assert all(len(lines[code][src]) == 1 for src in src_list)
            Dsorig = Ds = [(src, todict(code, lines[code][src][0])) for src in src_list]
            # First we omit sources that didn't give any subgroups
            Ds = [(src, D) for (src, D) in Ds if len(lines["S"][src]) > 0]
            for col, desired in [("subgroup_inclusions_known", "t"), ("all_subgroups_known", "t"), ("complements_known", "t"), ("outer_equivalence", "f")]:
                if any([D[col] == desired for (src, D) in Ds]):
                    Ds = [(src, D) for (src, D) in Ds if D[col] == desired]
                    if len(Ds) == 1:
                        break
            if len(Ds) > 1:
                m = max(int(D["subgroup_index_bound"]) for (src, D) in Ds)
                Ds = [(src, D) for (src, D) in Ds if int(D["subgroup_index_bound"]) == m]
                if len(Ds) > 1:
                    # There were code changes between noaut1 and noaut2, including Sylows and normals.  Also, in some cases there are multiple runs and one got further than the other.  So prefer larger list of subgroups
                    for subcode in "SLWDIh":
                        M = max(len(lines[subcode][src]) for (src, D) in Ds)
                        Ds = [(src, D) for (src, D) in Ds if len(lines[subcode][src]) == M]
                        if len(Ds) == 1:
                            break
                    # In the noaut1/noaut2 runs, the labels aren't canonical, so we can't match them and need to pick
                    # Moreover, there seems to be an issue in general that even our "canonical" labels are not determinstic.  For now, we just pick one source.
                    Ds = [Ds[0]]
                    # noncan = set()
                    # for src, D in Ds:
                    #     for line in lines["S"][src]:
                    #         label = todict("S", line)["label"]
                    #         if label[-1].isupper() and not any(label.endswith(post) for post in [".N", ".M", ".CF"]):
                    #             noncanonical.add(src)
                    #             noncan.add(src)
                    #             break
                    # if len(noncan) == len(Ds):
                    #     # Just pick one
                    #     Ds = [Ds[0]]
                    # else:
                    #     Ds = [(src, D) for (src, D) in Ds if src not in noncan]
                    #     # Otherwise the labels should match as well, so we can combine data.
                    #     if len(Ds) > 1:
                    #         # The following groups had inconsistencies in labeling their subgroups; for now we pick one result
                    #         if ambient_label in ['4332.n', '4332.o']:
                    #             Ds = [pair for pair in Ds if pair[0] == 'fixsmall8']
                    #         elif ambient_label in ['6144.xa', '6144.yn', '6144.zc', '115200.bo', '230400.bg']:
                    #             Ds = [pair for pair in Ds if pair[0] =='lowmem_termS2']
                    #         elif ambient_label in ['640000.ik', '13436928.te']:
                    #             Ds = [pair for pair in Ds if pair[0] == 'sopt3']

                    #         for subcode in "SLWDIh":
                    #             Ss = defaultdict(list)
                    #             for src, D in Ds:
                    #                 for sub in lines[subcode][src]:
                    #                     SD = todict(subcode, sub)
                    #                     Ss[SD["label"]].append(SD)
                    #             if not all(len(v) == len(Ds) for v in Ss.values()):
                    #                 bad_labels = set(lab for lab, SDs in Ss.items() if len(SDs) != len(Ds))
                    #                 labels_by_src = defaultdict(list)
                    #                 for src, D in Ds:
                    #                     for sub in lines[subcode][src]:
                    #                         SD = todict(subcode, sub)
                    #                         if SD["label"] in bad_labels:
                    #                             ambient = SD["ambient"]
                    #                             labels_by_src[src].append(SD["label"])
                    #                 labelset_mismatch.append((ambient, subcode, labels_by_src))
                    #                 #print("len(Ds)", len(Ds))
                    #                 #print([todict(subcode, y)["label"] for y in lines[subcode][Ds[0][0]]])
                    #                 #print([todict(subcode, y)["label"] for y in lines[subcode][Ds[1][0]]])
                    #                 #print([[y["label"] for y in v] for v in Ss.values() if len(v) != len(Ds)])
                    #             #assert all(len(v) == len(Ds) for v in Ss.values())
                    #             else:
                    #                 for slabel, SDs in Ss.items():
                    #                     Ss[slabel] = merge(subcode, SDs, arbitrary=["generators", "diagramx", "subgroup_tex", "quotient_tex", "ambient_tex"])
                    #                 out[subcode] = Ss.values()
                    #         out["s"] = merge("s", [D for (src, D) in Ds])
            if len(Ds) == 1: # Since we set Ds = [Ds[0]] above, this will always be true
                # We still want to merge to get access to intrinsically defined columns
                exts = ["subgroup_inclusions_known", "all_subgroups_known", "complements_known", "outer_equivalence", "subgroup_index_bound"]
                out["s"] = [merge("s", [D for (src, D) in Dsorig], arbitrary=exts)]
                for col in exts:
                    out["s"][0][col] = Ds[0][1][col]
                for subcode in "SLWDIh":
                    out[subcode] = [todict(subcode, line) for line in lines[subcode][Ds[0][0]]]
        elif code == "J":
            # First we omit sources that didn't give any conjugacy class reps
            srcs = [src for src in src_list if len(lines["J"][src]) > 0]
            if len(srcs) > 1:
                for subcode in "CQ":
                    if any(len(lines[subcode][src]) > 0 for src in srcs):
                        srcs = [src for src in srcs if len(lines[subcode][src]) > 0]
                # Now just pick arbitrarily: just need consistency
                srcs = [srcs[0]]
            for subcode in "JCQ":
                out[subcode] = [todict(subcode, line) for line in lines[subcode][srcs[0]]]
        elif code in "SLWDIhCQ":
            pass # dealt with in code-s or code-J above
        elif code == "a":
            # There are some cases where multiple lines are output from the same source
            out[code] = [merge(code, [todict(code, line) for src in src_list for line in lines[code][src]], arbitrary=["aut_gens"])]
        elif code == "i":
            out[code] = [merge(code, [todict(code, line) for src in src_list for line in lines[code][src]])]
        elif code == "t":
            # tex_name isn't deterministic, so we just take the first output
            out[code] = [todict(code, lines[code][src_list[0]][0])]
        elif code == "w" and ambient_label == "1536.408544622":
            # There were two runs, with different values of index bound, so in one the subgroups were identified and in the other they weren't.
            out[code] = [{"label": "1536.408544622", "wreath_data":'{"192.j1","512.a1","1536.a1","3T1"}', "wreath_product": "t"}]
        else:
            Ss = defaultdict(list)
            for src in src_list:
                for line in set(lines[code][src]):
                    SD = todict(code, line)
                    Ss[SD["label"]].append(SD)
            if any(len(v) != len(src_list) for v in Ss.values()):
                bad_labels = set(lab for lab, SDs in Ss.items() if len(SDs) != len(src_list))
                labels_by_src = defaultdict(list)
                ambient = None
                for src in src_list:
                    for sub in lines[code][src]:
                        SD = todict(code, sub)
                        thislabel = SD["label"]
                        if ambient is None:
                            ambient = thislabel
                        else:
                            i = min(len(ambient), len(thislabel))
                            while ambient[:i] != thislabel[:i]:
                                i -= 1
                            ambient = ambient[:i]
                        if thislabel in bad_labels:
                            labels_by_src[src].append(thislabel)
                othercode_mismatch.append((ambient, code, labels_by_src))
            #assert all(len(v) == len(src_list) for v in Ss.values())
            else:
                for slabel, SDs in Ss.items():
                    Ss[slabel] = merge(code, SDs)
                out[code] = list(Ss.values())
    return out

def write_upload_files(datafolder, outfolder="/scratch/grp/upload/", overwrite=False):
    # datafolder should have a subfolder for each group, with files inside each containing data lines
    tmps = tmpheaders()
    final_to_tmp = {
        "SubGrp": "SLWDI",
        "GrpConjCls": "J",
        "GrpChtrCC": "C",
        "GrpChtrQQ": "Q",
        "Grp": "blajcqshtguomwinv" # skip zr since they're just used internally
    }
    finals = {oname: odata for (oname, odata) in headers().items() if oname in final_to_tmp}
    if not overwrite and any(ope(f"{final}.txt") for final in final_to_tmp):
        raise ValueError("An output file already exists; you can use overwrite to proceed anyway")
    writers = {final: open(opj(outfolder, f"{final}.txt"), "w") for final in final_to_tmp}
    try:
        for oname, (final_cols, final_types) in finals.items():
            _ = writers[oname].write("|".join(final_cols) + "\n" + "|".join(final_types) + "\n\n")
        for label in sorted(os.listdir(datafolder), key=sort_key):
            # There may be multiple sources of data from different runs; in many cases this data will be compatible and we just need to prevent duplication, but sometimes one is better than another (subgroup inclusions known or not, better bounds, etc)
            # Here are the different conflicts that are anticipated:
            # code-t (tex_name): Magma's GroupName isn't deterministic, and we can just pick one.
            # code-z (conj_centralizer_gens): depends on choice of reps for conjugacy classes and generators; also only used internally.
            # code-r (charc_center_gens, charc_kernel_gens): depends on choice of generators for subgroups; also only used internally.
            # code-h (charc_centers, charc_kernels): this is more worrisome, and occurred for 3072.hm 3072.ih 6144.xa 6144.yn 57600.dh 87480.h 115200.h 115200.bo 118098.gh.
            # code-u (aut_stats, number_autjugacy_classes): also worrisome, and occured for 7500.u 8000.bu 10368.bu 10368.cu 20000.u 20736.ju 31104.hu 40000.eu 80000.cu 160000.bu 160000.uo 160000.us 200000.u 320000.mv 320000.uo 320000.xb 320000.bau 320000.bem 640000.ku 640000.uc 5000000.u
            # code-l (labels for certain characteristic subgroups): this is okay (nulls in one line match non-null in another)
            # code-a (first-pass aut group info): just different generators for automorphism group, so pick shorter one?
            # code-s (first-pass subgroup info): Columns come in two flavors: those computing something intrinsic about the group (number_normal_subgroups, etc) and those describing which subgroups were kepts and which quantities were computed about them.  There are several conflicts in intrinsic columns (direct_product, semidirect_product, number_characteristic_subgroups), and we choose a total order for the possible extrinsic settings
            # Tricky: all_subgroups_known vs subgroup_inclusions known
            # Proposed: subgroup_inclusions_known then all_subgroups_known then complements_known then outer_equivalence
            sources = defaultdict(set)
            lines = defaultdict(lambda: defaultdict(list))
            for source in os.listdir(opj(datafolder, label)):
                with open(opj(datafolder, label, source)) as F:
                    for line in F:
                        code = line[0]
                        sources[code].add(source)
                        lines[code][source].append(line[1:].strip())
            out = collate_sources(sources, lines, tmps, label)
            if len(out.get("s", [])) > 0 and out["s"][0].get("conj_centralizers", r"\N") != r"\N":
                conj_centralizers = out["s"][0]["conj_centralizers"]
                conj_centralizers = conj_centralizers[1:-1].split(",")
                if len(conj_centralizers) != len(out.get("J", [])):
                    aggid_mismatch["conj_centralizers"].append((label, len(out.get("J", [])), conj_centralizers))
                else:
                    for cc, cent in zip(out["J"], conj_centralizers):
                        cc["centralizer"] = cent
            if len(out.get("h", [])) > 0:
                for col, aggcol in [("charc_centers", "center"), ("charc_kernels", "kernel")]:
                    if out["h"][0].get(col, r"\N") != r"\N":
                        colval = out["h"][0][col]
                        colval = colval[1:-1].split(",")
                        if len(colval) != len(out.get("C", [])):
                            aggid_mismatch[col].append((label, len(out.get("C", [])), colval))
                        else:
                            for char, sub in zip(out["C"], colval):
                                char[aggcol] = sub
            for oname, codes in final_to_tmp.items():
                final_cols = finals[oname][0]
                if len(codes) == 1:
                    # GrpConjCls, GrpChtrCC or GrpChtrQQ
                    for row in out.get(codes[0], []):
                        for col in set(row).difference(set(final_cols)):
                            extra_cols.add(col)
                        _ = writers[oname].write("|".join(row.get(col, r"\N") for col in final_cols) + "\n")
                elif oname == "Grp":
                    odata = {}
                    for code in codes:
                        if code in out:
                            if len(out[code]) != 1:
                                multiG.append((label, code, len(out[code])))
                            if len(out[code]) > 0:
                                odata.update(out[code][0])
                    if odata.get("rank", r"\N") == r"\N" and odata.get("easy_rank", r"\N") != r"\N":
                        odata["rank"] = odata["easy_rank"]
                    if odata.get("solvability_type", r"\N") == r"\N" and odata.get("backup_solvability_type", r"\N") != r"\N":
                        odata["solvability_type"] = odata["backup_solvability_type"]
                    for col in set(odata).difference(set(final_cols)):
                        extra_cols.add(col)
                    _ = writers[oname].write("|".join(odata.get(col, r"\N") for col in final_cols) + "\n")
                else: # SubGrp
                    odata = defaultdict(dict)
                    for code in codes:
                        if code in out:
                            for row in out[code]:
                                for col in set(row).difference(set(final_cols)):
                                    extra_cols.add(col)
                                odata[row["label"]].update(row)
                    for row in odata.values():
                        _ = writers[oname].write("|".join(row.get(col, r"\N") for col in final_cols) + "\n")
    finally:
        for final in final_to_tmp:
            writers[final].close()

    # out = defaultdict(lambda: defaultdict(lambda: defaultdict(dict)))
    # for oname, codes in final_to_tmp.items():
    #     if not overwrite and ope(oname+".txt"):
    #         raise ValueError("File %s.txt already exists" % oname)
    #     for code in codes:
    #         cols = tmps[code]
    #         label_loc = cols.index("label")
    #         #missing = [gp_label for gp_label in finished if gp_label not in data[code]]
    #         #if missing:
    #         #    raise ValueError("Missing %s entries for %s: %s..." % (len(missing), code, missing[0]))
    #         for gp_label, lines in data[code].items():
    #             if gp_label in finished:
    #                 for line in lines:
    #                     line = line.split("|")
    #                     assert len(line) == len(cols)
    #                     label = line[label_loc]
    #                     # subagg3 accidentally used short_labels rather than labels
    #                     D = dict(zip(cols, line))
    #                     if code == "D":
    #                         label = "%s.%s" % (D["ambient"], D["label"])
    #                         D["label"] = label
    #                     out[oname][gp_label][label].update(D)
    # # Sort them....
    # # Update centers, kernels and centralizers from the corresponding columns
    # for oname, (final_cols, final_types) in finals.items():
    #     with open(opj("DATA", oname+".txt"), "w") as F:
    #         _ = F.write("|".join(final_cols) + "\n" + "|".join(final_types) + "\n\n")
    #         for gp_label, gpD in out[oname].items():
    #             for label, D in gpD.items():
    #                 _ = F.write("|".join(D.get(col, r"\N") for col in final_cols) + "\n")

def get_hshing():
    D = defaultdict(list)
    for folder in ["gps_to_id", "gps_to_id1"]:
        for fname in os.listdir(folder):
            with open(opj(folder, fname) )as F:
                for i, line in enumerate(F):
                    if line.strip():
                        source, desc = line.strip().split("|")
                        hsh = hash(desc)
                        code = 1000*int(fname) + i
                        D[hsh].append(code)
    return D
def get_labels():
    D = {}
    for i in range(1,7):
        for dirpath, dirnames, fnames in os.walk(f"label{i}"):
            if dirpath == "TE": continue
            for fname in fnames:
                if fname.startswith("labelout") or fname.startswith("grp-") and fname.endswith(".txt"):
                    with open(opj(dirpath, fname)) as F:
                        for line in F:
                            if line[0] == "X":
                                gid, label = line[1:].strip().split("|")
                                gid = int(gid)
                                if gid in D:
                                    assert label == D[gid]
                                else:
                                    D[gid] = label
    return D
def make_collation(code_lookup=None, label_lookup=None):
    t0 = time.time()
    if code_lookup is None:
        code_lookup = get_hshing()
        print(f"code_lookup constructed in {time.time()-t0}s")
        t0 = time.time()
    if label_lookup is None:
        label_lookup = get_labels()
        print(f"label_lookup constructed in {time.time()-t0}s")
        t0 = time.time()
    labelRE = re.compile(r"\?([^\?]+)\?")
    for folder in os.listdir():
        print(f"Starting {folder} at time {time.time()-t0}")
        foldD = defaultdict(list)
        def process_file(path):
            with open(path) as F:
                for line in F:
                    code = line[0]
                    if code not in "TE":
                        label, data = line[1:].split("|",1)
                        label = label.split("(")[0]
                        data = labelRE.split(data)
                        for j in range(1,len(data),2):
                            hsh = hash(data[j])
                            for hsh_ctr in code_lookup[hsh]:
                                if hsh_ctr in label_lookup:
                                    data[j] = label_lookup[hsh_ctr]
                                    break
                            else:
                                data[j] = r"\N"
                        data = "".join(data)
                        foldD[label].append(f"{code}{label}|{data}")
        if any(folder.startswith(h) for h in ["15", "60", "fixsmall", "highmem", "lowmem", "noaut", "sopt", "tex", "Xrun", "last"]):
            for sub in os.listdir(folder):
                if sub == "raw":
                    for fname in os.listdir(opj(folder, "raw")):
                        if fname.startswith("grp-") and fname.endswith(".txt"):
                            process_file(opj(folder, "raw", fname))
                elif sub.startswith("output"):
                    process_file(opj(folder, sub))
            for label, lines in foldD.items():
                os.makedirs(opj("collated", label), exist_ok=True)
                with open(opj("collated", label, folder), "a") as F:
                    _ = F.write("".join(lines))
    return code_lookup, label_lookup
