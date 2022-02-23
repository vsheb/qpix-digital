#!/usr/bin/python3

import random
import math
import time
from enum import Enum

#Enum-like things
DIRECTIONS = ("North", "East", "South", "West")

class AsicStates(Enum):
  Measure = 0
  TransmitLocal = 1
  TransmitRemote = 2

class PixelHit:
  """
  Something like a struct to store actual hits.
  A hit corresponds to what would be a bitmask of channels hit for a given timestamp
  We'll just treat that mask as a list of channels for now
  """
  def __init__(self, hitTime, channelList, originRow, originCol):
    self.hitTime     = hitTime
    self.originRow   = originRow
    self.originCol   = originCol
    self.channelMask = 0
    for ch in channelList: 
      self.channelMask |= 0x1 << ch

  def AddChannel(self, channel):
    self.channelMask |= 0x1 << channel

class ProcItem:
  '''
  Process item controlled by ProcQueue.
  0 - asic, the ASIC being pushed to
  1 - direction, where the new entry came from
  2 - hit, a PixelHit object
  3 - absTime, absolute time that the data would be received
  '''

  def __init__(self, asic, dir, pixelHit, absTime):
    self.asic = asic
    self.dir = dir
    self.pixelHit = pixelHit
    self.absTime = absTime
    self._nextItem = None

  def __gt__(self, otherItem):
    '''
    define that comparing process items based on what absTime the item should be
    processed
    '''
    if isinstance(otherItem, ProcItem):
      return self.absTime > otherItem.absTime
    else:
      return NotImplementedError

class ProcQueue:
  """
  Processing queue which sorts ProcItems in ascending time.
  """
  def __init__(self, procItem=None):
    self._curItem = procItem
    self._entries = 0

  def AddQueueItem(self, asic, dir, pixelHit, absTime):
    '''
    refactor
    '''
    procItem = ProcItem(asic, dir, pixelHit, absTime)
    self._AddQueueItem(procItem)

  def _AddQueueItem(self, procItem):
    '''
    include a new process item, inserting into list at appropriate time
    '''
    newItem = procItem
    curItem = self._curItem
    self._entries += 1

    if curItem is None:
      self._curItem = newItem
    elif curItem > newItem:
      h = self._curItem
      self._curItem = newItem
      self._curItem._nextItem = h
    else:
      while newItem > curItem and curItem._nextItem is not None:
        curItem = curItem._nextItem 
      newItem._nextItem = curItem._nextItem
      curItem._nextItem = newItem

    return self._entries

  def PopQueue(self):
    if self._curItem is None:
        return None
    self._entries -= 1
    data = self._curItem
    self._curItem = self._curItem._nextItem
    return data

  def SortQueue(self):
    '''
    deprecated
    '''
    pass

  def Length(self):
    return self._entries

