#!/usr/bin/env python3

# Move the output file to be collected into the DATA directory, named output{n}.txt, where n is the phase.

import sys, os, re, string
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

def extract_unlabeled_groups(infolders, outfolder, skipfile):
    seen = set()
    os.makedirs(outfolder, exist_ok=True)
    existing = os.listdir(outfolder)
    starti = len(existing)
    for i, fname in enumerate(existing):
        if i and (i%100000 == 0):
            print("Reading outfolder", i)
        with open(opj(outfolder, fname)) as F:
            label, x  = F.read().strip().split("|")
            seen.add(x)
    matcher = re.compile(r"\?([^\?]+)\?")
    unlabeled = defaultdict(set)
    if isinstance(infolders, str):
        infolders = [infolders]
    with open(skipfile, "w") as Fskip:
        for infolder in infolders:
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
                                        unlabeled[x].add(label)
                                        if len(unlabeled) % 100000 == 0:
                                            print("Reading infolder", len(unlabeled))
    for x in unlabeled:
        unlabeled[x] = min(unlabeled[x], key=sort_key)
    UL = defaultdict(list)
    for x, label in unlabeled.items():
        UL[label].append(x)
    i = starti
    for label in sorted(UL, key=sort_key):
        for x in UL[label]:
            i += 1
            if i%100000 == 0:
                print("Writing outfolder", i)
            with open(opj(outfolder, str(i)), "w") as F:
                _ = F.write(f"{label}|{x}\n")

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

def update_todo_and_preload(datafolder="/scratch/grp/noaut1/raw", oldtodo="DATA/compute_noaut1.todo", newtodo="DATA/compute_noaut2.todo", old_preload_folder="/home/roed/cloud_groups_debug/DATA/preload", new_preload_folder="/home/roed/cloud_groups_debug/DATA/preload2"):
    have = defaultdict(set)
    subtime = defaultdict(float)
    noskips = set()
    skips = defaultdict(list)
    terminate = {}
    shortdivs = set()
    maxmem = defaultdict(float)
    started_normal = set()
    normal_time = {}
    errors = defaultdict(list)
    errored = set()
    for fname in os.listdir(datafolder):
        divs = []
        with open(opj(datafolder, fname)) as F:
            for line in F:
                if line[0] in "TE":
                    label, text = line[1:].strip().split("|", 1)
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
                        errored.add(label)
                else:
                    have[line[0]].add(label)
        # Either last order shown took us over the limit, so we can actually skip it next time, or the last order timed out, so we want to skip it.  The only case where we want to go all the way down is if we actually finished.
        if len(divs) < 2:
            # Something's weird
            shortdivs.add(label)
        elif divs[-1] == 1:
            # Made it all the way to the end!
            terminate[label] = 1
        else:
            terminate[label] = divs[-2]
    for label in noskips:
        if not all(label in have[c] for c in "sSnL"):
            print("Inconsistent NoSkip", label)
            break
    preloads = {}
    print("Loading preloads")
    for label in os.listdir(old_preload_folder):
        with open(opj(old_preload_folder, label)) as F:
            heads, vals = F.read().strip().split("\n")
            heads = heads.split("|")
            vals = vals.split("|")
            preloads[label] = dict(zip(heads, vals))
    print("Loading old todo")
    with open(oldtodo) as F:
        with open(newtodo, "w") as Fout:
            for line in F:
                label, codes = line.strip().split()
                if label in noskips or label in errored:
                    continue
                _ = Fout.write(line)
                with open(opj(new_preload_folder, label)) as Fp:
                    L1, L2 = zip(*preloads[label].items())
                    L1 = "|".join(L1)
                    L2 = "|".join(L2)
                    _ = Fp.write(f"{L1}\n{L2}\n")
    return have, noskips, skips, maxmem, subtime, normal_time, started_normal, errors, errored, terminate, shortdivs

#def improve_names(out):
#    names = {label: D[label].get("name") for (label, D) in out["Grp"].items()}
#    tex_names = {label: D[label].get("tex_name") for (label, D) in out["Grp"].items()}
#    for gp_label, gpD in out["SubGrp"].items():
#        for label, D in gpD.items():
#            if D.get("normal") == "t" and D.get("subgroup", r"\N") != r"\N" and D.get("quotient", r"\N") != r"\N":
#                

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
    for oname, (final_cols, final_types) in finals.items():
        with open(opj("DATA", oname+".txt"), "w") as F:
            _ = F.write("|".join(final_cols) + "\n" + "|".join(final_types) + "\n\n")
            for gp_label, gpD in out[oname].items():
                for label, D in gpD.items():
                    _ = F.write("|".join(D.get(col, r"\N") for col in final_cols) + "\n")
