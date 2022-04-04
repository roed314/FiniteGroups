# Convert output from CARAT's Q_catalog function into our string format

from sage.all import ZZ
from collections import defaultdict

def load_file(filename):
    groups = defaultdict(list)
    with open(filename) as F:
        reported = True
        for line in F:
            if line[0] == "#":
                # gives number of generators
                if not reported:
                    print(f"No order shown for {dim}, {entries}")
                s = ""
                toread = 0
                dim = None
                entries = []
                reported = False
                continue
            if "=" in line:
                if reported:
                    raise RuntimeError(f"Two orders given")
                order = ZZ(line.split("=")[1].split("%")[0].strip())
                groups[order].append(f"{dim},0Mat{','.join(entries)}")
                reported = True
                continue
            if toread == 0:
                n = int(line[0]) # All dimensions are one digit
                if dim is None:
                    dim = n
                elif dim != n:
                    raise RuntimeError(f"Dimension mismatch: {dim} vs {n}")
                toread = n
                continue
            entries.extend(line.strip().split())
            toread -= 1
    return groups
