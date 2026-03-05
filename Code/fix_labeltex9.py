# Check description files
from description_conversion import representation_to_description
import re

pcredo = set()
with open("/home/roed/pcfixed.txt") as F:
    for line in F:
        pcredo.add(line.split("|")[0])

bad_desc = []
trans_desc = []
nt_re = re.compile(r"(\d+)T\d+")
perm_re = re.compile(r"(\d+)Perm[\d,]+")
for rec in db.gps_groups.search({}, ["label", "order", "element_repr_type", "representations"]):
    label = rec["label"]
    ert = rec["element_repr_type"]
    db_desc = representation_to_description(rec["order"], rec["representations"], ert)
    with open("DATA/descriptions/"+label) as F:
        file_desc = F.read().strip()
    if db_desc != file_desc:
        if label in pcredo:
            continue
        #if ert in ["GLZN", "GLZq"] and file_desc.startswith(db_desc + "--"):
        if ert in ["GLZN", "GLZq"] and file_desc.endswith("-->" + db_desc):
            continue
        if ert == "Lie" and db_desc[0] == "P" and file_desc.endswith("-->>" + db_desc):
            continue
        if ert == "Perm":
            mnt = nt_re.fullmatch(file_desc)
            mperm = perm_re.fullmatch(db_desc)
            if mnt and mperm and mnt.group(1) == mperm.group(1):
                trans_desc.append((label, db_desc, file_desc))
                continue
        bad_desc.append((label, db_desc, file_desc))
