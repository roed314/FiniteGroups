import os
import itertools
from collections import defaultdict
ope = os.path.exists
opj = os.path.join

def collate(folder):
    # Naming conventions:
    # Big*.hashed -- lines contain pairs `desc ordhash`, where `desc` can be fed into StringToGroup
    #                and `ordhash` takes the form `N.hsh` where N is the order of the group and hsh is the hash.
    # Big*.unhashed -- lines contain pairs `desc order`, as above but without the hash
    # Small*.txt and Medium*.identified -- lines contain a small group id (generally of one of the skipped orders 512, 640, 768,...
    # Skipped.orders -- lines contain orders of groups that could not be hashed (not identifiable or 512,1152,1536,1920)
    # Other files are ignored

    # Output:
    # - creates a file `Smed.txt` containing small group ids without duplicates
    # - creates a folder `active`, and a file within it for each ordhash that has more than one group; each line of the file has the description of a group with that ordhash.
    # - creates a folder `done`, and a file within it for each ordhash with only one group (and for each unhashed group with an order that did not otherwise exist)
    # - creates a file `Problems.txt` containing pairs `desc order` of unhashed groups where the order is not unique

    smedfile = opj(folder, "Smed.txt")
    probfile = opj(folder, "Problems.txt")
    active = opj(folder, "active")
    done = opj(folder, "done")
    if ope(smedfile): raise ValueError("Smed.txt already exists")
    if ope(probfile): raise ValueError("Problems.txt already exists")
    if ope(active): raise ValueError("active already exists")
    if ope(done): raise ValueError("done already exists")
    os.mkdir(active)
    os.mkdir(done)
    smed = set()
    big = defaultdict(list)
    orders = set()
    unhashed = defaultdict(list)
    for ifile in os.listdir(folder):
        if (ifile.startswith("Small") and ifile.endswith(".txt") or
            ifile.startswith("Medium") and ifile.endswith(".identified")):
            with open(opj(folder, ifile)) as F:
                for line in F:
                    line = line.strip()
                    if line:
                        smed.add(line)
        elif ifile.startswith("Big") and ifile.endswith(".hashed"):
            with open(opj(folder, ifile)) as F:
                for line in F:
                    line = line.strip()
                    if line:
                        desc, ordhash = line.split()
                        order, hash = ordhash.split(".")
                        big[ordhash].append(desc)
                        orders.add(order)
        elif ifile.startswith("Big") and ifile.endswith(".unhashed"):
            with open(opj(folder, ifile)) as F:
                for line in F:
                    line = line.strip()
                    if line:
                        desc, order = line.split()
                        unhashed[order].append(desc)
    smed = sorted(smed, key=lambda x: [int(c) for c in x.split(".")])
    with open(smedfile, "w") as F:
        _ = F.write("\n".join(smed)+"\n")
    unh_ok = {}
    unh_probs = []
    for order, V in unhashed.items():
        if len(V) == 1 and order not in orders:
            unh_ok[order] = V
        else:
            for desc in V:
                unh_probs.append(f"{desc} {order}")
    for ordhash, V in itertools.chain(big.items(), unh_ok.items()):
        ofile = opj(done, ordhash) if len(V) == 1 else opj(active, ordhash)
        with open(ofile, "w") as F:
            _ = F.write("\n".join(V)+"\n")
    if unh_probs:
        with open(probfile, "w") as F:
            _ = F.write("\n".join(unh_probs)+"\n")
