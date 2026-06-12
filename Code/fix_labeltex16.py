#!/usr/bin/env -S sage -python

from pathlib import Path
if "/home/roed/lmfdb" not in sys.path:
    sys.path.append("/home/roed/lmfdb")
from lmfdb import db
from sage.all import ZZ
from collections import defaultdict

def fix_direct(gps, subs):
    gps = {rec["label"]: rec for rec in gps}
    by_ambient = defaultdict(lambda: defaultdict(list))
    for rec in subs:
        if rec["normal"]:
            sord, qord = rec["subgroup_order"], rec["quotient_order"]
            if sord != 1 and qord != 1 and ZZ(sord).gcd(ZZ(qord)) == 1:
                by_ambient[rec["ambient"]][rec["subgroup_order"]].append(rec)
    for amb, D in by_ambient.items():
        for sord in list(D):
            for rec in D[sord]:
                if D[rec["quotient_order"]]: # There is a normal subgroup of the complementary, coprime order
                    rec["direct"] = True
                    gps[amb]["direct_product"] = True

def unbooler(b):
    if b is None:
        return r"\N"
    return "t" if b else "f"

def collate_latex():
    from cloud_collect import get_tex_data_gps, get_tex_data_subs, get_good_names, parse
    manual_tex = {
        "600.149": "F_{25}",
        "702.47": "F_{27}",
        "992.194": "F_{32}",
        "2352.b": "F_{49}",
        "4032.n": "F_{64}",
        "6480.a": "F_{81}",
        "14520.b": "F_{121}",
        "15500.d": "F_{125}",
        "16256.19325": "F_{128}",
        "28392.a": "F_{169}",
        "37056.a": "F_{193}",
        "58806.b": "F_{243}",
        "65280.a": "F_{256}",
        "65792.1118964": "F_{257}",
        "83232.a": "F_{289}",
        "103680.b": "\\GSp(4,3)",
        "117306.b": "F_{343}",
        "129960.a": "F_{361}",
        "187056.a": "F_{433}",
        "201152.a": "F_{449}",
        "2937600.a": "\\GSp(4,4)",
        "7396945920.a": "\\GSp(4,8)",
        "12318179328000.a": "\\GSp(6,4)",
        "17971200.a": "{}^2F(4,2)'",
    }
    base = Path("/scratch/grp")
    gptex = {}
    subtex = {}
    quotex = {}
    vtex = {}
    for path in (base / "tex_out").iterdir():
        ambient = path.name
        with open(path) as F:
            for line in F:
                if "|" in line:
                    label, code, t = line.strip().split("|")
                    if code == "S":
                        subtex[label] = t
                    else:
                        assert code == "Q"
                        quotex[label] = t
                elif ambient in manual_tex:
                    gptex[ambient] = manual_tex[ambient]
                else:
                    gptex[ambient] = line.strip()
    for path in (base / "vtex_out").iterdir():
        with open(path) as F:
            vtex[path.name] = F.read().strip()
    gpsource = list(db.gps_groups.search({}, ["label", "name", "representations", "order", "cyclic", "abelian", "smith_abelian_invariants", "direct_product", "direct_factorization", "wreath_data", "aut_tex", "outer_tex", "inner_tex", "autcent_tex", "autcentquo_tex", "aut_group", "outer_group", "central_quotient", "autcent_group", "autcentquo_group"]))
    for rec in gpsource:
        if rec["label"] in gptex:
            rec["tex_name"] = gptex[rec["label"]]

    subsource = list(db.gps_subgroup_search.search({}, ["label", "subgroup", "ambient", "quotient", "subgroup_order", "quotient_order", "split", "direct", "normal", "abelian", "quotient_abelian"]))
    for rec in subsource:
        label, slabel, qlabel = rec["label"], rec["subgroup"], rec["quotient"]
        rec["short_label"] = ".".join(label.split(".")[2:])
        if label in subtex:
            stex = subtex[label]
        elif slabel in gptex:
            stex = gptex[slabel]
        elif slabel in vtex:
            stex = vtex[slabel]
        else:
            raise RuntimeError
        if rec["normal"]:
            if label in quotex:
                qtex = quotex[label]
            elif qlabel in gptex:
                qtex = gptex[qlabel]
            elif qlabel in vtex:
                qtex = vtex[qlabel]
            else:
                raise RuntimeError
        else:
            qtex = None
        rec["ambient_tex"] = gptex[rec["ambient"]]
        rec["subgroup_tex"] = stex
        rec["quotient_tex"] = qtex

    print("Fixing direct")
    fix_direct(gpsource, subsource)
    print("Direct fixed")

    tex_names, orig_tex_names, orig_names, options, by_order, wreath_data, direct_data, cyclic, finalized, oneoff, update, borked = get_tex_data_gps(gpsource=gpsource)

    # Add options from special_names
    fam_lookup = {rec["family"]: rec["tex_name"] for rec in db.gps_families.search({}, ["family", "tex_name"])}
    for rec in db.gps_special_names.search({}, ["family", "label", "parameters"]):
        if rec["family"].startswith("Cox"):
            # Know that some of these are wreath products
            fam = rec["parameters"].get("fam")
            n = rec["parameters"]["n"]
            if fam == "B" and n > 3:
                tname = fr"C_2\wr S_{{{n}}}"
            elif fam == "D" and n > 3:
                tname = fr"C_2^{{{n-1}}}:S_{{{n}}}"
            else:
                continue
        elif rec["family"] not in ["Dic", "Sporadic"]:
            tname = fam_lookup[rec["family"]].format(**rec["parameters"])
        options[label][tname] = parse(tname)

    # also updates options
    subs, wd_lookup = get_tex_data_subs(orig_tex_names, wreath_data, options, by_order, oneoff, update, borked, subsource=subsource)

    # also updates tex_names
    ties = get_good_names(tex_names, options, by_order, wreath_data, wd_lookup, direct_data, cyclic, finalized, subs, borked)

    with open(base / "tex_gps_groups.update", "w") as Fout:
        cols = "label|tex_name|name|aut_tex|outer_tex|inner_tex|autcent_tex|autcentquo_tex|direct_product"
        _ = Fout.write(cols + "\ntext|text|text|text|text|text|text|text|boolean\n\n")
        cols = cols.split("|")
        for rec in gpsource:
            new = tex_names[rec["label"]]
            rec["tex_name"] = new.latex_to_file
            rec["name"] = new.plain
            for typ in ["aut", "outer", "inner", "autcent", "autcentquo"]:
                if typ == "inner":
                    lcol = "central_quotient"
                else:
                    lcol = typ + "_group"
                tcol = typ + "_tex"
                alab, atex = rec[lcol], rec[tcol]
                if alab is None:
                    if atex is None:
                        rec[tcol] = r"\N"
                    elif atex in oneoff[typ]:
                        rec[tcol] = oneoff[typ][atex]
                elif alab in tex_names:
                    new = tex_names[alab]
                    rec[tcol] = new.latex_to_file
                elif atex is None:
                    rec[tcol] = r"\N"
            vals = [rec[col] for col in cols]
            vals[-1] = unbooler(vals[-1])
            _ = Fout.write("|".join(vals) + "\n")
    with open(base / "tex_gps_subgroup_search.update", "w") as Fout:
        cols = "label|ambient_tex|subgroup_tex|quotient_tex|direct"
        _ = Fout.write(cols + "\ntext|text|text|text|boolean\n\n")
        cols = cols.split("|")
        for rec in subsource:
            rec["ambient_tex"] = tex_names[rec["ambient"]].latex_to_file
            for typ, label, tex in [("subgroup", rec["subgroup"], rec["subgroup_tex"]),
                                    ("quotient", rec["quotient"], rec["quotient_tex"])]:
                tcol = typ + "_tex"
                if label in tex_names:
                    rec[tcol] = tex_names[label].latex_to_file
                else:
                    assert label is None
                    if tex is None:
                        rec[tcol] = r"\N"
                    elif tex in oneoff[typ]:
                        rec[tcol] = oneoff[typ][tex]
            vals = [rec[col] for col in cols]
            vals[-1] = unbooler(vals[-1])
            _ = Fout.write("|".join(vals) + "\n")
