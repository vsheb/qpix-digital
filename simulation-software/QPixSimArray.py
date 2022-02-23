#!/usr/bin/python3

import QpixAsicArray as qparray
from QpixAsic import PixelHit, ProcQueue
import random
import numpy as np
random.seed(2)
qpa = qparray.QpixAsicArray(16, 16, debug=0.0)

timeNow = 1.
timeEnd = 4.0
tickNow = 50e6
deltaT = 1.0
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

    procQueue.AddQueueItem(qpa[0][0], 3, PixelHit(tickNow, [], None, None), timeNow)

    while(procQueue.Length() > 0):

        nextItem = procQueue.PopQueue()
        qpa.ProcessArray(procQueue, nextItem.absTime)

        newProcessItems = nextItem.asic.ReceiveData(nextItem)
        if newProcessItems:
            for item in newProcessItems:
                procQueue.AddQueueItem(*item)

        qpa.ProcessArray(procQueue, nextItem.absTime)

    eventTimes.append(qpa._daqNode.absTimeNow-timeNow)
    hitsPerEvent.append(qpa._daqNode.daqHits)
    qpa._daqNode.daqHits = 0
    timeNow += deltaT
    tickNow += deltaTick

print("MAX QUEUE DEPTHS")
# Check the current queue depths
for asic in qpa:
    print(str(asic.row)+" "+str(asic.col)+" "+str(asic._maxLocalDepth)+" ",end='')
    for d in range(0,4):
      print(str(asic.maxConnDepths[d])+" ",end='')
    print()

print("PROCESSING TIMES")
for i in range(0,len(eventTimes)):
  print(str(eventTimes[i]))

print("HITS PER EVENT")
for i in range(0,len(hitsPerEvent)):
  print(str(hitsPerEvent[i]))