import sys
import os
import re
opj = os.path.join
ope = os.path.exists
from collections import defaultdict
from sage.all import ZZ
from sage.databases.cremona import class_to_int
### Need to import db

nonsolv = "60.5 120.5 120.34 120.35 168.42 180.19 240.89 240.90 240.91 240.92 240.93 240.94 240.189 240.190 300.22 336.114 336.208 336.209 360.51 360.118 360.119 360.120 360.121 360.122 420.13 480.217 480.218 480.219 480.220 480.221 480.222 480.943 480.944 480.945 480.946 480.947 480.948 480.949 480.950 480.951 480.952 480.953 480.954 480.955 480.956 480.957 480.958 480.959 480.960 480.1186 480.1187 504.156 504.157".split() # Nonsolvable groups up to 511
def analyze_aut_timing(Nmax=511, basedir=None):
    if basedir is None:
        basedir = os.getcwd()
    autdir = opj(basedir, "aut_test")
    solvdir = opj(basedir, "autsolv_test")
    repdir = opj(basedir, "autrep_test")
    aut = {}
    solv = {}
    rep = {}
    for D, directory in [(aut, autdir), (solv, solvdir), (rep, repdir)]:
        for name in os.listdir(directory):
            with open(opj(directory, name)) as F:
                for line in F:
                    label, t = line.strip().split()
                    D[label] = float(t)
    neither = 0
    sfast = 0
    svfast = 0
    afast = 0
    avfast = 0
    same = 0
    for N in range(1, Nmax+1):
        for i in range(1, ZZ(gap.NrSmallGroups(N))):
            label = "%s.%s" % (N, i)
            if label in nonsolv:
                continue
            # Default is that solv and rep are faster than aut, we include an error margin
            s = solv.get(label, 10000)
            a = aut.get(label, 1000)
            if label not in solv and label not in aut:
                neither += 1
            elif s > 16*a:
                avfast += 1
            elif s > 2*a:
                afast += 1
            elif a > 16*s:
                svfast += 1
            elif a > 2*s:
                sfast += 1
            else:
                same += 1
            if s < 0.4 or (s < 3*a):
                continue
            print(label, solv.get(label, "+++++"), aut.get(label, "+++++"))
    print("Neither finished %s times" % neither)
    print("AutomorphismGroupSolubleGroup much faster %s times" % svfast)
    print("AutomorphismGroupSolubleGroup faster %s times" % sfast)
    print("About the same %s times" % same)
    print("AutomorphismGroup faster %s times" % afast)
    print("AutomorphismGroup much faster %s times" % avfast)

def prep_report(Nmax=511, basedir=None):
    if basedir is None:
        basedir = os.getcwd()
    prepdir = opj(basedir, "RePresentations")
    D = defaultdict(int)
    for name in os.listdir(prepdir):
        if name == "log": continue
        with open(opj(prepdir, name)) as F:
            for line in F:
                t = line.strip().split()[-1][:-1]
                D[floor(float(t))] += 1
    for k, v in sorted(D.items()):
        print("%s-%ss: %s" % (k, k+1, v))

def move_files(Nmax=511, basedir=None):
    if basedir is None:
        basedir = os.getcwd()
    autdir = opj(basedir, "aut_test")
    solvdir = opj(basedir, "autsolv_test")
    repdir = opj(basedir, "autrep_test")
    prepdir = opj(basedir, "RePresentations")
    ctr = 1
    for N in range(1, Nmax+1):
        print(N)
        for i in range(1, ZZ(gap.NrSmallGroups(N))+1):
            for dr in [autdir, solvdir, repdir, prepdir]:
                filename = opj(dr, str(ctr)+".txt")
                if ope(filename):
                    os.rename(filename, opj(dr, "%s.%s" % (N, i)))
            ctr += 1

