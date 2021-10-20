from lmfdb import db as mydb
from lmfdb.groups.abstract.web_groups import *
from sage.all import *
import sys, os

HOME=os.path.expanduser("~")
sys.path.append(os.path.join(HOME, 'lmfdb'))


which = 'conj'
fn = "grdata"

if len(sys.argv)>1:
    fn = "grdata_aut"
    which = 'aut'

outf = open(fn,"w")

def dogp(gp):
    print (gp)
    wg = WebAbstractGroup(str(gp))
    if which == 'conj':
        layers = wg.subgroup_lattice
    else:
        layers = wg.subgroup_lattice_aut
    incl = layers[1]
    posetinp = {}
    for a in incl:
      if a[0] in posetinp:
        posetinp[a[0]].append(a[1])
      else:
        posetinp[a[0]] = [a[1]]
    a = [z for z in posetinp.keys()]
    b = [posetinp[z] for z in a]
    outf.write("[\"%s\", %s, %s]\n"%(gp, a, b))

cur = mydb.gps_groups.search()

for xx in cur:
    order = xx['order']
    if not is_prime(order) and order > 7:
      dogp(xx['label'])


#from lmfdb import db
#for a in final:
#  db.gps_subgroups.upsert({'label': '%s.%s'%(gp, a[0])}, {'diagram_x': a[1]})

