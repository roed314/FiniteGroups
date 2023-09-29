#!/usr/bin/env python3
# current bound of 1000 conjugacy classes for testing irrep_stats,
# current bound 5,000,000,000 for aut group order
# TO DO: groups that are not  Perm nor PC,  not currently testing subgroup DB

#E error  W warning  T timing

import sys, os, time

HOME=os.path.expanduser("~")
sys.path.append(os.path.join(HOME, 'lmfdb'))

from lmfdb import db
from sage.all import libgap, ZZ, Permutations, Permutation, SymmetricGroup



#creates order set from Gap, C conjugacy classes of G
def gap_order_set(G,C):
    gap_ords = []
    for i in range(C.Size()):
        c = C[i]
        gap_ords.append(c.Representative().Order().sage())
    return list(set(gap_ords))

#creates order statistics from Gap, and number cc
def gap_order_stats(G):
    C = G.ConjugacyClasses()
    ord_set = gap_order_set(G,C)
    L = []
    for ord in ord_set:
        L.append([ord,0])
    for c in C:
        loc = ord_set.index(c.Representative().Order())
        L[loc][1] += c.Size()
    return L, len(C)


#creates irrep degrees from Gap
def gap_irrep_set(G):
    gap_irrs = []
    char = G.Irr()
    for i in range(char.Size()):
        deg = char[i][0]
        gap_irrs.append(deg.sage())
    gap_irr_set=set(gap_irrs)
    irr_stats=[]
    for elt in gap_irr_set:
        irr_stats.append([elt,gap_irrs.count(elt)])
    return irr_stats


def get_num_cc(data):
    sum_cc = 0
    if 'irrep_stats' in data and data['irrep_stats'] != None:
        for tup in data['irrep_stats']:
            sum_cc += tup[1]
    return sum_cc  #0 means don't have irrep stats
                
#code for boolean and numeric values from a direct GAP call
def test_match(col, data, funcname, G, Fout):
    if col in data:    #only compare if data exists in db
        if data[col] != None:
            func = getattr(libgap, funcname)
            gapval = func(G)
            if data[col] != gapval:
                Fout.write(f"E Mismatch in {col}: {data[col]} (data) vs {gapval} (GAP) \n")
                return [(data["label"], col)]
    return []

#code for labels where GAP returns [a,b] as group ID"
def test_label(col,data,funcname,G,Fout):
    if col in data:    #only compare if data exists in db
        func = getattr(libgap,funcname)
        specialG = func(G)
        if libgap.SmallGroupsAvailable(specialG.Order()):
            gapval = libgap.IdGroup(specialG)
            gapstrng = str(gapval[0]) +  "." + str(gapval[1])
            if data[col] != gapstrng:
                Fout.write(f"E Mismatch in {col}: {data[col]} (data) vs {gapstrng} (GAP) \n")
                return [(data["label"], col)]
        else:
            Fout.write(f"W Cannot determine label for group represented in {col}. \n")
    return []


#code for lists
def test_list(col,data,func,G,Fout):
    if col in data:
        gaplist = func(G)
        gaplist.sort()
        if data[col] != gaplist:
            Fout.write(f"E Mismatch in {col}: {data[col]} (data) vs {gaplist} (GAP) \n")
            return [(data["label"], col)]
    return []


def test_gps(data,G,Fout): 
    failures = []
    init_time = time.time()
    #Test Boolean and Numeric Values
    for (col, funcname) in [("abelian", "IsAbelian"),
                            ("almost_simple", "IsAlmostSimpleGroup"),
                            ("cyclic", "IsCyclic"),
                            ("monomial","IsMonomialGroup"),
                            ("nilpotent", "IsNilpotentGroup"),
                            ("perfect","IsPerfectGroup"),
                            ("quasisimple", "IsQuasisimpleGroup"),
                            ("simple","IsSimpleGroup"),
                            ("solvable", "IsSolvableGroup"),
                            ("supersolvable", "IsSupersolvableGroup"),
                            ("order", "Order"),
                            ("derived_length", "DerivedLength"),
                            ("commutator_length", "CommutatorLength"),
                            ("exponent", "Exponent")]:
