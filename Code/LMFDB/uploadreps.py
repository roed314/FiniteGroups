import os, sys

HOME=os.path.expanduser("~")
sys.path.append(os.path.join(HOME, 'lmfdb'))

from lmfdb import db

di = { 'gps_crep': 'glnc.data',
      'gps_qrep': 'glnq.data'}

for k in di.keys():
    print ("Doing "+ k)
    db[k].delete({})
    db[k].copy_from(di[k])

