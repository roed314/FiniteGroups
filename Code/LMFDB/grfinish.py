import sys, json, re, os
HOME=os.path.expanduser("~")
sys.path.append(os.path.join(HOME, 'lmfdb'))

fh=open("grdata.out")
from lmfdb import db

adict = {}

for line in fh.readlines():
    line.strip()
    if re.match(r'\S', line):
        line = line.replace(r"'", r'"')
        l = json.loads(line)
        #lab = l[0]
        final=l[1]
        for a in final:
            adict[a[0]] = int(round(a[1]))
            #print ({'label': '%s.%s'%(lab, a[0])}, {'diagram_x': a[1]})
            #db.gps_subgroups.upsert({'label': '%s'%(a[0])}, {'diagram_x': int(round(a[1]))})

#for a in final:
#  db.gps_subgroups.upsert({'label': '%s.%s'%(gp, a[0])}, {'diagram_x': a[1]})

def modif(ent):
    global adict
    lab = ent['label']
    if lab in adict:
        ent['diagram_x'] = adict[lab]
    return ent

db.gps_subgroups.rewrite(modif)

fh.close()
