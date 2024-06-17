
"""
This file contains functions for changes to the data that may need to be made multiple times,
including the following tasks:

* Change element_repr_type, making elements display using a different construction for the group.
* Update the label to use small group ids when they become available in GAP
  (for example, update groups of order 2100 to use newly available labels)
* Add identifications for subgroup, quotient, aut_group, outer_group.  This can also update latex for other groups.

This file should be attached to a running instance of Sage, with `from lmfdb import db` already executed.
You must also have write access to the database.
Some of these functions may take a while to execute, so it may be worth running in screen or tmux
to prevent interruption.
"""
from sage.databases.cremona import class_to_int
from collections import defaultdict
import subprocess
from pathlib import Path
import description_conversion
representation_to_description = description_conversion.representation_to_description
from psycodict.utils import DelayCommit
from psycodict.encoding import copy_dumps
import re

def update_element_repr_type(changes, ncores=24, force=False):
    """
    INPUT:

    - changes -- a dictionary {label: new_ert}.  new_ert can be a normal value (PC, Perm, GLZ, GLFp, GLFq, GLZq, GLZN, Lie) or Lie2, Lie3, etc (in which case the order of the Lie groups in the representations dictionary will be changed to move the specified representation to the front).
    - ncores -- the number of cores to use in computing the new representatives.

    OUTPUT:

    labels in the changes dictionary that are not actually changing will be deleted, and the relevant tables will be updated.
    """
    assert changes

    current, representations, autgens, subgens, ccreps = ert_inputs(changes, force=force)
    todofile = write_ert_input(changes, current, representations, autgens, subgens, ccreps)
    run_ert_magma(todofile, ncores)
    outfolder, Swritten, jwritten = collate_ert_output(changes)
    # TODO: change representations when Lie order is swapped
    upload_ert_to_db(outfolder, Swritten, jwritten)

def fix_element_repr_type(fixfile, ncores=24):
    changes, fix = load_fix(fixfile)
    current, representations, autgens, subgens, ccreps = ert_inputs(changes, force=True)
    todofile = write_ert_input(changes, current, representations, autgens, subgens, ccreps, fix=fix)
    run_ert_magma(todofile, ncores)
    outfolder, Swritten, jwritten = collate_ert_output(changes)
    # We upload manually so that we can double check things

def load_fix(fixfile):
    changes = {}
    fix = {}
    descbase = Path("DATA/descriptions")
    with open(fixfile) as F:
        for i, line in enumerate(F):
            if i > 1: # skip header
                pieces = line.strip().split("|")
                descs = [None for _ in pieces]
                for j, x in enumerate(pieces):
                    if "[" in x:
                        pieces[j], descs[j] = x[:-1].split("[")
                label = pieces[0]
                changes[label] = re.sub(r"\d+", "", pieces[2]) # Change Lie1 to Lie
                with open(descbase / label) as Fdesc:
                    filedesc = Fdesc.read().strip()
                fix[label] = (pieces, descs, filedesc)
    return changes, fix

def ccpair(label):
    N, i = label.split(".")
    if not i.isdigit():
        i = class_to_int(i) + 1
    return int(N), int(i)

def ert_inputs(changes, force=False):
    labels = list(changes)

    representations = {}
    current = {}
    autgens = defaultdict(list)
    ccreps = defaultdict(list)
    subgens = defaultdict(list)
    if len(changes) < 200:
        # There is some cutoff where it's faster to scan through everything; 200 is just a guess
        gquery = {"label":{"$in":list(changes)}}
    else:
        gquery = {}
    for rec in db.gps_groups.search(gquery, ["label", "aut_gens", "representations", "element_repr_type"]):
        label = rec["label"]
        if label in changes:
            if rec["element_repr_type"] == changes[label] and not force:
                del changes[label]
            else:
                current[label] = rec["element_repr_type"]
                autgens[label] = rec["aut_gens"]
                representations[label] = rec["representations"]

    if len(changes) < 200:
        squery = {"ambient":{"$in":list(changes)}}
    else:
        squery = {}
    for rec in db.gps_subgroups.search(squery, ["ambient", "label", "generators", "subgroup_order"]):
        ambient = rec["ambient"]
        if ambient in changes and rec["generators"]:
            subgens[ambient].append((rec["label"], rec["subgroup_order"], rec["generators"]))

    ccpairs = {ccpair(label): label for label in labels}
    for rec in db.gps_conj_classes.search({}, ["group_order", "group_counter", "id", "order", "representative"]):
        pair = (rec["group_order"], rec["group_counter"])
        label = ccpairs.get(pair)
        if label:
            ccreps[label].append((rec["id"], rec["order"], rec["representative"]))

    return current, representations, autgens, subgens, ccreps