def description_classification():
    # Should be called in the DATA folder
    if not os.path.abspath(".").endswith("DATA"):
        raise RuntimeError("Must be called in the DATA directory")
    # Classifies the groups we're adding to the database based on source and description type (permutation, pc, matrix group, etc
    # Counts are by abstract isomorphism
    # Note that totals overlap since there are groups in the intersection
    # We have *some* pc presentation for every solvable group, but they're not all optimized
    #primary_columns = ["nTt", "nPermG", "PC", "pMAT", "qMAT", "ZMAT", "Lie", "PC->NMAT", "nPermG->NMAT"] # Add PLie back in?
    columns = ["Total", "Solvable", "Perm", "Mat", "OptimizedPC", "MinPerm"]
    sources = ["SmallGroup", "TransitiveGroup", "LieType", "IntransitiveGroup", "CARAT", "GLq", "GLZN", "Perf", "Chev", "Sporadic", "SmallAut", "PermAut"] # TODO: add PGLC

    matchers = {
        "nTt": re.compile(r"\d+T\d+"),
        "nPermG": re.compile(r"(\d+)Perm[0-9,]+"),
        "PC": re.compile(r"\d+[Pp][Cc][0-9,\-]*"),
        "pMAT": re.compile(r"(\d+),(\d+)MAT[0-9,]+"),
        "qMAT": re.compile(r"(\d+),q(\d+)MAT[0-9,]+"),
        "ZMAT": re.compile(r"\d+,0,\d+MAT[0-9,]+"),
        "Lie": re.compile(r"[A-Za-z]+\([0-9,]+\)"),
        "PLie": re.compile(r"[A-Za-z]+\([0-9,]+\)\-\-[0-9,]+\-\->>P[A-Za-z]+\([0-9,]+\)"),
        "PC->NMAT": re.compile(r"\d+[Pp][Cc][0-9,\-]+\-\-[0-9,]+\-\->\d+,\d+MAT[0-9,]+"),
        "nPermG->NMAT": re.compile(r"\d+Perm[0-9,]+\-\-[0-9,]+\-\->\d+,\d+MAT[0-9,]+"),
        "Perf": re.compile(r"Perf\d+"),
        "Chev": re.compile(r"Chev\d?[BDEFG],\d+,\d+(\-D)?"),
        "SmallAut": re.compile(r"\d+\.\d+\-A"),
        "PermAut": re.compile(r"\d+T\d+\-A"),
    }
    def all_small(label):
        N = ZZ(label.split(".")[0])
        return N <= 2000 and (N <= 500 or N.valuation(2) < 7)
    def sort_key(label):
        N, i = label.split(".")
        if i.isdigit():
            return int(N), int(i)
        return int(N), class_to_int(i)


    by_row = defaultdict(set)
    by_column = defaultdict(set)
    with open("to_add.txt") as F:
        all_labels = [line.strip().split(" ")[0] for line in F]
    by_column["Total"] = set(all_labels)
    by_row["SmallGroup"] = set(label for label in all_labels if all_small(label)) # SmallGroup is only those orders where we load everything from the small group database
    smallsolv = list(db.gps_groups.search({"solvable":True}, "label"))
    by_column["Solvable"] = set(os.listdir("pcreps_fastest") + os.listdir("pcreps_fast") + smallsolv)
    by_column["OptimizedPC"] = set(os.listdir("pcreps") + smallsolv) # Note that this will need to change once the new data is uploaded
    by_column["MinPerm"] = set(os.listdir("minreps"))
    for fname in ["aliases.txt", "mat_aliases.txt"]:
        with open(fname) as F:
            for line in F:
                label, desc = line.strip().split(" ")
                if matchers["nTt"].fullmatch(desc):
                    by_row["TransitiveGroup"].add(label)
                elif matchers["nPermG"].fullmatch(desc):
                    n = int(matchers["nPermG"].fullmatch(desc).group(1))
                    if n <= 15:
                        by_row["IntransitiveGroup"].add(label)
                elif matchers["Lie"].fullmatch(desc):
                    # Maybe add HaveLie?
                    by_row["LieType"].add(label)
                elif matchers["pMAT"].fullmatch(desc):
                    d, N = [ZZ(c) for c in matchers["pMAT"].fullmatch(desc).groups()]
                    if N.is_prime():
                        if d > 2:
                            by_row["GLq"].add(label)
                        else:
                            by_row["GLZN"].add(label)
                    else:
                        by_row["GLZN"].add(label)
                elif matchers["ZMAT"].fullmatch(desc):
                    by_row["CARAT"].add(label)
                elif matchers["qMAT"].fullmatch(desc):
                    d, q = [int(c) for c in matchers["qMAT"].fullmatch(desc).groups()]
                    if d == 2 and q < 100 or d == 3 and q < 10 or d == 4 and q == 4:
                        by_row["GLq"].add(label)
                elif matchers["SmallAut"].fullmatch(desc):
                    by_row["SmallAut"].add(label)
                elif matchers["PermAut"].fullmatch(desc):
                    by_row["PermAut"].add(label)
                elif matchers["Perf"].fullmatch(desc):
                    by_row["Perf"].add(label)
                elif matchers["Chev"].fullmatch(desc):
                    by_row["Chev"].add(label)
                elif desc in ["J1", "J2", "HS", "J3", "McL", "He", "Ru", "Co3", "Co2", "Co1"]:
                    by_row["Sporadic"].add(label)
                else:
                    print("Unknown description", desc)
                    raise ValueError
    for label in os.listdir("preload"):
        with open(opj("preload", label)) as F:
            lines = [line.split("|") for line in F.read().strip().split("\n")]
            ldata = dict(zip(lines[0], lines[1]))
            reps = ldata["representations"]
            if '"Perm"' in reps:
                by_column["Perm"].add(label)
            if '"PC"' in reps:
                by_column["Solvable"].add(label)
            if any(f'"{typ}"' in reps for typ in ["Lie", "GLZ", "GLZq", "GLFq", "GLFp", "GLZN"]):
                by_column["Mat"].add(label)
    with open("TinyLie.txt") as F:
        for line in F:
            label, desc = line.strip().split(" ")
            by_row["LieType"].add(label)
    for i in range(1, len(sources)):
        for j in range(i):
            by_row[sources[i]] = by_row[sources[i]].difference(by_row[sources[j]])

    # Now we add column data for primary description
    # descs = {}
    # for label in os.listdir("descriptions"):
    #     with open(opj("descriptions", label)) as F:
    #         desc = F.read().strip().split("\n")[0] # FIXME!
    #         descs[label] = desc
    #     for name in primary_columns:
    #         matcher = matchers[name]
    #         m = matcher.fullmatch(desc)
    #         if m:
    #             if name == "unspec":
    #                 by_column[name].add((label, desc))
    #             else:
    #                 if name == "pMAT":
    #                     p = ZZ(m.group(2))
    #                     assert p.is_prime()
    #                 by_column[name].add(label)
    #             break
    #     else:
    #         by_column["other"].add((label, desc))
    # for name in matchers:
    #     v = by_column[name]
    #     if v:
    #         if name not in ["other", "unspec"]:
    #             v = sorted(v, key=sort_key)
    #             print(name, len(v), v[0])
    #         else:
    #             print(name, len(v))

    print("| Source | " + " | ".join(columns) + " |")
    print("| --- | " + " | ".join("---" for col in columns) + " |")
    for source in sources:
        print(f"| {source} | " + " | ".join(f"{len(by_row[source].intersection(by_column[col]))}" for col in columns) + " |")

    return all_labels, sources, columns, by_row, by_column
