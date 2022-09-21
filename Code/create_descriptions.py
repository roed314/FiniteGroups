#!/usr/bin/env python3
# Create the descriptions folder

import os
import sys
opj = os.path.join

sys.path.append(os.path.expanduser(opj("~", "lmfdb")))

from lmfdb import db

print(db.gps_groups.count())
