#!/usr/bin/env -S sage -python

"""
This script is used to add new groups to the LMFDB.  It takes as input a file containing descriptions of groups to add, and carries out several steps in preparation for adding these groups to the LMFDB.  Configuration options (such as runtime limits) are controlled by the config.ini file in this folder, and can also be overridden using command line arguments.

This script is intended to be run on a single server using multiple cores.  If the number of groups being added is sufficiently large, it may be helpful to use the cloud_* framework instead.

Steps:

0. Extract necessary data into DATA/descriptions/, DATA/hash_lookup/, DATA/subhash_lookup, DATA/quohash_lookup from the LMFDB (if not already present).  These will be regenerated if the number of files in the DATA/descriptions folder is less than db.gps_groups.count(), indicating that groups have been added on another server.
1. Compute orders and hashes for the groups to be added.
2. Divides input groups into isomorphism classes and assigns labels.  There is now a file available with the labels for all the input groups (new or old). Updates the local folders DATA/descriptions and DATA/hash_lookup with the newly added groups.  This is the only step that interacts with the LabelingLock.
3. Computes MinimalDegreePermutationRepresentation (via MinReps4.m)
4. Computes PCGenerators (via PCreps.m)
5. Sets preload (see create_descriptions.py for more details).
6. Creates DATA/manifest and DATA/ncores appropriately, then executes cloud_parallel.py
7. Imports appropriate functions from cloud_collect and executes them to generate upload files
8. Uploads data from these files into the relevant LMFDB tables.

By default, these steps are all run automatically, but you can select them individually using --steps, or omit steps using various --skip-<STEP> options

File structure:

* DATA/additions/<NAME>/input is the input file, containing one group description per line.  NAME is passed as a positional argument to this script, and additional preload items can be included using space separated key=value pairs on the same line (these pairs are used to augment other information computed in steps 1-4 in creating preload files for the new groups)
* DATA/additions/<NAME>/ordhash is generated in step 1, and contains orders and hashes for the input groups.  It can be created manually in case hashes have already been computed
* DATA/additions/<NAME>/labels is generated in step 2, and contains labels for the input groups in the same order as the inputs (some may be labels already in the database, others new labels for groups that need to be added)
* DATA/additions/<NAME>/new is generated in step 2, and contains the labels that are new to the database.
* DATA/additions/<NAME>/id_fail is generated in step 2, and contains the descriptions where an error or timeout prevented a definative label from being assigned.
* DATA/additions/<NAME>/gps_groups.new is generated in step 7 and is used in db.gps_groups.copy_from in step 8
* DATA/additions/<NAME>/gps_groups.update is generated in step 7 and is used in db.gps_groups.update_from_file in step 8 (adding labels for commutator subgroups, etc, in existing groups
* DATA/additions/<NAME>/gps_subgroups.new is generated in step 7 and is used in db.gps_subgroups.copy_from in step 8
* DATA/additions/<NAME>/gps_subgroups.update is generated in step 7 and is used in db.gps_subgroups.update_from_file in step 8 (adding labels for subgroups and quotients when they gain a label)
* DATA/additions/<NAME>/gps_groups_cc.new is generated in step 7 and is used in db.gps_groups_cc.copy_from in step 8
* DATA/additions/<NAME>/gps_char.new is generated in step 7 and is used in db.gps_char.copy_from in step 8
* DATA/additions/<NAME>/gps_char.update is generated in step 7 and is used in db.gps_char.update_from_file in step 8 (updating image_isoclass)
* DATA/additions/<NAME>/gps_qchar.new is generated in step 7 and is used in db.gps_qchar.copy_from in step 8
* DATA/additions/lock is a lockfile used to store information about ongoing computations.  It is created and deleted during step 2.

* DATA/descriptions/ is used to store descriptions of groups as a function of label; this folder is created from the contents of the gps_ tables in the LMFDB, and is updated by this script as new groups are added
* DATA/hash_lookup/ is used to index groups by their hash value for easier identification
* DATA/subhash_lookup/ is used to index unidentified subgroups by their hash value, so that when new groups are added the new label can be included in the subgroup table
* DATA/quohash_lookup/ is used to index unidentified quotient groups by their hash value, so that when new groups are added the new label can be included in the subgroup table
* DATA/minrep.todo/ and DATA/minreps/ and DATA/minrep.timings/ are used for new groups in computing a minimal degree permutation
* DATA/pcrep.todo/ and DATA/pcreps/ and DATA/pcrep.timings/ are used for new solvable groups in computing a human-adapted pc representation
* DATA/preload/ is used to store information computed about the new groups in these initial stages (hash, transitive_degree, permutation_degree, linQ_degree, pc_rank, element_repr_type, representations, aut_group, aut_order.  Additional preload items can be specified in the input file.
* DATA/manifest and DATA/ncores are overwritten to provide input for the cloud_parallel.py script

Parallelism:

Parts of step 2 cannot be executed in parallel, and different processes running this script will be blocked to run one at a time.  Running this script on multiple servers should not be done, since it risks having isomorphic groups added with different labels.
"""

