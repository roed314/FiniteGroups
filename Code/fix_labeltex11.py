
from pathlib import Path
from collections import defaultdict, Counter

subgroup_rename = defaultdict(dict)
#collated = defaultdict(lambda: defaultdict(list))
counts = defaultdict(lambda: defaultdict(Counter))
#cc_count = defaultdict(Counter)
#char_count = defaultdict(Counter)
#qchar_count = defaultdict(Counter)
def load_file(fname, fid):
    collated = defaultdict(lambda: defaultdict(list))
    with open(fname) as F:
        for line in F:
            code = line[0]
            if code not in "TE":
                label, data = line[1:].split("|", 1)
                if code == "B" and label in "tf":
                    # Bug in first run; have to throw away this data
                    continue
                if code == "R":
                    label = ".".join(label.split(".")[:2])
                if code in "JQCR":
                    counts[code][label][fid] += 1
                collated[code][label].append(line)
    base = Path("/scratch/grp/new_collated")
    for code, V in collated.items():
        for label, lines in V.items():
            pth = base / f"Code{code}" / label
            pth.mkdir(parents=True, exist_ok=True)
            with open(pth / fid, "w") as Fout:
                _ = Fout.write("".join(lines))

fbase = Path("/scratch/grp")
for fname in ["relabel.output", "relabel1.output", "relabel2.output"]:
    print(fname)
    load_file(fbase / fname, fname.split(".")[0])
for folder in ["new_30minrun", "new_60minrun"]:
    print(folder)
    fold = folder.split("_")[1]
    for fname in (fbase / folder).iterdir():
        if fname.name.endswith(".txt"):
            load_file(fname, fold)
