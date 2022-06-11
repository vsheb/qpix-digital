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
    
while(timeNow < timeEnd):

    for asic in qpa:
        newProcessItems = asic.Process(timeNow - timeEpsilon)
        if newProcessItems:
            print("WARNING: ASIC had things left to do at next maor time step")

    procQueue.AddQueueItem(qpa[0][0], 3, QPByte(tickNow, [], None, None), timeNow)

    while(procQueue.Length() > 0):

        nextItem = procQueue.PopQueue()
        qpa.ProcessArray(procQueue, nextItem.inTime)

        newProcessItems = nextItem.asic.ReceiveData(nextItem)
        if newProcessItems:
            for item in newProcessItems:
                procQueue.AddQueueItem(*item)

        qpa.ProcessArray(procQueue, nextItem.inTime)

    eventTimes.append(qpa._daqNode._absTimeNow-timeNow)
    hitsPerEvent.append(qpa._daqNode.daqHits)
    qpa._daqNode.daqHits = 0
    timeNow += deltaT
    tickNow += deltaTick

print("MAX QUEUE DEPTHS")
# Check the current queue depths
for asic in qpa:
    print(str(asic.row)+" "+str(asic.col)+" "+str(asic._maxLocalDepth)+" ",end='')
    for d in range(0,4):
      print(str(asic.maxFifoDepths[d])+" ",end='')
    print()

# print("PROCESSING TIMES")
# for i in range(0,len(eventTimes[-10:])):
#   print(str(eventTimes[i]))

# print("HITS PER EVENT")
# for i in range(0,len(hitsPerEvent)[-10:]):
#   print(str(hitsPerEvent[i]))

qpa._timeNow = timeNow
qpa._tickNow = tickNow

qpa.Calibrate(1)
qpa.Calibrate(1)
qpa.PrintTimeMap()