#!/usr/local/bin/sage -python
# -*- coding: utf-8 -*-
r""" 

Inserts links to images of representations associated with characters

Takes one argument, q or c to say which type of representations to do.

"""

import sys, time, os
import re
import json

HOME=os.path.expanduser("~")
sys.path.append(os.path.join(HOME, 'lmfdb'))

from lmfdb import db

adict = {}

typ = sys.argv[1]

if typ=="q":
    fname='QQchars2reps'
    table = db.gps_qchar
else:
    fname='CCchars2reps'
    table = db.gps_char

f = open(fname, "r")
print ()
print ("File %s" % fname)
l = f.readline()
while l:
    l=l.strip()
    ab=l.split(' ')
    adict[ab[0]] = ab[1]
    l = f.readline()

f.close()

def modif(ent):
    global adict
    lab = ent['label']
    if lab in adict:
        ent['image'] = adict[lab]
    return ent

table.rewrite(modif)


#    char = table.lucky({'label': ab[0]})
#    if char:
#        table.upsert({'label': ab[0]}, {'image': ab[1]})
#    l = f.readline()

