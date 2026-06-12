from pathlib import Path
import re

manual = {
    '6048.a': ('2A(2,3)', ['SU(3,3)']),
    '25920.a': ('C(2,3)', ['SU(4,2)']),
    '62400.a': ('2A(2,4)', ['SU(3,4)']),
    '126000.a': ('2A(2,5)', ['PSU(3,5)']),
    '3265920.a': ('2A(3,3)', ['PSU(4,3)']),
    '4680000.a': ('C(2,5)', ['PSp(4,5)', 'Omega(5,5)']),
    '5515776.a': ('2A(2,8)', ['PSU(3,8)']),
    '5663616.a': ('2A(2,7)', ['SU(3,7)', 'PGU(3,7)']),
    '13685760.a': ('2A(4,2)', ['SU(5,2)', 'PGU(5,2)']),
    '42573600.a': ('2A(2,9)', ['SU(3,9)', 'PGU(3,9)']),
    '70915680.a': ('2A(2,11)', ['PSU(3,11)']),
    '138297600.a': ('C(2,7)', ['PSp(4,7)', 'Omega(5,7)']),
    '174182400.a': ('D(4,2)', ['OmegaPlus(8,2)', 'SpinPlus(8,2)']),
    '197406720.a': ('2D(4,2)', ['OmegaMinus(8,2)', 'SpinMinus(8,2)']),
    '811273008.a': ('2A(2,13)', ['SU(3,13)', 'PGU(3,13)']),
    '1018368000.a': ('2A(3,4)', ['SU(4,4)', 'OmegaMinus(6,4)', 'SpinMinus(6,4)', 'PGU(4,4)']),
    '1721606400.a': ('C(2,9)', ['PSp(4,9)', 'Omega(5,9)']),
    '2317678272.a': ('2A(2,17)', ['PSU(3,17)']),
    '4279234560.a': ('2A(2,16)', ['SU(3,16)', 'PGU(3,16)']),
    '4585351680.a': ('B(3,3)', ['Omega(7,3)']),
    '4585351680.b': ('C(3,3)', ['PSp(6,3)']),
    '9196830720.a': ('2A(5,2)', ['PSU(6,2)']),
    '12860654400.a': ('C(2,11)', ['PSp(4,11)', 'Omega(5,11)']),
    '14742000000.a': ('2A(3,5)', ['PSU(4,5)', 'OmegaMinus(6,5)', 'PSOMinus(6,5)']),
    '16938986400.a': ('2A(2,19)', ['SU(3,19)', 'PGU(3,19)']),
    '68518981440.a': ('C(2,13)', ['PSp(4,13)', 'Omega(5,13)']),
    '258190571520.a': ('2A(4,3)', ['SU(5,3)', 'PGU(5,3)']),
    '1004497044480.a': ('C(2,17)', ['PSp(4,17)']),
    '1165572172800.a': ('2A(3,7)', ['PSU(4,7)', 'POmegaMinus(6,7)']),
    '3057017889600.a': ('C(2,19)', ['PSp(4,19)']),
    '4952179814400.a': ('D(4,3)', ['POmegaPlus(8,3)']),
    '10151968619520.a': ('2D(4,3)', ['OmegaMinus(8,3)', 'PSOMinus(8,3)']),
    '23499295948800.a': ('D(5,2)', ['OmegaPlus(10,2)', 'SpinPlus(10,2)']),
    '25015379558400.a': ('2D(5,2)', ['OmegaMinus(10,2)', 'SpinMinus(10,2)']),
    '34693789777920.a': ('2A(3,8)', ['SU(4,8)', 'OmegaMinus(6,8)', 'SpinMinus(6,8)', 'PGU(4,8)']),
    '53443952640000.a': ('2A(4,4)', ['PSU(5,4)']),
    '227787103272960.a': ('2A(6,2)', ['SU(7,2)', 'PGU(7,2)']),
    '228501000000000.a': ('C(3,5)', ['PSp(6,5)']),
    '22837472432087040.a': ('2A(5,3)', ['PSU(6,3)']),
    '65784756654489600.a': ('B(4,3)', ['Omega(9,3)']),
    '65784756654489600.b': ('C(4,3)', ['PSp(8,3)']),
    '7434971050829414400.a': ('2A(7,2)', ['SU(8,2)', 'PGU(8,2)'])}


def manual_tex():
    infile = Path("/scratch/grp/texfix/UpdatedTexNames.txt")
    outfile = Path("/scratch/grp/texfix/UpdatedTexNames1.txt")
    matcher1 = re.compile(r"(?:\{\}\^(?P<chev1twist>\d))?(?P<chev1family>[A-G])_(?P<chev1d>\d)\((?P<chev1q>\d+)\)")
    matcher2 = re.compile(r"(?:\{\}\^)?(?P<chev2twist>\d)?(?P<chev2family>[A-G])\((?P<chev2d>\d+),(?P<chev2q>\d+)\)'?")
    with open(outfile, "w") as Fout:
        with open(infile) as F:
            for line in F:
                label, t = line.strip().split("|")
                if label in manual:
                    _ = Fout.write(f"{label}|{manual[label][1][0]}\n")
                else:
                    if matcher1.fullmatch(label) or matcher2.fullmatch(label):
                        print(line.strip())
                    _ = Fout.write(line)
