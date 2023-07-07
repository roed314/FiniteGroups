#!/usr/bin/env -S sage -python

from .cloud_collect import parse
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("n", type=int)
parser.add_argument("total", type=int)
parser.add_argument("fname")
args = parser.parse_args()

print(args.n, args.total, args.fname, parse(r"(C_2\times D_4):S_5"))
