#!/usr/bin/env python3

import sys
import glob
import os


def qpix_conv(filename = '') :
    res = [x.split(',') for x in open(filename).readlines()]
    resort = sorted(res, key = lambda x : int(x[2]))
    x_l = [int(l[0]) for l in res]
    x_avg = round(sum(x_l)/len(x_l))
    y_l = [int(l[1]) for l in res]
    y_avg = round(sum(y_l)/len(y_l))

    rebased = [ [int(t[0])-x_avg+6, int(t[1])-y_avg+6, int(t[2])] for t in resort ]

    return rebased

def getnev(path = '.') :
    for fn in glob.glob(os.path.join(path, '*.txt')):
        with open(os.path.join(os.getcwd(), fn), 'r') as f: # open in readonly mode
            n = len(f.readlines())
            print(n)

