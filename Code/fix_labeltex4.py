
from collections import defaultdict
from pathlib import Path
from sage.databases.cremona import class_to_int, cremona_letter_code
from sage.all import ZZ

tnames = ["gps_groups", "gps_subgroups", "gps_conj_classes", "gps_char", "gps_qchar"]
ambs = ["label", "ambient", "group", "group", "group"]
label_col = dict(zip(tnames, ambs))

def gg(label):
    N, i = label.split(".")
    if i.isdigit():
        return (N, i)
    return (N, str(1+class_to_int(i)))

PCFIX = Path("/scratch/grp/pcfix/")
pcfix = defaultdict(lambda: defaultdict(list))
for fname in PCFIX.iterdir():
    tname = fname.name.split(".")[0]
    with open(fname) as F:
        for i, line in enumerate(F):
            cols = line.strip().split("|")
            if i == 0:
                header = cols
            elif i > 2:
                D = dict(zip(header, cols))
                group = D[label_col[tname]]
                pcfix[tname][group].append(D)
pctodo = set(pcfix["gps_groups"])
pctodo.update([gg(label) for label in pctodo])

TEXFIX = Path("/scratch/grp/texfix")
for oldname, newname, tname, lname in [
        ("OrigTexNames.txt", "UpdatedTexNames.txt", "gps_groups", "tex_name"),
        ("OrigSubTexNames.txt", "UpdatedSubTexNames.txt", "gps_subgroups", "subgroup_tex"),
        ("OrigQuoTexNames.txt", "UpdatedQuoTexNames.txt", "gps_subgroups", "quotient_tex"),
]:
    pcadded = set()
    with open(TEXFIX / newname, "w") as Fout:
        with open(TEXFIX / oldname) as F:
            for line in F:
                label = line.split("|")[0]
                ambient = ".".join(label.split(".")[:2])
                if ambient in pctodo:
                    if ambient not in pcadded:
                        for D in pcfix[tname][ambient]:
                            _ = Fout.write(f"{D['label']}|{D[lname]}\n")
                        pcadded.add(ambient)
                else:
                    _ = Fout.write(line)

def order_factorization_type(N):
    fac = ZZ(N).factor()
    if len(fac) == 0:
        return "0"
    elif len(fac) == 1:
        p, e = fac[0]
        if e in [1,2]:
            return str(e)
        if e >= 7:
            return "7"
        return "3"
    m = min(e for (p,e) in fac)
    M = max(e for (p,e) in fac)
    if M == 1:
        return "11"
    if len(fac) == 2:
        if M == 2:
            return "22"
        if m == 1:
            if M < 5:
                return "31"
            return "51"
        if m == 2:
            return "32"
        return "33"
    if M == 2:
        return "222"
    if len([e for (p,e) in fac if e == 1]) == 2:
        return "311"
    return "321"

def adjust_line(D, tname, header):
    if tname in ["gps_conj_classes", "gps_char"]:
        D["group_order"], i = D["group"].split(".")
        if i.isdigit():
            D["group_counter"] = i
        else:
            D["group_counter"] = str(1 + class_to_int(i))
        if tname == "gps_char":
            center = D["center"]
            D["center_index"] = center.split(".")[0]
            if center == r"\N":
                D["center_order"] = r"\N"
            else:
                D["center_order"] = str(ZZ(D["group_order"]) // ZZ(D["center_index"]))
            kernel = D["kernel"]
            if kernel == r"\N":
                D["kernel_order"] = D["image_isoclass"] = D["image_order"] = r"\N"
            else:
                for E in pcfix["gps_subgroups"][D["group"]]:
                    if E["short_label"] == kernel:
                        break
                if E["short_label"] == kernel:
                    D["image_isoclass"] = E["quotient"]
                    D["image_order"] = E["quotient_order"]
                    D["kernel_order"] = E["subgroup_order"]
                else:
                    D["kernel_order"] = D["image_isoclass"] = D["image_order"] = r"\N"
    elif tname == "gps_qchar":
        D["group_order"] = D["group"].split(".")[0]
    elif tname == "gps_groups":
        D["order_factorization_type"] = order_factorization_type(D["order"])
    return "|".join(D.get(col, r"\N") for col in header) + "\n"

BIGFIX = Path("/scratch/grp/bigfix")
for tname, amb in zip(tnames, ambs):
    pcadded = set()
    with open(BIGFIX / f"{tname}1.txt", "w") as Fout:
        with open(BIGFIX / f"{tname}.txt") as F:
            for i, line in enumerate(F):
                cols = line.strip().split("|")
                if i == 0:
                    header = cols
                    if tname == "gps_conj_classes":
                        a, b = cols.index("group_order"), cols.index("group_counter")
                        def getter(cc):
                            return (cc[a], cc[b])
                    else:
                        ambloc = cols.index(amb)
                        def getter(cc):
                            return cc[ambloc]
                if i > 2 and getter(cols) in pctodo:
                    ambient = getter(cols)
                    if isinstance(ambient, tuple):
                        ambient = f"{ambient[0]}.{ambient[1]}"
                    if ambient not in pcadded:
                        for D in pcfix[tname][ambient]:
                            _ = Fout.write(adjust_line(D, tname, header))
                        pcadded.add(ambient)
                else:
                    _ = Fout.write(line)