class QPixAsic:
  """
  A Q-Pix ASIC fundamentally consists of:
  An oscillator of nominal frequency (~50 MHz)
  A number of channels (nominally 16 or 32)
    - When a given channel is "hit", a timestamp is generated
  Four communications interfaces to contatct nearest neighbors
  Each has its own queue

  fOsc       - Oscillator Frequency in Hz
  lastTsDir  - Last direction timestamp was accepted from
  state      - IDLE/MEASURING, - REPORT_LOCAL, - REPORT_REMOTE
  queue      - Queue 0/1 are a ping/pong buffer mechanism
               You switch from one to another upon receipt of a timestamp
  _curLocalQueue - Tells us whether we're in ping or pong state
  _remoteQueues  - A list of lists, one for each side, N E S W, which stores hits
  """
  def __init__(self, fOsc = 50e6, nPixels = 16, randomRate = 1.0/9.0, timeout = 0.5, row = None, col = None,
               isDaqNode = False, transferTicks = 4*66, debugLevel=0):
    # relevant asic parameters
    self.nPixels        = 16
    self.fOsc           = fOsc
    self.tOsc           = 1.0/fOsc
    self._curLocalQueue = 0
    self.lastTsDir      = None
    self._maxLocalDepth = 0
    self.state          = 0
    self.randomRate     = randomRate
    self.transferTicks  = transferTicks
    self.timeoutStart   = 0
    self.timeout        = timeout
    self.row            = row
    self.col            = col
    # timing
    self.lastAbsHitTime = [0] * self.nPixels
    self.absTimeNow     = 0
    self.absTicksNow    = 0
    # daq node
    self.isDaqNode      = isDaqNode
    self.daqHits        = 0
    # queues
    self._localQueues   = [[],[]]
    self.connections    = [None] * 4
    self._remoteQueues  = [[],[],[],[]]
    self.maxConnDepths  = [0,0,0,0]
    # additional
    self._debugLevel = debugLevel
    self._measurements = 0
    self._transmissions = 0
    self._receptions = 0

  def __repr__(self):
    self.PrintStatus()
    return ""

  def PrintStatus(self):
    print(" ASIC ("+str(self.row)+","+str(self.col)+") ", end="")
    print(" STATE "+str(self.state),end='')
    print(" N_LOCAL(A,B) "+str(len(self._localQueues[0])) + "," + str(len(self._localQueues[1])),end='')
    print(" N_REMOTE(N,E,S,W) ",end='')
    for d in range(0,4):
      print(str(len(self._remoteQueues[d])) + ",",end='')
    print(" t = "+str(self.absTimeNow))
    print(" ticks = "+str(self.absTicksNow))
    print("Measurements:", self._measurements, "Transactions:", self._transmissions)

  def CountConnections(self):
    nConnected = 0
    for conn in self.connections:
      if conn:
        nConnected += 1
    return nConnected

  def HasConnection(self, dir):
    if self.connections[dir]:
      return 1
    else:
      return 0

  def ReceiveData(self, queueItem:ProcItem):
    """
    Receive data from a neighbor
    queueItem - tuple of (asic, dir, hit, absTime)
    """
    inDir     = queueItem.dir
    inHit     = queueItem.pixelHit
    inAbsTime = queueItem.absTime

    if self.isDaqNode:
      # print("DAQ node received: ",end=' ')
      # print("from: ("+str(inHit.originRow)+","+str(inHit.originCol)+")",end=' ')
      # print("Hit: "+str(inHit.hitTime)+" , "+format(inHit.channelMask,'016b'),end=' ')
      # print("absT: "+str(inAbsTime))
      self.absTimeNow = inAbsTime
      self.daqHits    += 1
      return []

    # print("Receive data called for ASIC ("+str(self.row)+","+str(self.col)+")")
    outList = [] 
    # 0: MEASURING STATE
    #    Wait for timestamps... when we see one:
    #    a) Mark where the timestamp came from
    #    b) Generate Poisson hits up to the current time
    #    c) Add the timestamp as the last entry to the queue
    #    d) Swap _localQueues
    #    e) Pass interrogation on to all other neighbors
    #       (i.e., add them to the outList)
    #    f) Advance to the next state
    if self.state == 0:
      # If this is a timestamp from the DAQ node, do the below steps
      if inHit.channelMask == 0 and inHit.originCol == None and inHit.originRow == None:
        # a) Mark where the timestamp came from
        self.lastTsDir = inDir
        # b) Generate Poisson hits up to the current AbsTime
        self._GeneratePoissonHits(inAbsTime)
        # c) Add the timestamp as the last entry to the queue
        self._localQueues[self._curLocalQueue].append(PixelHit(inHit.hitTime, [], self.row, self.col))
        #  update max queue depth
        if len(self._localQueues[self._curLocalQueue]) > self._maxLocalDepth:
          self._maxLocalDepth = len(self._localQueues[self._curLocalQueue])
        # d) Swap recording _localQueues
        self._curLocalQueue = (self._curLocalQueue + 1) % 2
        # e) Pass interrogation to all other neighbors
        transactionCompleteTime = inAbsTime + self.transferTicks * self.tOsc
        self.absTimeNow = transactionCompleteTime
        for i in range(4):
          if i != inDir and self.connections[i]:
            outList.append((self.connections[i] , (i+2)%4, inHit, transactionCompleteTime))
        # f) Advance to the next state
        self.state = 1
        self._measurements += 1
      # If the inbound hit is anything else, don't do anything, the data is lost
      else:
        print("WARNING lost data! Can't send data while measuring!")

    # If we're in any other state, we should just queue up data into our local lists
    else:
      # Don't forward source timestamps
      if inHit.originRow is not None and inHit.originCol is not None:
        # print(str(self.row)+","+str(self.col)+" : adding hit from "+str(inHit.originRow)+","+str(inHit.originCol)+" at "+str(self.absTimeNow))
        self._remoteQueues[inDir].append(inHit)
        self._receptions += 1
        # update max queue depth
        if len(self._remoteQueues[inDir]) > self.maxConnDepths[inDir]:
          self.maxConnDepths[inDir] = len(self._remoteQueues[inDir])

    return outList

  def _GeneratePoissonHits(self, targetTime):
    """
    Generate Poisson hits for the time step ##
    Distribution of inter-arrival times can be modeled by throwing
    p = Uniform(0,1) and feeding it to -ln(1.0 - p)/aveRate
    General strategy for moving forward to some timestep is:
      foreach channel:
        currentTime = now
        while currentTime < targetTime:
          generate nextHitTime from distribution above
          if currentTime + nextHitTime < targetTime:
            Calculate number of ticks for timestamp and add it to the current queue
          else:
            this is last hit for this pixel, add the next time to the alternate queue
      Sort the overall list by timestamp
      foreach unique entry in the timestamp list, create a hit with proper parameters,
      add it to the queue (A or B)
    """
    tempList = []

    # Generate new hits
    for ch in range(self.nPixels):
      currentTime = self.lastAbsHitTime[ch]
      while currentTime < targetTime:
        p = random.random()
        nextAbsHitTime = currentTime + (-math.log(1.0 - p) / self.randomRate)
        nextRelHitTime = int(math.floor(nextAbsHitTime / self.tOsc))
        if nextAbsHitTime < targetTime:
          tempList.append([ch,nextRelHitTime])
          currentTime = nextAbsHitTime
          self.lastAbsHitTime[ch] = currentTime
        elif nextAbsHitTime > targetTime:
          currentTime             = targetTime
          self.lastAbsHitTime[ch] = targetTime
    tempList.sort(key=lambda x : x[1], reverse = False)
    self._CombineHitsAndAppend(tempList, self._localQueues[self._curLocalQueue])

    return len(tempList)

  def _CombineHitsAndAppend(self, hitList, queue):
    '''
    helper function within GeneratePoissonHits
    '''
    lastEntry = None
    nextEntry = None
    for i in range(len(hitList)):
      thisTime = hitList[i][1]
      thisCh = hitList[i][0]
      if not(lastEntry):
        lastEntry = PixelHit(thisTime, [thisCh], self.row, self.col)
      else:
        if thisTime == lastEntry.hitTime:
          lastEntry.AddChannel(thisCh)
        else:
          queue.append(lastEntry)
          lastEntry = PixelHit(thisTime, [thisCh], self.row, self.col)
    if len(hitList) > 0:
      queue.append(lastEntry)
    return None

  def Process(self, targetTime):
    """
    This is a state where we just process the current goings ons for this ASIC
    """
    # nothing to process if DAQ or if target time is in past
    if self.isDaqNode or self.absTimeNow > targetTime:
      return []

    if self.state == 0:
      return self._processMeasuringState(targetTime)

    elif self.state == 1:
      return self._processTransmitLocalState(targetTime)

    elif self.state == 2:
      return self._processTransmitRemoteState(targetTime)

    # undefined state
    print("WARNING! ASIC in undefined state")
    self.state = 0
    return []

  def _processMeasuringState(self, targetTime):
    """
    helper function when processing in Measuring state
    """
    self.absTimeNow = targetTime
    return []

  def _processTransmitLocalState(self, targetTime):
    """
    helper function for sending local data where it needs to go
    """

    outList = []
    transactionCompleteTime = self.absTimeNow + self.transferTicks * self.tOsc
    self._transmissions += 1

    # Note that hits come from the prior queue, since _curLocalQueue tracks where we're
    # now storing new hits, so the previous one is the one to empty now.
    if len(self._localQueues[(self._curLocalQueue+1)%2]) > 0:
      hit = self._localQueues[(self._curLocalQueue+1)%2].pop(0)
      outList.append((self.connections[self.lastTsDir], (self.lastTsDir+2)%4, hit, transactionCompleteTime))
      self.absTimeNow = transactionCompleteTime
      # print(str(self.row)+","+str(self.col)+" : sending local hit to "+DIRECTIONS[self.lastTsDir]+" at "+str(transactionCompleteTime))
    else:
      self.state = 2
      self.timeoutStart = self.absTimeNow

    return outList

  def _processTransmitRemoteState(self, targetTime):
    """
    helper function for sending remote data where it needs to go
    """

    # If we're timed out, just kill it
    if self.absTimeNow - self.timeoutStart > self.timeout:
      self.state = 0
      for q in self._localQueues:
        if len(q) > 0:
          print("Lost "+str(len(q))+" hits that were left to forward!")
      self._localQueues = [[], []]
      return []

    # If there's nothing to forward, just bring us up to requested time
    hitsToForward = False
    for q in self._remoteQueues:
      if len(q) > 0:
        hitsToForward = True
    if not(hitsToForward):
      self.absTimeNow = targetTime
      if self.absTimeNow - self.timeoutStart > self.timeout:
        self.state = 0
      return []

    # Otherwise, check if there's a hit to forward, if so, forward it
    # Using a fixed priority here
    outList = []
    transactionCompleteTime = self.absTimeNow + self.transferTicks * self.tOsc
    hit = None
    for cq in self._remoteQueues:
      if len(cq) > 0:
        hit = cq.pop(0)
        break
    if hit:
      # print(str(self.row)+","+str(self.col)+" : forwarding hit from "+str(hit.originRow)+","+str(hit.originCol)+" at "+str(transactionCompleteTime))
      self._transmissions += 1
      outList.append((self.connections[self.lastTsDir], (self.lastTsDir+2)%4 , hit, transactionCompleteTime))
      self.absTimeNow = transactionCompleteTime
    return outList