import os
# Pathlib is superb, but its primary benefit is code readability (and writeability). Not raw performance on unmanageably extreme numbers of files.  We use it, but fall back on os.scandir in some cases.
from pathlib import Path
import sys
import shutil
import subprocess
import time
import argparse
from collections import Counter, defaultdict
from sage.all import cached_method, magma
from sage.database.cremona import cremona_letter_code
sys.path.append(os.path.expanduser("~/lmfdb"))
from lmfdb import db

# TODO: Add help text to all arguments
parser = argparse.ArgumentParser(description='Add abstract groups to the LMFDB')
parser.add_argument("name")
def parse_steps(steps):
    return sorted(int(c) for c in steps)
parser.add_argument("-s", "--steps", type=parse_steps, default=list(range(10)))
parser.add_argument("--status", action='store_true')
parser.add_argument("--skip-local-add", action='store_true')
parser.add_argument("--skip-perm", action='store_true')
parser.add_argument("--skip-pc", action='store_true')
parser.add_argument("--skip-compute", action='store_true')
parser.add_argument("--skip-upload", action='store_true')

parser.add_argument("--assume-new", action='store_true')
parser.add_argument("--assume-distinct", action='store_true')
parser.add_argument("--id-only", action='store_true')

class LabelingLock:
    # This lock should always be acquired through the acquire_lock method on the Runner,
    # since that has a loop to wait for the lock file to be deleted.
    def __init__(self, runner):
        self.runner = runner

    def __enter__(self):
        assert not self.runner.LOCK.exists()
        with open(self.runner.LOCK, "w") as F:
            _ = F.write(self.runner.name)
        self.runner.has_lock = True
    def __exit__(self, type, value, traceback):
        with open(self.runner.LOCK) as F:
            lock_contents = F.read()
        if lock_contents != self.runner.name:
            raise RuntimeError(f"Lockfile was reset by another process; current name is {lock_contents}")
        self.runner.LOCK.unlink()
        self.runner.has_lock = False
        if hasattr(self.runner, "big_orders"):
            # Without the lock, another process could invalidate this stored attribute, screwing up labels
            delattr(self.runner, "big_orders")

