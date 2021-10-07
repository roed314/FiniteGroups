import sys
import os
import json
from sage.all import *

HOME=os.path.expanduser("~")
sys.path.append(os.path.join(HOME, 'lmfdb'))

fn = "grdata"
fn1 = "grdata1"
if len(sys.argv)>1:
    fn="grdata_aut"
    fn1 = "grdata1_aut"

fh = open(fn)
fho = open(fn1, "w")

for line in fh.readlines():
    #print(line)
    line = line.replace(r"'", r'"')
    l = json.loads(line)
    print(l[0])
    posetinp = zip(l[1],l[2])
    posetinp = dict(posetinp)
    poset= Poset(posetinp)
    pl = poset.plot()
    good = [a for a in pl if isinstance(a, sage.plot.text.Text)]
    final = [[str(z.string), z.x] for z in good]
    final.sort()

    minx=0
    maxx = 100000000000000000
    for a in final:
      if a[1]> minx: minx = a[1]
      if a[1] < maxx: maxx = a[1]


    def adj(val):
      if minx==maxx:
        return 5001
      return int((val-minx)*9999./(maxx-minx))+1

    for j in range(len(final)):
      final[j][1] = adj(final[j][1])

    final[0][1]=5001
    final[len(final)-1][1]=5001
    fho.write("[\"%s\", %s]\n" % (l[0], final))

fh.close()
fho.close()
