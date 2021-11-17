import sys, json, re, os
HOME=os.path.expanduser("~")
sys.path.append(os.path.join(HOME, 'lmfdb'))

from lmfdb import db

for fn in ["grdata2", "grdata_aut2"]:
  print ("Reading "+fn)
  fh=open(fn)
  for line in fh.readlines():
    line.strip()
    if re.match(r'\S', line):
        line = line.replace(r"'", r'"')
        #print (line)
        l = json.loads(line)
        ambient = l[0]
        final=l[1]
        for a in final:
            full_label = "%s.%s"%(ambient, a[0])
            print ({'label': '%s'%(full_label)}, {'diagram_x': a[1]})
            if fn == "grdata2":
                db.gps_subgroups.upsert({'label': full_label}, {'diagram_x': int(round(a[1]))})
            else:
                db.gps_subgroups.upsert({'label': full_label}, {'diagram_aut_x': int(round(a[1]))})
  fh.close()

#for a in final:
#  db.gps_subgroups.upsert({'label': '%s.%s'%(gp, a[0])}, {'diagram_x': a[1]})