class Runner:
    LOCK = Path("DATA", "additions", "lock")
    DESC = Path("DATA", "descriptions")
    HASH = Path("DATA", "hash_lookup")

    def __init__(self, args):
        self.__dict__.update(vars(args)) # Sets name and steps, along with various skip_*
        skip = set()
        if self.skip_local_add:
            # TODO: Think about this
            skip.update([8])
        if self.skip_perm:
            skip.update([3])
        if self.skip_pc:
            skip.update([4])
        if self.skip_compute:
            skip.update([6,7,8])
        if self.skip_upload:
            skip.update([8])
        self.steps = [c for c in self.steps if c not in skip]
        self.ADDITIONS = Path("DATA", "additions", self.name)
        self.has_lock = False
        # TODO: Set ncores, ncores_per_cluster, timeout_oh, timeout_clusters, timeout_id
        # TODO: Write ClusteringIsoTest.m
        # TODO: Write identify_cluster.py
        # TODO: Finish representation_to_description and vice versa

    def run(self, n=None):
        if self.status:
            self.report_status()
        elif n is None:
            for n in self.steps:
                self.run(n)
        elif n == 0:
            self.setup()
        elif n == 1:
            self.ordhash()
        elif n == 2:
            self.isolabel()
        elif n == 3:
            self.permrep()
        elif n == 4:
            self.pcrep()
        elif n == 5:
            self.set_preload()
        elif n == 6:
            self.cloud_parallel()
        elif n == 7:
            self.cloud_collect()
        elif n == 8:
            self.upload()

    def report_status(self):
        pass

    def ensure_folders(self):
        for name in ["descriptions", "hash_lookup", "subhash_lookup", "quohash_lookup", "minrep.todo", "minreps", "minrep.timings", "pcrep.todo", "pcreps", "pcrep.timings", "preload", "additions"]:
            Path("DATA", name).mkdir(parents=True, exist_ok=True)
        Path("DATA", "additions", self.name).mkdir(parents=True, exist_ok=True)
        for name in ["cluster_in", "cluster_out"]:
            Path("DATA", "additions", self.name, name).mkdir(exist_ok=True)

    def is_locked(self):
        """
        Determine whether labeling is locked, preventing parts of steps 0-3
        """
        return self.LOCK.exists()

    def acquire_lock(self):
        if self.is_locked():
            print("Waiting for lockfile DATA/additions/lock to be removed by another process")
        while self.is_locked():
            time.sleep(1)
        return LabelingLock(self)

    def setup(self):
        """
        Step 0.

        Extract necessary data into

        - DATA/descriptions/
        - DATA/hash_lookup/
        - DATA/subhash_lookup
        - DATA/quohash_lookup

        from the LMFDB (if not already present).  These will be regenerated
        if the number of files in the DATA/descriptions folder is less than
        db.gps_groups.count(), indicating that groups have been added on another server.
        """
        self.ensure_folders()
        DATA = Path("DATA")
        SUBHASH = DATA / "subhash_lookup"
        QUOHASH = DATA / "quohash_lookup"
        db_count = db.gps_groups.count()
        # We use os.scandir because it's the fastest option I can find, and iterating over 500K+ entries takes a bit of time.
        local_count = sum(1 for _ in os.scandir(DATA / "descriptions"))
        if db_count > local_count:
            if self.is_locked():
                raise RuntimeError("Remote database has more groups than local folder, but lock present")
            if local_count > 0:
                print("Remote database has more groups than local folder\nRecreating descriptions and hash lookups from database.\n Proceeding in 5 seconds....")
                time.sleep(5)
                for folder in [self.DESC, self.HASH, SUBHASH, QUOHASH]:
                    shutil.rmtree(folder)
                self.ensure_folders()
            for rec in db.gps_groups.search({}, ["label", "representations", "element_repr_type", "order", "hash"]):
                with open(self.DESC / rec["label"], "w") as F:
                    _ = F.write(representation_to_description(rec["order"], rec["representations"], rec["element_repr_type"]) + "\n")
                # TODO: This will use 123456/None for things without a computed hash.  Probably Fine?
                with open(self.HASH / str(rec["order"]) / str(rec["hash"]), "a") as F:
                    _ = F.write(rec["label"] + "\n")
            for rec in db.gps_subgroups.search({}, ["label", "normal", "subgroup_order", "quotient_order", "subgroup_hash", "quotient_hash", "subgroup", "quotient", "special_labels"]):
                special_labels = ",".join(slabel for slabel in rec["special_labels"] if slabel.isalpha())
                if special_labels:
                    special_labels = " " + special_labels
                # TODO: Check that this isn't too many files
                if rec["subgroup"] is None and rec["subgroup_hash"] is not None:
                    with open(SUBHASH / str(rec["subgroup_order"]) / str(rec["subgroup_hash"]), "a") as F:
                        _ = F.write(f'{rec["label"]}{special_labels}\n')
                if rec["normal"] and rec["quotient"] is None and rec["quotient_hash"] is not None:
                    with open(QUOHASH / str(rec["quotient_order"]) / str(rec["quotiet_hash"]), "a") as F:
                        _ = F.write(f'{rec["label"]}{special_labels}\n')

    @cached_method
    def inputs(self):
        INPUT = self.ADDITIONS / "input"
        with open(INPUT) as F:
            inputs = [desc.strip() for desc in F]
            ctr = Counter(inputs)
            if len(inputs) != len(ctr):
                raise ValueError(f"Repeated descriptions ({','.join(inp for (inp, c) in ctr.items() if c > 1)})")
        return inputs, ctr

    @cached_method
    def ordhash(self):
        """
        Step 1.

        Compute orders and hashes for the groups to be added.

        Returns a list of triples (desc, order, hash), in the same order as the input file.
        """
        self.ensure_folders()
        RUN = self.ADDITIONS / "oh_tmp"
        ORDHASH = self.ADDITIONS / "ordhash"
        ordhash = {}
        inputs, ctr = self.inputs()
        if ORDHASH.exists():
            with open(ORDHASH) as F:
                for line in F:
                    desc, oh = line.strip().split(" ")
                    if desc not in ctr:
                        raise ValueError(f"Description {desc} not in input file")
                    ordhash[desc] = oh
            if len(ordhash) == len(inputs):
                # ORDHASH is already complete, so we don't need to do any more computations
                RUN = None
        try:
            if RUN:
                with open(RUN, "w") as F:
                    _ = F.write("".join(desc+"\n" for desc in inputs if desc not in ordhash))
                subprocess.run(f"parallel -j {self.ncores} --timeout {self.timeout_oh} -a {RUN} magma -b desc={{1}} hashone.m >> {ORDHASH}", shell=True, check=True)
            with open(ORDHASH) as F:
                for line in F:
                    desc, oh = line.strip().split(" ")
                    if desc not in ctr:
                        raise ValueError(f"Description {desc} not in input file")
                    if desc in ordhash:
                        assert ordhash[desc] == oh
                    else:
                        ordhash[desc] = oh
        finally:
            if RUN:
                RUN.unlink()
        if len(ordhash) != len(inputs):
            print("\n\n" + "\n".join(desc for desc in inputs if desc not in ordhash) + "\n\nThe above hash computations did not succeed; increasing timeout_oh may help")
            raise RuntimeError("Unsuccessful hash computations (try increasing timeout_oh)")
        return [(desc,) + tuple(map(int, ordash[desc].split("."))) for desc in inputs]

    def order_counts(self):
        """
        Reload the counts of known labels from the descriptions folder.
        """
        # these orders have group ids but IdentifyGroup doesn't work in Magma
        medium = set([512, 1152, 1536, 1920, 2187, 6561, 15625, 16807, 78125, 161051])
        small = set(range(1,2001)).difference([512, 1024, 1152, 1536, 1920])
        big = Counter()
        with os.scandir(self.DESC) as it:
            for entry in it:
                if entry.name.count(".") == 1: # Should always be true
                    N, i = entry.name.split(".")
                    N = int(N)
                    if N in medium or N in small:
                        continue
                    if i.isdigit():
                        small.add(N)
                    else:
                        big[N] += 1
        return small, medium, big

    def assign_label(self, n):
        """
        Create the next label to be used for the given group order.
        """
        assert self.has_lock
        if not hasattr(self, "big_orders"):
            self.small_orders, self.medium_orders, self.big_orders = self.order_counts()
        assert n not in self.small_orders and n not in self.medium_orders
        label = f"{n}.{cremona_letter_code(self.big_orders[n])}"
        assert not (self.DESC / label).exists()
        self.big_orders[n] += 1
        return label


    def safe_write(self, s, path, mode="w"):
        """
        Write to a temporary file and then move, in order to protect against getting interrupted
        """
        TMP = self.ADDITIONS / "safe_tmp"
        if mode == "a":
            shutil.copy(path, TMP)
        with open(TMP, mode) as F:
            _ = F.write(s)
        shutil.move(TMP, path)

    def create_clusters(self, ordhash):
        """
        Use ClusteringIsoTest.m to group the inputs into isomorphism classes
        """
        CLUSTER_IN = self.ADDITIONS / "cluster_in"
        by_ordhash = defaultdict(list)
        for desc, order, hsh in ordhash:
            by_ordhash[f"{order}.{hsh}"].append(desc)
        todo = []
        for oh, descs in by_ordhash.items():
            PATH = CLUSTER_IN / oh
            if PATH.exists():
                with open(PATH) as F:
                    # ClusteringIsoTest.m gradually clears its input file as it
                    # creates final isomorphism classes.  If the input file is
                    # empty, there's nothing more to be done.
                    if F.read().count("\n") > 0:
                        todo.append(oh)
            else:
                self.safe_write("\n".join(descs) + "\n", PATH)
                todo.append(oh)
        if todo:
            TODO = self.ADDITIONS / "cluster_todo"
            self.safe_write("\n".join(todo) + "\n", TODO)
            subprocess.run("parallel -j {self.ncores} --timeout {self.timeout_cluster} -a {TODO} magma -b name:={self.name} ordhash:={{1}} ClusteringIsoTest.m", shell=True, check=True)
        CLUSTER_OUT = self.ADDITIONS / "cluster_out"
        clusters = []
        for PATH in CLUSTER_OUT.iterdir():
            # TODO: What if hsh is None?
            order, hsh = map(int, PATH.parts[-1].split(".")[:2])
            with open(PATH) as F:
                clusters.append((order, hsh, F.read().strip().split(" ")))
        return clusters

    def update_local(self, new, labels, ordhash):
        """
        Updates the local folders DATA/descriptions and DATA/hash_lookup with the newly added groups
        """
        hashed = set()
        def write_all():
            rev = {}
            for desc, label in labels.items():
                if label not in rev:
                    rev[label] = desc
            oh_lookup = {}
            for desc, order, hsh in ordhash:
                oh_lookup[desc] = (order, hsh)
            for label in new:
                desc = rev[label]
                order, hsh = oh_lookup[desc]
                self.safe_write(desc + "\n", self.DESC / label)
                if label not in hashed:
                    self.safe_write(label + "\n", self.HASH / str(order) / str(hsh), mode="a")
                    hashed.add(label)
        try:
            write_all()
        except BaseException:
            # Trap KeyboardInterrupts
            write_all()
            raise

    def run_identify_filenames(self, order, hsh, cluster):
        chash = hash(cluster)
        # Find all the descriptions with this ordhash, so that we can update the input file
        while True:
            infile = self.ADDITIONS / "id_todo" / f"{order}.{hsh}.{chash}"
            outfile = self.ADDITIONS / "id_done" / f"{order}.{hsh}.{chash}"
            if infile.exists():
                with open(infile) as F:
                    for line in F:
                        if line.split(" ") == cluster:
                            return infile, outfile
                        break # Only care about the first line of the input file
                # There was a collision in chash
                chash += 1
            else:
                return infile, outfile

    def write_identify_input(self, order, hsh, cluster, options=None):
        """
        Write a file for input into IdentifyCluster.m
        """
        with open(self.HASH / str(order) / str(hsh)) as F:
            possibilities = set(line.strip() for line in F)
        infile, outfile = self.run_identify_filenames(order, hsh, cluster)
        if outfile.exists():
            with open(outfile) as F:
                for line in F:
                    status = line.strip() # First line contents
                    break
            if status == "None":
                # This is the case where we might have added more groups
                with open(infile) as F:
                    done = set()
                    for i, line in enumerate(F):
                        if i != 0:
                            label, checked = line.strip().split()
                            if checked == "1":
                                done.add(label)
                if len(possibilities) > len(done):
                    addition = "".join(f"{label} 0\n" for label in possibilities.difference(done))
                    self.safe_write(addition, infile, mode="a")
                    outfile.unlink()
                    return infile, outfile
            return # already done
        elif infile.exists():
            return infile, outfile
        contents = " ".join(cluster) + "\n"
        contents += "".join(f"{label} 0\n" for label in possibilities)
        self.safe_write(contents, infile)
        return infile, outfile

    def read_identify_output(self, outfile):
        """
        Read the output file from IdentifyCluster.m
        """
        if not outfile.exists():
            return False
        with open(outfile) as F:
            data = F.read().split("\n")
            if data[0] in ["Error", "Timeout"]:
                return False
            elif data[0] == "None":
                return None
            return data[0]

    def execute_identify(self, labels, todo, failures, run_id):
        TODO = self.ADDITIONS / "run_ids.todo"
        contents = "".join(f"{infile}\n" for (order, hsh, cluster, infile, outfile) in run_id)
        self.safe_write(contents, TODO)
        ncores = max(1, self.ncores // self.ncores_per_cluster)
        subprocess.run(f"parallel -j {ncores} -a {TODO} ./identify_cluster.py {{1}} --ncores {self.ncores_per_cluster} --timeout {self.tiemout_id}", shell=True, check=True)
        for (order, hsh, cluster, infile, outfile) in run_id:
            label = self.read_identify_output(outfile):
            if label is None: # Checked all current groups and this is not one of them
                todo.append((order, hsh, cluster))
            elif label is False: # There was an error or timeout
                for desc in cluster:
                    failures.add(desc)
            else:
                for desc in cluster:
                    labels[desc] = label


    @cached_method
    def isolabel(self):
        """
        Step 2.

        Divides input groups into isomorphism classes and assigns labels.  There is now a file available with the labels for all the input groups (new or old).
        """
        self.ensure_folders()
        LABELS = self.ADDITIONS / "labels"
        NEW = self.ADDITIONS / "new"
        FAIL = self.ADDITIONS / "id_fail"
        inputs, ctr = self.inputs()
        # First, check if the labels file is already present
        if NEW.exists() and LABELS.exist():
            with open(LABELS) as F:
                labels = [label.strip() for label in F]
            if len(labels) != len(inputs):
                raise RuntimeError("Label file does not have the same number of rows as input file")
            with open(NEW) as F:
                new = [label.strip() for label in F]
            return new
        elif NEW.exists() or LABELS.exists():
            raise RuntimeError("Label file present without new file or vice versa")

        ordhash = self.ordhash()
        if self.assume_distinct:
            clusters = [(order, hsh, [desc]) for (desc, order, hsh) in ordhash]
        else:
            clusters = self.create_clusters(ordhash)

        # We determine which orders are small (magma can identify them) or medium (we can use stored hashes)
        labels = {}
        small_orders, medium_orders, big_orders = self.order_counts()
        unknown_orders = sorted(set(order for (desc, order, hsh) in ordhash if (order not in small_orders and order not in medium_orders and order_not in big_orders)))
        if unknown_orders:
            magma_unknown = magma(unknown_orders)
            magma_unknown = magma("[CanIdentifyGroup(o) : o in %s]" % magma_unknown.name())
            for order, can_id in zip(unknown_orders, magma_unknown):
                if can_id:
                    small_orders.add(order)
        medium_oh = defaultdict(lambda: defaultdict(list))
        run_id = []
        todo = []
        for order, hsh, cluster in clusters:
            oh = f"{order}.{hsh}"
            if order in small_orders:
                for desc in cluster:
                    labels[desc] = oh
            elif order in medium_orders:
                medium_oh[order][hsh].append(cluster)
            elif order in big_orders:
                if self.assume_new:
                    todo.append((order, hsh, cluster))
                else:
                    infile, outfile = self.write_identify_input(order, hsh, cluster)
                    if infile is not None:
                        run_id.append((order, hsh, cluster, infile, outfile))

        # We use the gps_smallhash table to help identify medium groups
        for order, hashes in medium_oh.items():
            medium_labels = defaultdict(list)
            if len(hashes) == 1:
                query = {"order": order, "hash": list(hashes)[0]}
            else:
                query = {"order": order, "hash": {"$in": list(hashes)}}
            for rec in db.gps_smallhash.search(query, ["hash", "counter"]):
                medium_labels[rec["hash"]].append(rec["counter"])
            if len(medium_labels) != len(hashes):
                missing = set(hashes).difference(set(medium_labels))
                raise RuntimeError(f"No groups found of order {order} and hashes {','.join(str(h) for h in missing)}")
            for hsh, counters in medium_labels.items():
                if len(counters) == 1:
                    # We know the label for everything with this hash
                    label = f"{order}.{counters[0]}"
                    for cluster in hashes[hsh]:
                        for desc in cluster:
                            labels[desc] = label
                else:
                    labels = [f"{order}.{counter}" for counter in counters]
                    for cluster in hashes[hsh]:
                        infile, outfile = self.write_identify_input(order, hsh, cluster, labels)
                        if infile is not None:
                            run_id.append((order, hsh, cluster, infile, outfile))

        # Now we actually identify the groups in run_id
        failures = set()
        if run_id:
            self.execute_identify(labels, todo, failures, run_id)

        with self.acquire_lock():
            if not self.assume_new:
                # Now that we've aquired the lock, it's possible that more groups have been added
                # and some of the groups that looked new before now have a label.
                run_id = []
                i = 0
                while i < len(todo):
                    order, hsh, cluster = todo[i]
                    # infile will already exist, and write_identify_input compares its contents
                    # to the list of groups with this ordhash
                    infile, outfile = self.write_identify_input(order, hsh, cluster)
                    if infile is None:
                        # No change, so proceed to the next i
                        i += 1
                    else:
                        run_id.append((order, hsh, cluster, infile, outfile))
                        del todo[i]
                if run_id:
                    self.execute_identify(labels, todo, failures, run_id)

            new = []
            if not self.id_only:
                for order, hsh, cluster in todo:
                    label = self.assign_label(order)
                    new.append(label)
                    for desc in cluster:
                        labels[desc] = label

            label_text = "".join(f"{labels.get(desc, 'FAIL' if desc in failures else 'NEW')}\n" for desc in inputs)
            try:
                self.safe_write(label_text, LABELS)
                if new:
                    self.update_local(new, labels, ordhash)
                    self.safe_write("".join(f"{label}\n" for label in new), NEW)
                if failures:
                    self.safe_write("".join(f"{label}\n" for label in failures), FAIL)
            except BaseException:
                # update_local already handled KeyboardInterrupt, so we just have to write to LABELS and NEW
                self.safe_write(label_text, LABELS)
                if new:
                    self.safe_write("".join(f"{label}\n" for label in new), NEW)
                if failures:
                    self.safe_write("".join(f"{label}\n" for label in failures), FAIL)
                raise
            return new

    def permrep(self):
        """
        Step 3.

        Computes MinimalDegreePermutationRepresentation (via MinReps4.m)
        """
        

    def pcrep(self):
        """
        Step 4.

        Computes PCGenerators (via PCreps.m)
        """
        

    def set_preload(self):
        """
        Step 5.

        Sets preload (see create_descriptions.py for more details).
        """
        

    def cloud_parallel(self):
        """
        Step 6.

        Creates DATA/manifest and DATA/ncores appropriately, then executes cloud_parallel.py
        """
        

    def cloud_collect(self):
        """
        Step 7.

        Imports appropriate functions from cloud_collect and executes them to generate upload files
        """
        

    def upload(self):
        """
        Step 8.

        Uploads data from these files into the relevant LMFDB tables.
        """
        


runner = Runner(parser.parse_args())
#runner.run()
