#!/usr/bin/env python3
#TO DO:  subgroups


import sys, os

HOME=os.path.expanduser("~")
sys.path.append(os.path.join(HOME, 'lmfdb'))

from lmfdb import db
from sage.all import libgap



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
    if 'irrep_stats' in data:
        sum_cc  =  0
        for tup in data['irrep_stats']:
            sum_cc += tup[1]
    return sum_cc
                
#code for boolean and numeric values from a direct GAP call
def test_match(col, data, funcname, G):
    if col in data:    #only compare if data exists in db 
        func = getattr(libgap, funcname)
        gapval = func(G)
        if data[col] != gapval:
            print(f"Mismatch in {col}: {data[col]} (data) vs {gapval} (GAP)")
            return [(data["label"], col)]
    return []

#code for labels where GAP returns [a,b] as group ID"
def test_label(col,data,funcname,G):
    if col in data:    #only compare if data exists in db
        func = getattr(libgap,funcname)
        specialG = func(G)
        if libgap.SmallGroupsAvailable(specialG.Order()):
            gapval = libgap.IdGroup(specialG)
            gapstrng = str(gapval[0]) +  "." + str(gapval[1])
            if data[col] != gapstrng:
                print(f"Mismatch in {col}: {data[col]} (data) vs {gapstrng} (GAP)")
                return [(data["label"], col)]
        else:
            print(f"Cannot determine label for group represented in {col}.")
    return []


#code for lists
def test_list(col,data,func,G):
    if col in data:
        gaplist = func(G)
        gaplist.sort()
        if data[col] != gaplist:
            print(f"Mismatch in {col}: {data[col]} (data) vs {gaplist} (GAP)")
            return [(data["label"], col)]
    return []


def test_small_gps(data,G):
    failures = []
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
        print(col,funcname)
        failures.extend(test_match(col, data, funcname, G))
    if data['nilpotency_class'] != -1:   #nilpotency class is special with -1
        failures.extend(test_match('nilpotency_class',data,"NilpotencyClassOfGroup",G))


    #Test labels
    for (col,funcname) in [("commutator_label", "DerivedSubgroup"),
                           ("center_label", "Center"),
                           ("frattini_label","FrattiniSubgroup"),
                           ("abelian_quotient", "CommutatorFactorGroup")]:
        print(col,funcname)
        failures.extend(test_label(col, data, funcname, G))


    #Test list of integers
    for (col,func) in [("irrep_stats",gap_irrep_set)]:
        print(col)
        failures.extend(test_list(col, data, func, G))

    #testing size of automorphism group (aut gp too large to identify in gap)    
    print("size of automorphism group")
    gap_aut_order = libgap.AutomorphismGroup(G).Order()
    col = "aut_order"
    if data[col] != gap_aut_order:
        print(f"Mismatch in {col}: {data[col]} (data) vs {gap_aut_order} (GAP)")
        failures.extend([(data["label"], 'col')])
    
    #testing conjugacy class sizes
    print("conjugacy class sizes")    
    gap_ords, gapnumCC = gap_order_stats(G)
    gap_ords.sort()
    col = 'number_conjugacy_classes'
    if data[col] != gapnumCC:
        print(f"Mismatch in {col}: {data[col]} (data) vs {gapnumCC} (GAP)")
        failures.extend([(data["label"], 'col')])
    #testing num char = num cc in DB  
    num_cc = get_num_cc(data)
    if data[col] != num_cc:
        print(f"Mismatch in {col}: {data[col]} (data) vs {num_cc} (data-number cc)")
        failures.extend([(data["label"], 'col')])
    #testing order_stats
    col = 'order_stats'   
    if data[col] != gap_ords:
        print(f"Mismatch in {col}: {data[col]} (data) vs {gap_ords} (GAP)")
        failures.extend([(data["label"], col)])


    #Confirm number of non-conjugate subgroups (if known in database) 
    print("number of subgroups")    
    col = 'number_subgroup_classes'
    if data[col]:
        SubLat = libgap.LatticeSubgroups(G)                                                                                               
        Cons =  libgap.ConjugacyClassesSubgroups(SubLat)                                                                                  
        if data[col] != libgap.Size(Cons):
            print(f"Mismatch in {col}: {data[col]} (data) vs {gapstrng} (GAP)")
            failures.extend([(data["label"], col)])
    col = 'number_normal_subgroups'
    if data[col]:
        NormLat = libgap.NormalSubgroups(G)       
        if data[col] != libgap.Size(NormLat):
            print(f"Mismatch in {col}: {data[col]} (data) vs {gapstrng} (GAP)")
            failures.extend([(data["label"], col)])

    return failures


for i in range(10):
    sample_gp = db.gps_groups.random({"order": {"$lte": 2000, "$ne": 1024}}, projection=1)
    print(sample_gp['label'])
    id_nums = sample_gp['label'].split(".")
    G = libgap.SmallGroup(int(id_nums[0]),int(id_nums[1]))
    print(test_small_gps(sample_gp,G))
    
