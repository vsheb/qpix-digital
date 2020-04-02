#!/usr/bin/python3

from QpixAsic import *
import random
import math
import sys

# This is a single trial array

# Seed the RNG
random.seed(2)

# Debug status
debugLevel = 1 #5 - debug

# Create an array of QPixAsics
nRows = 16
nCols = 16
nPixs = 16

# Hit rate per pixel
randomRatePerPixel = 1./9.

# Ticks per transaction
serialTransferTicks = 4*66

# Nominal frequency and associated spread (as 1-sigma in percent)
fNominal  = 50e6
pctSpread = 0.05

# Time interval between DAQ-node timestamps
deltaT = 1.0
# Ticks in nominal oscillator between DAQ-node timestamps
deltaTick = int(math.floor(deltaT * fNominal))
# Small time interval used for stepping simulation almost up to current
timeEpsilon = 1e-6

# How long to run the simulation
timeEnd = 2.0

# Create the array and populate all positions
asicMatrix = [[None for i in range(nCols)] for j in range(nRows)] 

for i in range(0,nRows):
  for j in range(0,nCols):
    # Create the random frequency here
    fThisAsic = random.gauss(fNominal,fNominal*pctSpread)
    # Create an ASIC at this position
    asicMatrix[i][j] = QPixAsic(fThisAsic, nPixs, row = i, col = j, transferTicks = serialTransferTicks, randomRate = randomRatePerPixel)
    ## Debug info
    if debugLevel >= 5:
      print("Created ASIC at row "+str(i)+" col "+str(j)+" with frequency "+str(fThisAsic))

# Create the connections between all ASICs
for i in range(0,nRows):
  for j in range(0,nCols):
    # 0 - North
    # 1 - East
    # 2 - South
    # 3 - West
    if i > 0:
      asicMatrix[i][j].connections[0] = asicMatrix[i-1][j]
    if i < nRows-1:
      asicMatrix[i][j].connections[2] = asicMatrix[i+1][j]
    if j > 0:
      asicMatrix[i][j].connections[3] = asicMatrix[i][j-1]
    if j < nCols-1:
      asicMatrix[i][j].connections[1] = asicMatrix[i][j+1]    

# Create a dummy DAQ node and connect it up to our target
daqNode = QPixAsic(fNominal, 0, isDaqNode = True)
asicMatrix[0][0].connections[3] = daqNode

# Print count of connections vs. position
if debugLevel >= 5:
  print("Connection count per ASIC:")
  for i in range(0,nRows):
    for j in range(0,nCols):
      print( str(asicMatrix[i][j].CountConnections())+" ", end = '')
    print("")

# Print north connections vs. position
if debugLevel >= 5:
  for d in range(0,len(DIRECTIONS)):
    dir = DIRECTIONS[d]
    print("Connections to the "+dir+" per ASIC:")
    for i in range(0,nRows):
      for j in range(0,nCols):
        print( str(asicMatrix[i][j].HasConnection(d))+" ", end = '')
      print("")

# Start time now
timeNow = 0
tickNow = 0
stepNum = 0

# Create an empty processing queue
procQueue = ProcQueue()

timeNow += deltaT
tickNow += deltaTick

# Maximum queue depths
maxConnQueueDepths = [[[0 for i in range(nCols)] for j in range(nRows)] for k in range(4)]
maxSelfQueueDepths = [[0 for i in range(nCols)] for j in range(nRows)]
eventTimes = []
hitsPerEvent = []
iteration = 0

while(timeNow < timeEnd):

  # Print states if they were updated
  if debugLevel == 1:
    print("t = "+str(timeNow))
    for r in range(0,nRows):
      for c in range(0,nCols):
        print(str(asicMatrix[r][c].stateNum),end='')
      print("")

  # Make sure there's nothing to do right now
  # Now iterate through ASICs and keep doing processing on them until
  # they're caught up to the latest time.
  for i in range(0,nRows):
    for j in range(0,nCols):
      newProcessItems = asicMatrix[i][j].Process(timeNow - timeEpsilon)
      if len(newProcessItems) > 0:
        print("WARNING: ASIC ("+str(i)+","+str(j)+") had things left to do at next major time step")
        # Print states if they were updated
        if debugLevel >= 5:
          print("Init: ",end='')
          asicMatrix[i][j].PrintStatus()

  # Add a first timestamp at 1 second
  timestamp = PixelHit(tickNow, [], None, None)
  procQueue.AddQueueItem(asicMatrix[0][0], 3, timestamp, timeNow)

  while(procQueue.Length() > 0):
    nextItem = procQueue.PopQueue()
    nextAsic = nextItem[0]

    # Now iterate through ASICs and keep doing processing on them until
    # they're caught up to the latest time.
    somethingToDo = True
    nextTime = nextItem[3]
    while somethingToDo:
      somethingToDo = False
      for i in range(0,nRows):
        for j in range(0,nCols):
          newProcessItems = asicMatrix[i][j].Process(nextTime)
          for item in newProcessItems:
            procQueue.queue.append(item)
          procQueue.SortQueue()
          if len(newProcessItems) > 0:
            somethingToDo = True

            # Print states if they were updated
            if debugLevel == 1:
              print("t = "+str(procQueue.queue[0][3]))
              for r in range(0,nRows):
                for c in range(0,nCols):
                  print(str(asicMatrix[r][c].stateNum),end='')
                print("")
#              print("PrQ: ",end='')
#              asicMatrix[i][j].PrintStatus()


    newQueueItems = nextAsic.ReceiveData(nextItem)
    for item in newQueueItems:
      procQueue.queue.append(item)
      procQueue.SortQueue()

    # Now iterate through ASICs and keep doing processing on them until
    # they're caught up to the latest time.
    somethingToDo = True
    nextTime = nextItem[3]
    while somethingToDo:
      somethingToDo = False
      for i in range(0,nRows):
        for j in range(0,nCols):
          newProcessItems = asicMatrix[i][j].Process(nextTime)
          for item in newProcessItems:
            procQueue.queue.append(item)
          procQueue.SortQueue()
          if len(newProcessItems) > 0:
            somethingToDo = True

            # Print states if they were updated
            if debugLevel == 1:
              print("t = "+str(procQueue.queue[0][3]))
              for r in range(0,nRows):
                for c in range(0,nCols):
                  print(str(asicMatrix[r][c].stateNum),end='')
                print("")

            # Print states if they were updated
            if debugLevel >= 5:
              print("AfQ: ",end='')
              asicMatrix[i][j].PrintStatus()

    stepNum += 1

  eventTimes.append(daqNode.absTimeNow-timeNow)
  hitsPerEvent.append(daqNode.daqHits)
  daqNode.daqHits = 0
  timeNow += deltaT
  tickNow += deltaTick
  iteration += 1
  if iteration%1 == 0:
    print("time is now: "+str(timeNow), file=sys.stderr)

print("MAX QUEUE DEPTHS")
# Check the current queue depths
for i in range(0,nRows):
  for j in range(0,nCols):
    print(str(i)+" "+str(j)+" "+str(asicMatrix[i][j].maxDepth)+" ",end='')
    for d in range(0,4):
      print(str(asicMatrix[i][j].maxConnDepths[d])+" ",end='')
    print()

print("PROCESSING TIMES")
for i in range(0,len(eventTimes)):
  print(str(eventTimes[i]))

print("HITS PER EVENT")
for i in range(0,len(hitsPerEvent)):
  print(str(hitsPerEvent[i]))
