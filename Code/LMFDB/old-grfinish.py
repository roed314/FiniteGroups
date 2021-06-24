import sys, json, re, os
HOME=os.path.expanduser("~")
sys.path.append(os.path.join(HOME, 'lmfdb'))

fh=open("grdata.out")
from lmfdb import db
for line in fh.readlines():
    line.strip()
    if re.match(r'\S', line):
        line = line.replace(r"'", r'"')
        print (line)
        l = json.loads(line)
        lab = l[0]
        final=l[1]
        for a in final:
            #print ({'label': '%s.%s'%(lab, a[0])}, {'diagram_x': a[1]})
            db.gps_subgroups.upsert({'label': '%s'%(a[0])}, {'diagram_x': int(round(a[1]))})

#for a in final:
#  db.gps_subgroups.upsert({'label': '%s.%s'%(gp, a[0])}, {'diagram_x': a[1]})

fh.close()