#                            ("permutation_degree", "MinimalFaithfulPermutationDegree")]:
        Fout.write("Running: " + col + " " + funcname +"\n")
        failures.extend(test_match(col, data, funcname, G,Fout))
        if data['nilpotency_class'] != -1:   #nilpotency class is special with -1
            failures.extend(test_match('nilpotency_class',data,"NilpotencyClassOfGroup",G,Fout))
    Fout.write("T Checking boolean and numeric values ran in " + str(time.time()-init_time) + " seconds \n")

    #Test labels
    init_time = time.time()
    for (col,funcname) in [("commutator_label", "DerivedSubgroup"),
                           ("center_label", "Center"),
                           ("frattini_label","FrattiniSubgroup"),
                           ("abelian_quotient", "CommutatorFactorGroup")]:
        Fout.write("Running: " +  col + " " + funcname + "\n")
        failures.extend(test_label(col, data, funcname, G,Fout))
    Fout.write("T Checking labels of special subgroups ran in " + str(time.time()-init_time) + " seconds \n")

        #Test list of integers
    init_time =	time.time()
    col = "irrep_stats"
    func = gap_irrep_set
    if 'irrep_stats' in data and data['irrep_stats'] != None:
        if data['number_conjugacy_classes'] <= 1000: #may be able to change this bound
            Fout.write("Running: "+ col + "\n")
            failures.extend(test_list(col, data, func, G,Fout))
            Fout.write("T Checking irreducible representations stats ran in " + str(time.time()-init_time) + " seconds \n")
        else:
            Fout.write(f"W Too many complex representatives ({data['number_conjugacy_classes']}) to create GAP character table \n")
    #testing size of automorphism group (aut gp too large to identify in gap)    
    Fout.write("Running: size of automorphism group \n")
    init_time =	time.time()
    col = "aut_order"
    if data[col] <= 5000000000:
        gap_aut_order = libgap.AutomorphismGroup(G).Order()
        if data[col] != gap_aut_order:
            Fout.write(f"E Mismatch in {col}: {data[col]} (data) vs {gap_aut_order} (GAP) \n")
            failures.extend([(data["label"], 'col')])
        Fout.write("T Checking the automorphism group order ran in " + str(time.time()-init_time) + " seconds \n")
    else:
        Fout.write(f"W Too many automorphism groups ({data[col]}) to determine via GAP in a timely manner. \n")

    
    #testing conjugacy class sizes
    Fout.write("Running: conjugacy class sizes \n")
    init_time = time.time()
    gap_ords, gapnumCC = gap_order_stats(G)
    gap_ords.sort()
    col = 'number_conjugacy_classes'
    if data[col] != gapnumCC:
        Fout.write(f"E Mismatch in {col}: {data[col]} (data) vs {gapnumCC} (GAP) \n")
        failures.extend([(data["label"], 'col')])
    Fout.write("T Checking conjugacy class sizes ran in " + str(time.time()-init_time) + " seconds \n")
    #testing num char = num cc in DB
    init_time = time.time()
    num_cc = get_num_cc(data)
    if num_cc != 0:  # =0 means not in db
        if data[col] != num_cc:
            Fout.write(f"E Mismatch in {col}: {data[col]} (data) vs {num_cc} (data-number cc) \n")
            failures.extend([(data["label"], 'col')])
        Fout.write("T Checking #char = #conjugacy classes ran in " + str(time.time()-init_time) + " seconds \n")    
    #testing order_stats
    init_time = time.time()
    col = 'order_stats'   
    if data[col] != gap_ords:
        Fout.write(f"E Mismatch in {col}: {data[col]} (data) vs {gap_ords} (GAP) \n")
        failures.extend([(data["label"], col)])
    Fout.write("T Checking number of elements of each  order ran in " + str(time.time()-init_time) + " seconds \n")


    #Confirm number of non-conjugate subgroups (if known in database) 
    Fout.write("Running: number of subgroups \n")    
    col = 'number_subgroup_classes'
    if data[col]:
        SubLat = libgap.LatticeSubgroups(G)
        Cons =  libgap.ConjugacyClassesSubgroups(SubLat)
        num_conj_subs = libgap.Size(Cons)
        if data[col] != num_conj_subs:
            Fout.write(f"E Mismatch in {col}: {data[col]} (data) vs {num_conj_subs} (GAP) \n")
            failures.extend([(data["label"], col)])
    Fout.write("T Checking number of subgroup classes ran in " + str(time.time()-init_time) + " seconds \n")
    
    col = 'number_normal_subgroups'
    if data[col]:
        NormLat = libgap.NormalSubgroups(G)
        num_normal = libgap.Size(NormLat)
        if data[col] != num_normal:
            Fout.write(f"E Mismatch in {col}: {data[col]} (data) vs {num_normal} (GAP) \n")
            failures.extend([(data["label"], col)])
        Fout.write("T Checking number of normal subgroup classes ran in " + str(time.time()-init_time) + " seconds \n")
    
    return failures


def random_gp_test():
    sample_gp = db.gps_groups.random(projection=1)
    reps = sample_gp['representations']
    fl_name = "Tests/" + sample_gp['label']
    with open(fl_name, "a") as Fout:
        Fout.write(sample_gp['label']+"\n")
        print(sample_gp['label'])
        init_time = time.time()
        if 'PC' in reps:
            G = libgap.PcGroupCode(ZZ(reps['PC']['code']),sample_gp['order'])
            Fout.write("T Generating the group took " + str(time.time()-init_time) + " seconds \n")
            for err in test_gps(sample_gp,G,Fout):
                print(err)
                print("\n")
        elif 'Perm' in reps:
            n = reps["Perm"]["d"]
            gens = [SymmetricGroup(n)(Permutations(n).unrank(g).to_cycles()) for g in reps["Perm"]["gens"]]
            G = libgap.Group(gens)
            Fout.write("T Generating the group took " + str(time.time()-init_time) + " seconds \n")
            for err in test_gps(sample_gp,G,Fout):
                print(err)
                print("\n")
        else:
            print("ERROR: NOT PC NOR PERM")
