import os
opj = os.path.join
ope = os.path.exists
from collections import defaultdict

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
