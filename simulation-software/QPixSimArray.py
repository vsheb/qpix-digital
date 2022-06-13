#!/usr/bin/python3

import QpixAsicArray as qparray
from QpixAsic import QPByte, ProcQueue
import random
import numpy as np
random.seed(2)
qpa = qparray.QpixAsicArray(2, 2, debug=0.0)

timeNow = 0.
timeEnd = 4.0
tickNow = 0
deltaT = 1e-6
deltaTick = 50e6
timeEpsilon = 1e-6
eventTimes = []
hitsPerEvent, eventTimes = [], []
procQueue = ProcQueue()

qpa._timeNow = timeNow
qpa._tickNow = tickNow

qpa.Calibrate(1)
qpa.Calibrate(3)
qpa.PrintTimeMap()