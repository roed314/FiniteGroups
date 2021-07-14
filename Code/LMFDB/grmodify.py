import sys, json, re, os

HOME=os.path.expanduser("~")
sys.path.append(os.path.join(HOME, 'lmfdb'))
from lmfdb import db

cnt=0
cnt2=0

with open("grdata.out") as fh:
 with open("diagramxlist", "w") as fout:
   fout.write('[*\n')
   first = True

   for line in fh.readlines():
    line.strip()
    cnt += 1
    if re.match(r'\S', line):
        cnt2 +=1
        line = line.replace(r"'", r'"')
        l = json.loads(line)
        final=l[1]
        for a in final:
            #print ({'label': '%s.%s'%(lab, a[0])}, {'diagram_x': a[1]})
            s= '' if first else ','
            first = False
            s+='<"{}", {}>\n'.format(a[0], int(round(a[1])))
            fout.write(s)
   fout.write('*]\n')

print ("{} lines from {}\n".format(cnt2,cnt))
