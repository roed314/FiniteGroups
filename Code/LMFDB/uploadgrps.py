import os, sys

HOME=os.path.expanduser("~")
sys.path.append(os.path.join(HOME, 'lmfdb'))

from lmfdb import db

di = {'gps_char': 'cchar.data',
      'gps_groups_cc': 'ccs.data',
      'gps_crep': 'glnc.data',
      'gps_qrep': 'glnq.data',
      'gps_groups': 'groups.data',
      'gps_qchar': 'qchar.data',
      'gps_subgroups': 'subs.data'}

for k in di.keys():
    print ("Doing "+ k)
    db[k].delete({})
    db[k].copy_from(di[k])

