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
  def __init__(self, hitTime, channelList, originRow, originCol, data=None):
    self.hitTime     = hitTime
    self.originRow   = originRow
    self.originCol   = originCol
    self.channelMask = 0
    # extra data to lug around for commands send to ASICs
    self.data = data
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
  4 - state, flag to determine how individual ASIC receiving data should behave
  '''
  def __init__(self, asic, dir, pixelHit, inTime, command=None):
    self.asic = asic
    self.dir = dir
    self.pixelHit = pixelHit
    self.inTime = inTime
    self.command = command
    self._nextItem = None

  def __gt__(self, otherItem):
    '''
    define that comparing process items based on what inTime the item should be
    processed
    '''
    if isinstance(otherItem, ProcItem):
      return self.inTime > otherItem.inTime
    else:
      return NotImplementedError

class ProcQueue:
  """
  Processing queue which sorts ProcItems in ascending time.
  """
  def __init__(self, procItem=None):
    self._curItem = procItem
    self._entries = 0

  def AddQueueItem(self, asic, dir, pixelHit, inTime, command=None):
    '''
    refactor
    '''
    procItem = ProcItem(asic, dir, pixelHit, inTime, command)
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
  _localQueues   - Queue 0/1 are a ping/pong buffer mechanism
                   You switch from one to another upon receipt of a timestamp
  _curLocalQueue - Tells us whether we're in ping or pong state
  _remoteQueues  - A list of lists, one for each side, N E S W, which stores hits
  connections  - list of pointers to adjacent asics
  """
  def __init__(self, fOsc = 50e6, nPixels = 16, randomRate = 1.0/9.0, timeout = 0.5, row = None, col = None,
               isDaqNode = False, transferTicks = 4*66, debugLevel=0):
    # basic asic parameters
    self.nPixels        = 16
    self.fOsc           = fOsc
    self.tOsc           = 1.0/fOsc
    self._curLocalQueue = 0
    self.lastTsDir      = None
    self._maxLocalDepth = 0
    self.state          = 0
    self.randomRate     = randomRate
    self.row            = row
    self.col            = col
    # timing, absolute and relative with random starting phase
    self.timeoutStart   = 0
    self.timeout        = timeout
    self.transferTicks  = transferTicks # why 264 transfer ticks?
    self.transferTime = self.transferTicks * self.tOsc
    self.lastAbsHitTime = [0] * self.nPixels
    self._absTimeNow    = 0
    self.relTimeNow     = (random.random()-0.5) * self.tOsc
    self.relTicksNow    = 0
    # daq node Configuration
    self.isDaqNode      = isDaqNode
    if self.isDaqNode:
      self.daqHits        = 0
      self.pixelData = {}
    # queues
    self._localQueues   = [[],[]] #buffer depths
    self.connections    = [None] * 4
    self._remoteQueues  = [[],[],[],[]] #buffer depths
    self.maxConnDepths  = [0,0,0,0]
    # additional
    self._debugLevel = debugLevel
    self._measurements = 0 # number of measurements made
    self._measuredTime = []
    self._localTransmissions = 0
    self._remoteTransmissions = 0
    self._hitReceptions = 0


  def __repr__(self):
    self.PrintStatus()
    return ""

  def PrintStatus(self):
    print("ASIC ("+str(self.row)+","+str(self.col)+") ", end="")
    print("STATE "+str(self.state),end='')
    print("N_LOCAL(A,B) "+str(len(self._localQueues[0])) + "," + str(len(self._localQueues[1])),end='')
    print("N_REMOTE(N,E,S,W) ",end='')
    for d in range(4):
      print(str(len(self._remoteQueues[d])) + ",",end='')
    print("t = "+str(self._absTimeNow), ", trel ="+str(self.relTimeNow))
    print("ticks = "+str(self.relTicksNow))
    print("Measurements:", self._measurements, "Local Transactions:", self._localTransmissions, end="")
    print("Remote Transactions:", self._remoteTransmissions, "Receptions:", self._hitReceptions)

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
    queueItem - tuple of (asic, dir, hit, inTime)

    pixelData records the ticks from when the Daq receives data and the ticks 
    of the asic when it received the ask
    """
    inDir     = queueItem.dir # direction the signal came from
    inHit     = queueItem.pixelHit # the time the asic was asked
    inTime    = queueItem.inTime # the time the information will be received
    inCommand = queueItem.command

    # how a DAQNode records and stores data
    if self.isDaqNode:
      print(f'compare {queueItem.inTime} with {self._absTimeNow}')
      self.UpdateTime(queueItem.inTime)
      self.daqHits += 1
      if self._debugLevel > 0:
        print(f"DAQ-{self.relTicksNow} ",end=' ')
        print(f"from: ({inHit.originRow},{inHit.originCol})",end='\n\t')
        print(f"Hit Time: {inHit.hitTime} "+format(inHit.channelMask,'016b'),end='\n\t')
        print(f"absT: {inTime}", end='\n\t')
        print(f"tDiff (ns): {(self.relTimeNow-inTime)*1e9:2.2f}")
      # store relevant data from the hit if necessary
      if hasattr(inHit, "data"):
        print(f'hit time of this data is {inHit.hitTime} with ticks {inHit.hitTime * self.fOsc}')
        pixel = f"({inHit.originRow},{inHit.originCol})"
        if pixel not in self.pixelData:
          self.pixelData[pixel] = []
        self.pixelData[pixel].append((self.relTicksNow, inHit.data))
        # print(f"received data! from asic {pixel}", inHit.data)
        print(f"the pixelData for asic {pixel} is {self.pixelData[pixel]} at lab time {self._absTimeNow} \n")
        
        # print(f'the time is {self._absTimeNow}')
        # print(f'the asic ticks are {self.relTicksNow} and sees time {self.relTimeNow}')
        
      return []

    fromAsic = self.connections[inDir]
    if fromAsic is None:
      print("WARNING receiving data from non-existent connection!")
    
    # print("Receive data called for ASIC ("+str(self.row)+","+str(self.col)+")")
    outList = [] 
    fromDaq = inHit.channelMask == 0 and inHit.originCol is None and inHit.originRow is None
    # ^ boolean

    # 0: MEASURING STATE
    if self.state == 0:
      if fromDaq:

        self.lastTsDir = inDir
        self.state = 1
        self._measurements += 1
        transactionCompleteTime = inTime + self.transferTime
        self.UpdateTime(transactionCompleteTime)
        self._measuredTime.append(self.relTimeNow)
        
        # Broadcast
        for i in range(4):
          if i != inDir and self.connections[i]:
            outList.append((self.connections[i] , (i+2)%4, inHit, transactionCompleteTime, inCommand))

        # Build hits on local queues for default inCommand
        if inCommand is None:
          self._GeneratePoissonHits(inTime)
          self._localQueues[self._curLocalQueue].append(PixelHit(inHit.hitTime, [], self.row, self.col))
          if len(self._localQueues[self._curLocalQueue]) > self._maxLocalDepth:
            self._maxLocalDepth = len(self._localQueues[self._curLocalQueue])
          self._curLocalQueue = (self._curLocalQueue + 1) % 2
        # alternative responses to incoming daq nodes here
        else:
          self._command = inCommand
      else:
        print("WARNING lost data! Can't send data while measuring!")

    # Receive in other states, means queue up hits
    else:
      # Don't forward source timestamps
      if inHit.originRow is not None and inHit.originCol is not None:
        # print(str(self.row)+","+str(self.col)+" : adding hit from "+str(inHit.originRow)+","+str(inHit.originCol)+" at "+str(self._absTimeNow))
        self._remoteQueues[inDir].append(inHit)
        self._hitReceptions += 1
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
      for each channel:
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
    print('generating poisson hits')
    tempList = []

    # Generate new hits
    for ch in range(self.nPixels):
      currentTime = self.lastAbsHitTime[ch]
      while currentTime < targetTime:
        p = random.random() #prints random real between 0 and 1
        nextAbsHitTime = currentTime + (-math.log(1.0 - p) / self.randomRate)
        print(f'the next absolute time for hit is {nextAbsHitTime}')
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
    Transmits local and remote data when asked 
    """
    # nothing to process if DAQ or if target time is in past
    if self.isDaqNode or self._absTimeNow > targetTime:
      return []

    # Process incoming commands first
    if hasattr(self, "_command") and self._command is not None:
      # print(f"Asic-{self.row}-{self.col}.{self.state} received broadcast: {self._command}")
      self._command = None
      # all commands build local queues, and the command should build up any 'hit' of interest
      self.state = 1 #transmit local state
      self._localQueues[(self._curLocalQueue+1)%2].append(PixelHit(self._measuredTime[-1], [], self.row, self.col, data=self.relTicksNow)) #relTicks now is the total number of ticks of the ASIC

    if self.state == AsicStates.Measure.value:
      return self._processMeasuringState(targetTime)

    if self.state == AsicStates.TransmitLocal.value:
      # print(f'processing transmission from local state for asic ({self.row}, {self.col})')
      return self._processTransmitLocalState(targetTime)

    if self.state == AsicStates.TransmitRemote.value:
      # print(f'processing transmission from remote state for asic ({self.row}, {self.col})')
      return self._processTransmitRemoteState(targetTime)

    else:
      # undefined state
      print("WARNING! ASIC in undefined state")
      self.state = 0
      return []

  def _processMeasuringState(self, targetTime):
    """
    helper function when processing in Measuring state
    """
    self.UpdateTime(targetTime)
    return []

  def _processTransmitLocalState(self, targetTime):
    """
    helper function for sending local data where it needs to go
    sends a single local state queue item into the outlist
    """

    outList = [] # list to send out
    transactionCompleteTime = self._absTimeNow + self.transferTime
    # print(f'transaction of local data complete in {transactionCompleteTime} for asic ({self.row}, {self.col})')

    # Note that hits come from the prior queue, since _curLocalQueue tracks where we're
    # now storing new hits, so the previous one is the one to empty now.
    if len(self._localQueues[(self._curLocalQueue+1)%2]) > 0:
      hit = self._localQueues[(self._curLocalQueue+1)%2].pop(0)
      outList.append((self.connections[self.lastTsDir], (self.lastTsDir+2)%4, hit, transactionCompleteTime))
      #appends direction to send data, direction data came from, the data, time of data transaction
      self.UpdateTime(transactionCompleteTime)
      self._localTransmissions += 1
      # print(str(self.row)+","+str(self.col)+" : sending local hit to "+DIRECTIONS[self.lastTsDir]+" at "+str(transactionCompleteTime))
    else:
      self.state = 2
      self.timeoutStart = self._absTimeNow

    return outList

  def _processTransmitRemoteState(self, targetTime):
    """
    helper function for sending remote data where it needs to go
    sends a single remote queue item from one of the remote queues 
    """

    # If we're timed out, just kill it
    if self._absTimeNow - self.timeoutStart > self.timeout:
      self.state = 0
      for q in self._localQueues:
        if len(q) > 0:
          print("Lost "+str(len(q))+" hits that were left to forward!")
      self._localQueues = [[], []]
      return []

    hitsToForward = False
    for q in self._remoteQueues:
      if len(q) > 0:
        hitsToForward = True

    # If there's nothing to forward, just bring us up to requested time
    if not(hitsToForward):
      self.UpdateTime(targetTime)
      if self._absTimeNow - self.timeoutStart > self.timeout:
        self.state = 0
      return []
    else:
      outList = []
      transactionCompleteTime = self._absTimeNow + self.transferTime
      hit = None
      for cq in self._remoteQueues:
        if len(cq) > 0:
          hit = cq.pop(0)
          break
      if hit:
        # print(str(self.row)+","+str(self.col)+" : forwarding hit from "+str(hit.originRow)+","+str(hit.originCol)+" at "+str(transactionCompleteTime))
        self._remoteTransmissions += 1
        outList.append((self.connections[self.lastTsDir], (self.lastTsDir+2)%4 , hit, transactionCompleteTime))
        self.UpdateTime(transactionCompleteTime)

      return outList

  def UpdateTime(self, absTime):
    """
    absTime - the time an asic is asked for data

    function keeps track of updating absTime and performs necessary updates to
    relTime and relTicksNow any time that absTime is updated. 
    
    Direct assignments should not be made to absTime
    """
    self._absTimeNow = absTime

    # only update the relTime if the asic needs to
    if self._absTimeNow > self.relTimeNow:
      t_diff =  self._absTimeNow - self.relTimeNow 
      cycles = int(t_diff/self.tOsc) + 1

      # update the local clock cycles
      self.relTimeNow += cycles * self.tOsc
      self.relTicksNow += cycles