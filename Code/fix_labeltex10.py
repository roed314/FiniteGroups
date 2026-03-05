
import re
import time
from collections import defaultdict
opj = os.path.join
time_extractor = re.compile(r"^Finished ([A-Za-z\-]+) in ([\d\.]+)")
timing_data = defaultdict(lambda: defaultdict(list))

t0 = time.time()
for folder in os.listdir("/scratch/grp/"):
    print(f"Starting {folder} at time {time.time()-t0}")
    def process_file(path):
        with open(path) as F:
            for line in F:
                code = line[0]
                if code == "T":
                    ambient, data = line[1:].split("|",1)
                    m = time_extractor.match(data)
                    if m:
                        ambient = ambient.split("(")[0]
                        timing_data[ambient][m.group(1)].append(float(m.group(2)))
    if any(folder.startswith(h) for h in ["15", "60", "fixsmall", "highmem", "lowmem", "noaut", "sopt", "tex", "last"]):
        for sub in os.listdir(opj("/scratch/grp/",folder)):
            if sub == "raw":
                for fname in os.listdir(opj("/scratch/grp/",folder, "raw")):
                    if fname.startswith("grp-") and fname.endswith(".txt"):
                        process_file(opj("/scratch/grp", folder, "raw", fname))
            elif sub.startswith("output"):
                process_file(opj("/scratch/grp", folder, sub))
    elif folder == "Xrun":
        for label in os.listdir("/scratch/grp/Xrun/TE"):
            process_file(opj("/scratch/grp/Xrun/TE", label))
