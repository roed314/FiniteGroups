# Utility functions for monitoring an ongoing computation
# These functions should be called with the current working directory set to the DATA directory

from sage.misc.cachefunc import cached_function
from sage.all import RR, ZZ
from collections import defaultdict
import os
opj = os.path.join
ope = os.path.exists

@cached_function
def num_groups(n):
    return ZZ(gap.NrSmallGroups(n))

def check_missing():
    started = []
    with open("logs/overall") as F:
        for line in F:
            started.append(line.strip().split()[3])
    Ns = sorted(set(ZZ(label.split(".")[0]) for label in started))
    maxN = max(Ns)
    maxi = max(ZZ(label.split(".")[1]) for label in started if ZZ(label.split(".")[0]) == maxN)
    unfinished = []
    for N in Ns:
        imax = num_groups(N) if N != maxN else maxi
        for i in range(1, imax+1):
            label = "%s.%s" % (N, i)
            if not ope(opj("groups", label)):
                unfinished.append(label)
    return unfinished

def write_rerun_input(filename, skip=[512,640,768,896,1024,1152,1280,1408,1536,1664,1792,1920], Nlower=None, Nupper=None):
    """
    Writes an input file for running in parallel, and returns the Nlower and Nupper to use in conjunction with it.

    For example:

    sage: write_parallel_input('inputs.txt')
    (576, 2001)

    parallel -j192 -a inputs.txt --timeout 3600 "magma Folder:=DATA Nlower:=576 Nupper:=2001 Skip:=[512,640,768,896,1024,1152,1280,1408,1536,1664,1792,1920] Proc:={1} AddSmallGroups.m | tee output/{1}.txt"
    """
    labels = check_missing()
    by_N = defaultdict(list)
    for label in labels:
        N, i = label.split(".")
        N, i = ZZ(N), ZZ(i)
        by_N[N].append(i)
    if Nlower is None:
        Nlower = min(by_N)
    else:
        assert Nlower <= min(by_N)
    if Nupper is None:
        Nupper = max(by_N) + 1
    else:
        assert Nupper > max(by_N)
    Procs = []
    sofar = 0
    for N in range(Nlower, Nupper):
        if N in skip:
            continue
        for i in by_N[N]:
            Procs.append(str(sofar + i))
        sofar += num_groups(N)
    with open(filename, 'w') as F:
        F.write("\n".join(Procs))
    return Nlower, Nupper

def show_failures(Nlower, skip=[512,640,768,896,1024,1152,1280,1408,1536,1664,1792,1920]):
    labels = check_missing()
    by_N = defaultdict(list)
    for label in labels:
        N, i = label.split(".")
        N, i = ZZ(N), ZZ(i)
        by_N[N].append(i)
    sofar = 0
    for N in range(Nlower, max(by_N) + 1):
        if N in skip:
            continue
        for i in by_N[N]:
            proc = sofar + i
            filename = f"output/{proc}.txt"
            if os.path.exists(filename):
                with open(filename) as F:
                    print(f"{N}.{i} = {proc}")
                    print("".join(list(F)[-3:]))
            else:
                print(f"No output file for {N}.{i}")
        sofar += num_groups(N)

groups_header = "Agroup|Zgroup|elt_rep_type|transitive_degree|abelian|abelian_quotient|all_subgroups_known|almost_simple|aut_group|aut_order|center_label|central_product|central_quotient|commutator_count|commutator_label|complete|composition_factors|composition_length|counter|cyclic|derived_length|direct_factorization|direct_product|elementary|eulerian_function|exponent|exponents_of_order|factors_of_aut_order|factors_of_order|faithful_reps|finite_matrix_group|frattini_label|frattini_quotient|gens_used|hash|hyperelementary|label|maximal_subgroups_known|metabelian|metacyclic|monomial|name|ngens|nilpotency_class|nilpotent|normal_subgroups_known|number_autjugacy_classes|number_characteristic_subgroups|number_conjugacy_classes|number_divisions|number_normal_subgroups|number_subgroup_autclasses|number_subgroup_classes|number_subgroups|old_label|order|order_stats|outer_equivalence|outer_group|outer_order|pc_code|perfect|perm_gens|pgroup|primary_abelian_invariants|quasisimple|rank|rational|schur_multiplier|semidirect_product|simple|smallrep|smith_abelian_invariants|solvability_type|solvable|subgroup_inclusions_known|subgroup_index_bound|supersolvable|sylow_subgroups_known|tex_name|wreath_data|wreath_product".split("|")

def update_groups():
    # Goal: update to include char_stats
    pass

def update_subgroups():
    # Goal: update to include diagram_x/diagram_aut_x from current data
    from lmfdb import db

def size_chars():
    base = opj("DATA", "characters_cc")
    size = {}
    for label in os.listdir(base):
        size[label] = os.path.getsize(opj(base, label))
    extract = {}
    clist = {"label": None,
             "exponent": int,
             "number_conjugacy_classes": int,
             "factors_of_order": lambda x: [int(c) for c in x[1:-1].split(",") if c]}
    for i, col in enumerate(groups_header):
        if col in clist:
            extract[col] = (i, clist[col])
    labi, _ = extract.pop("label")
    gdata = defaultdict(dict)
    with open(opj("LMFDB", "groups.data")) as F:
        for i, line in enumerate(F):
            if i < 3: continue
            if i%10000 == 0:
                print(i)
            pieces = line.split("|")
            for col, (i, typer) in extract.items():
                gdata[pieces[labi]][col] = typer(pieces[i])
    def cutoff(exp_cutoff=None, ncc_cutoff=None, maxp_cutoff=None):
        total = 0
        for label, attr in gdata.items():
            if exp_cutoff is not None and attr["exponent"] > exp_cutoff:
                continue
            if ncc_cutoff is not None and attr["number_conjugacy_classes"] > ncc_cutoff:
                continue
            if maxp_cutoff is not None and attr["factors_of_order"] and max(attr["factors_of_order"]) > maxp_cutoff:
                continue
            if label in size:
                total += size[label]
            else:
                print(f"no data for {label}")
    return size, gdata, cutoff

def count_chars():
    # Goal: figure out how to trim character tables
    pass
