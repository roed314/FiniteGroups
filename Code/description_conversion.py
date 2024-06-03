

# ['GLFp', 'GLFq', 'GLZ', 'GLZN', 'GLZq', 'Lie']
def representation_to_description(order, reps, rtype):
    rep = reps[rtype]
    if rtype == "PC":
        if "pres" in rep:
            return f"{order}pc{','.join(str(c) for c in rep['pres'])}"
        else:
            return f"{order}PC{rep['code']}"
    if rtype == "Lie":
        return f"{rep['family']}({rep['d']},{rep['q']})"
    gens = ','.join(str(g) for g in rep['gens'])
    if rtype == "Perm":
        return f"{rep['d']}Perm{gens}"
    if rtype == "GLZ":
        return f"{rep['d']},0,{rep['b']}MAT{gens}"
    if rtype in ["GLZN", "GLFp"]:
        R = str(rep['p'])
    elif rtype == "GLZq":
        R = str(rep['q'])
    else:
        R = f"q{rep['q']}"
    return f"{rep['d']},{R}MAT{gens}"

# description_to_representation is more complicated, and is currently implemented in create_descriptions.py:make_representations_dict
