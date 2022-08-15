#!/usr/bin/python3

import QpixAsicArray as qparray
from QpixAsic import QPByte, ProcQueue
import random
import numpy as np

random.seed(2)
qpa = qparray.QpixAsicArray(2, 2, debug=0.0)

qpa.Calibrate(20e-4)

print("\ndaq hits:", qpa._daqNode.daqHits)
data = qpa._daqNode.daqHits > 0
while data == True:
    
    hit = qpa._daqNode._localFifo.Read()
    if hit is None:
        data = False
    else:
        print(hit)