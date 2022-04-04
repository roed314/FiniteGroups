# Convert output from CARAT's Q_catalog function into our string format

from sage.all import ZZ
from collections import defaultdict

def load_file(filename, bigfile=None, mediumfile=None, smallfile=None):
    groups = defaultdict(list)
    with open(filename) as F:
        reported = True
        for line in F:
            if line[0] == "#":
                # gives number of generators
                if not reported:
                    print(f"No order shown for {dim}, {entries}")
                ngens = ZZ(line[2:].strip())
                toread = 0
                dim = None
                entries = []
                reported = False
                continue
            if "=" in line:
                if reported:
                    raise RuntimeError(f"Two orders given")
                if len(entries) != ngens * dim:
                    raise RuntimeError(f"Incorrect number of entries: {len(entries)} but should be {ngens * dim}")
                order = ZZ(line.split("=")[1].split("%")[0].strip())
                big = (order > 2000 or order == 1024)
                medium = (order in [512, 1536])
                small = (order in [128*k for k in [5,6,7,9,10,11,13,14,15]])
                s = f"{dim},0Mat{','.join(entries)}"
                if big and bigfile is not None or medium and mediumfile is not None or small and smallfile is not None:
                    entries = [entries[i*dim**2:(i+1)*dim**2] for i in range(ngens)]
                    entries = [[mat[i*dim:(i+1)*dim] for i in range(dim)] for mat in entries]
                    G = libgap.Group(entries)
                    if not (G.IsSimple() or G.IsPerfect() and order <= 50000):
                        if small:
                            label = ".".join(str(c) for c in G.IdGroup())
                            with open(smallfile, "a") as Fout:
                                _ = Fout.write(label + "\n")
                        elif medium:
                            with open(mediumfile, "a") as Fout:
                                _ = Fout.write(s + "\n")
                        elif big:
                            with open(bigfile, "a") as Fout:
                                _ = Fout.write(s + "\n")
                groups[order].append(s)
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
