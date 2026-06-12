
from collections import defaultdict, Counter
opj = os.path.join
from sage.databases.cremona import cremona_letter_code, class_to_int
from sage.misc.cachefunc import cached_function
from sage.all import ZZ, gcd
import re
canre = re.compile("[a-z]+[0-9]+")
conjre = re.compile("[A-Z]+")

sys.path.append("/home/roed/lmfdb")
from lmfdb import db

def long_to_short(label):
    return ".".join(label.split(".")[2:])

def label_is_canonical(short_label):
    pieces = short_label.split(".")
    return all(canre.fullmatch(x) for x in pieces[1:])

def label_is_conj(pieces):
    return len(pieces) == 2 and conjre.fullmatch(pieces[1])

def label_sortkey(label):
    L = []
    for piece in label.split("."):
        for i, x in enumerate(re.split(r"(\D+)", piece)):
            if x:
                if i % 2:
                    x = class_to_int(x.lower())
                else:
                    x = int(x)
                L.append(x)
    return L

@cached_function
def is_pp(n):
    return n.is_prime_power()

def create_rename_file():
    base = "/scratch/grp/newer_collated"
    redo = set(os.listdir("/scratch/grp/replace_collated")+os.listdir("/scratch/grp/bad47"))
    R = defaultdict(dict)
    B = defaultdict(dict)
    print("Setting oe and sib")
    oe = {}
    sib = {}
    for rec in db.gps_groups.search({}, ["label", "outer_equivalence", "subgroup_index_bound"]):
        oe[rec["label"]] = rec["outer_equivalence"]
        sib[rec["label"]] = rec["subgroup_index_bound"]
    print("Filling RB")
    nulls = set()
    new_indctr = defaultdict(Counter)
    for ambient in os.listdir(base):
        with open(opj(base, ambient)) as F:
            for line in F:
                if line[0] == "R":
                    new_label, old_label = line[1:].strip().split("|")
                    ind = int(new_label.split(".")[2])
                    if ind <= sib[ambient]:
                        new_indctr[ambient][ind] += 1
                    if old_label == r"\N":
                        nulls.add(ambient)
                        continue
                    assert new_label.startswith(ambient) and old_label.startswith(ambient)
                    R[ambient][long_to_short(old_label)] = long_to_short(new_label)
                elif line[0] == "B":
                    new_label, data = line[1:].strip().split("|",1)
                    assert new_label.startswith(ambient)
                    B[ambient][long_to_short(new_label)] = data
    indctr = defaultdict(Counter)
    print("Computing indctr")
    all_labels = defaultdict(lambda: defaultdict(list))
    with open("gps_subgroups.txt") as F:
        for i, line in enumerate(F):
            cols = line.strip().split("|")
            if i == 0:
                head = cols
                ambi = head.index("ambient")
                indi = head.index("quotient_order")
                labeli = head.index("label")
            elif i > 2:
                ind = int(cols[indi])
                amb = cols[ambi]
                if ind <= sib[amb]:
                    indctr[amb][ind] += 1
                all_labels[amb][ind].append(cols[labeli])
    problems = set(nulls)
    for ambient, D in new_indctr.items():
        for ind, c in D.items():
            if c != indctr[ambient][ind]:
                problems.add(ambient)
                break
    print("Sorting")
    for D in all_labels.values():
        for L in D.values():
            L.sort(key=label_sortkey)
    counter = defaultdict(Counter)
    def newname(label):
        # The label in the recent computation run, even if we won't be using it
        pieces = label.split(".")
        ambient = ".".join(pieces[:2])
        short_label = ".".join(pieces[2:])
        if short_label in R[ambient]:
            return ambient + "." + R[ambient][short_label]
        return r"\N"
    def rename(label):
        # The new label that we'll actually be using
        pieces = label.split(".")
        ambient = ".".join(pieces[:2])
        short_label = ".".join(pieces[2:])
        if ambient not in problems and short_label in R[ambient]:
            candidate = R[ambient][short_label]
            if label_is_canonical(candidate):
                return f"{ambient}.{candidate}"
        N = ZZ(pieces[0])
        index = ZZ(pieces[2])
        if index in [1,N] or (is_pp(N // index) and gcd(index, N // index) == 1) or indctr[ambient][index] == 1:
            if oe[ambient]:
                return f"{ambient}.{index}.a1"
            else:
                return f"{ambient}.{index}.a1.a1"
        if label_is_conj(pieces[2:]):
            return label
        i = counter[ambient][index]
        counter[ambient][index] += 1
        i = cremona_letter_code(i)
        if not oe[ambient]:
            i = i.upper()
        return f"{ambient}.{index}.{i}"
    print("Renaming")
    with open("sub_relabel.txt", "w") as F:
        for j, ambient in enumerate(sorted(all_labels, key=label_sortkey)):
            if j and j % 10000 == 0:
                print(j)
            if ambient in redo:
                continue
            D = all_labels[ambient]
            for ind in sorted(D):
                L = D[ind]
                for label in L:
                    _ = F.write(f"{label}|{newname(label)}|{rename(label)}\n")
    return nulls, problems, indctr, new_indctr, B