def write_ert_input(changes, current, representations, autgens, subgens, ccreps, fix=None):
    infolder = Path("DATA/ert_change_in")
    infolder.mkdir(exist_ok=True)
    todofile = Path("DATA/ert.todo")
    with open(todofile, "w") as Ftodo:
        for (label, new_ert) in changes.items():
            _ = Ftodo.write(label+"\n")
            order = int(label.split(".")[0])
            rep = representations[label]
            with open(infolder / label, "w") as F:
                if fix:
                    pieces, descs, filedesc = fix[label]
                    for j in range(2,6):
                        if descs[j] is None:
                            # Not Lie, so either PC, Perm, GLZq or GLZN
                            if pieces[j] in ["GLZq", "GLZN"]:
                                # Elements are correctly stored as matrices
                                assert "--" in filedesc
                                descs[j] = filedesc
                            elif not pieces[j]: # No data, so it doesn't matter what we put as long as it parses correctly
                                descs[j] = representation_to_description(order, rep, pieces[1])
                            else:
                                descs[j] = representation_to_description(order, rep, pieces[j])
                        elif pieces[j].startswith("Lie") and descs[j].startswith("P") and j > 2:
                            # Override the default behavior of lifting PGL(d,q), since elements are encoded as permutations
                            if "--" not in descs[j]:
                                descs[j] = f"{descs[j]}-->{descs[j]}"
                        elif pieces[j].startswith("PLie") and descs[j][0] != "P":
                            # Elements are correctly stored as lifted matrices
                            descs[j] = "P" + descs[j]
                    _ = F.write("&".join(descs[3:]) + "\n")
                    _ = F.write(descs[2] + "\n")
                    if autgens[label] is not None:
                        _ = F.write(f"a{autgens[label]}\n")
                    if descs[2] != descs[5]:
                        for slabel, sorder, gens in subgens[label]:
                            _ = F.write(f"S{slabel}|{sorder}|{gens}\n")
                    if descs[2] != descs[4]:
                        for repid, rorder, rep in ccreps[label]:
                            _ = F.write(f"j{repid}|{rorder}|{rep}\n")
                else:
                    _ = F.write(representation_to_description(order, rep, current[label]) + "\n")
                    _ = F.write(representation_to_description(order, rep, new_ert) + "\n")
                    if autgens[label] is not None:
                        _ = F.write(f"a{autgens[label]}\n")
                    for slabel, sorder, gens in subgens[label]:
                        _ = F.write(f"S{slabel}|{sorder}|{gens}\n")
                    for repid, rorder, rep in ccreps[label]:
                        _ = F.write(f"j{repid}|{rorder}|{rep}\n")
    return todofile

def run_ert_magma(todofile, ncores):
    subprocess.run(["parallel", "-j", str(ncores), "-a", todofile, "magma -b label:={1} ChangeERT.m"], check=True)

def collate_ert_output(changes):
    outfolder = Path("DATA/ert_change_out")
    outfolder.mkdir(exist_ok=True)
    with open(outfolder / "gps_groups.txt", "w") as Fgroups:
        _ = Fgroups.write("label|element_repr_type|aut_gens\ntext|text|numeric[]\n\n")
        with open(outfolder / "gps_subgroups.txt", "w") as Fsubgroups:
            _ = Fsubgroups.write("label|generators\ntext|numeric[]\n\n")
            Swritten = False
            with open(outfolder / "gps_conj_classes.txt", "w") as Fconj:
                _ = Fconj.write("id|representative\ninteger|numeric\n\n")
                jwritten = False
                for label in changes:
                    group_order, group_counter = ccpair(label)
                    with open(outfolder / label) as F:
                        for i, line in enumerate(F):
                            if i == 0:
                                if line[0] == "a":
                                    # Need to strip numbers, eg if changes[label] = Lie2
                                    agens = line[1:].strip()
                                    _ = Fgroups.write(f"{label}|{changes[label]}|{agens}\n")
                                else:
                                    # No autgens
                                    _ = Fgroups.write(f"{label}|{changes[label]}|\\N\n")
                            if line[0] == "S":
                                Swritten = True
                                _ = Fsubgroups.write(line[1:])
                            elif line[0] == "j":
                                jwritten = True
                                _ = Fconj.write(line[1:])
                            elif line[0] == "E":
                                raise RuntimeError(label, line)
    return outfolder, Swritten, jwritten

def upload_ert_to_db(outfolder, Swritten, jwritten):
    # Note that doing this in a DelayCommit means that tables are locked until all of them finish.  The alternative is to have inconsistent data while one table has been reloaded but not another.
    with DelayCommit(db):
        if jwritten:
            db.gps_conj_classes.update_from_file(outfolder / "gps_conj_classes.txt", label_col="id")
        db.gps_groups.update_from_file(outfolder / "gps_groups.txt")
        if Swritten:
            db.gps_subgroups.update_from_file(outfolder / "gps_subgroups.txt")
