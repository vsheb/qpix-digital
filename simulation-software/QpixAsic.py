#!/usr/bin/python3

from audioop import add
from io import IncrementalNewlineDecoder
import random
import math
import time
from enum import Enum
import numpy as np

#Enum-like things
DIRECTIONS = ("North", "East", "South", "West")

class QPExcpetion(Exception):
  pass

class AsicDirections(Enum):
  North = 0
  East = 1
  South = 2
  West = 3

class AsicState(Enum):
  Idle = 0
  TransmitLocal = 1
  TransmitRemote = 2

class QPByte:
  """
  NOTE: refactored PixelHit object! Data that are transferred are Bytes~ NOT
  'hits'. A hit is always a time stamp, but what is transferred is the more
  generic byte.

  This struct-style class stores no more than the 64 bit information transfered
  on a 64 bit Tx/Rx Endeavor protocol.

  This struct should be directly derived from QpixDataFormatType in QpixPkg.vhd
  """
  def __init__(self, hitTime, channelList, originRow, originCol, data=None, wordType=None):
    self.hitTime     = hitTime
    self.originRow   = originRow
    self.originCol   = originCol
    self.wordType = wordType
    self.channelMask = 0
    # extra data to lug around for commands send to ASICs
    self.data = data
    for ch in channelList: 
      self.channelMask |= 0x1 << ch

  def __repr__(self):
    """
    how to represent a Byte when print out
    """
    msg = f"({self.originRow},{self.originCol}): {self.channelMask:04x} @ {self.hitTime} - {self.data}"
    return msg

  def AddChannel(self, channel):
    self.channelMask |= 0x1 << channel

class QPFifo:
  """
  FIFO class to store and manage incoming QPByte data between ASIC connections

  A FIFO can only do two things: Read and Write. Therefore, there should only 
  be two implemented public functions for this class: Read and Write.
  """
  def __init__(self, maxDepth=256):
    self._data = []
    self._maxSize = 0
    self._curSize = 0
    self._maxDepth = maxDepth
    self._full = False
    self._totalWrites = 0

  def Write(self, data=QPByte) -> int:
    """
    Implements a write feature to the Fifo
    ARGS:
      Ensure that the data being stored in the FIFO matches the QPByte
    Returns:
      current number of events stored in the FIFO
    """

    # if not isinstance(data, QPByte):
    #   raise QPException("Can not add this data-type to a QPFifo!")

    self._data.append(data)
    self._curSize += 1
    self._totalWrites += 1

    if self._curSize > self._maxSize:
      self._maxSize = self._curSize

    if self._curSize > self._maxDepth:
      self._full = True

    return self._curSize

  def Read(self) -> QPByte:
    """
    Implements a Readout feature for the FIFO.
    ARGS:
      None
    Returns:
      oldest stored event (First In, First Out)
    """
    if self._curSize > 0:
      self._curSize -= 1
      return self._data.pop(0)
    else:
      return None

class ProcItem:
  '''
  Process item controlled by ProcQueue.
  0 - asic, the ASIC being pushed to
  1 - direction, where the data came from
  2 - QPByte, a QPByte object
  3 - inTime, time that the data would be received, or that the sending asic completes sending QPByte
  4 - command, flag to determine how individual ASIC receiving data should behave
  '''
  def __init__(self, asic, dir, QPByte, inTime, command=None):
    self.asic = asic
    self.dir = dir
    self.QPByte = QPByte
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
  ProcQueue class is the main class which defines the simulation flow. 
  
  It is designed to store ProcItem class objects, which are the basic unit of an ASIC transaction.
  """
  def __init__(self, procItem=None):
    self._curItem = procItem
    self._entries = 0

  def AddQueueItem(self, asic, dir, QPByte, inTime, command=None):
    '''
    refactor
    '''
    procItem = ProcItem(asic, dir, QPByte, inTime, command)
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
  nPixels    - number of analog channels
  lastTsDir  - Last direction timestamp was accepted from
  state      - IDLE/MEASURING, - REPORT_LOCAL, - REPORT_REMOTE
  _localFifo - QPFifo class to manage Read and Write of local data
  _remoteFifos - list of ofur QPFifo class' to manage write of remote ASIC data / transactions
  connections  - list of pointers to adjacent asics
  """
  def __init__(self, fOsc=50e6, nPixels=16, randomRate=20.0 / 1., timeout=1000, row=None, col=None,
               isDaqNode = False, transferTicks=4*66, debugLevel=0):
    # basic asic parameters
    self.nPixels        = 16
    self.fOsc           = fOsc
    self.tOsc           = 1.0/fOsc
    self.lastTsDir      = None
    self._maxLocalDepth = 0
    self.state          = AsicState.Idle
    self.randomRate     = randomRate
    self.row            = row
    self.col            = col
    self.connections    = [None] * 4 
    self._command       = None

    # timing, absolute and relative with random starting phase
    self.timeoutStart   = 0
    self.timeout        = timeout / fOsc
    self.transferTicks  = transferTicks
    self.transferTime   = self.transferTicks * self.tOsc
    self.lastAbsHitTime = [0] * self.nPixels
    self._absTimeNow    = 0
    self.relTimeNow     = (random.random()-0.5) * self.tOsc
    # self.relTimeNow     = 0
    self._startTime     = self.relTimeNow
    self.relTicksNow    = 0

    # daq node Configuration
    self.isDaqNode      = isDaqNode

    # Queues / FIFOs
    self._localFifo   = QPFifo(maxDepth=256)
    self._remoteFifos  = [QPFifo(maxDepth=256), QPFifo(maxDepth=256), QPFifo(maxDepth=256), QPFifo(maxDepth=256)]

    # additional / debug
    self._debugLevel = debugLevel
    self._hitReceptions = 0
    self._measuredTime = []

    # useful things for _InjectHits
    self._times = []
    self._channels = []
    self._lastAsicHitTime = 0

  def __repr__(self):
    self.PrintStatus()
    return ""

  def PrintStatus(self):
    print("ASIC ("+str(self.row)+","+str(self.col)+") ", end="")
    print("STATE:"+str(self.state),end=' ')
    print(f"locFifoSize: {self._localFifo._curSize}")
    print("Remote Sizes (N,E,S,W):",end=' ')
    for d in range(4):
      print(str(self._remoteFifos[d]._curSize) + ",",end=' ')
    print(f"absTime = {self._absTimeNow:0.2e}, trel = {self.relTimeNow:0.2e}")
    print(f"ticks = {self.relTicksNow}")

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
  
  def PrintFifoInfo(self):
    print("\033[4m" + f"asic ({self.row},{self.col}) Local Fifo" + "\033[0m")
    print(f'  data: {self._localFifo._data} (should be empty if interrogation/calibration was successful)')
    print(f'  did it reach max capacity?: {self._localFifo._full}')
    print(f'  max size: {self._localFifo._maxSize}')
    print(f'  total writes: {self._localFifo._totalWrites}')

    print("\033[4m" + f"asic ({self.row},{self.col}) Remote Fifos (NESW)" + "\033[0m")
    print(f'  data: ', end="")
    for remoteFifo in self._remoteFifos:
      print(f'{remoteFifo._data} ', end="")
    print(f'\n  did it reach max capacity?: ', end="")
    for remoteFifo in self._remoteFifos:
      print(f'{remoteFifo._full} ', end="")
    print(f'\n  max size:', end="")
    for remoteFifo in self._remoteFifos:
      print(f'{remoteFifo._maxSize} ', end="")
    print(f'\n  total writes: ', end="")
    for remoteFifo in self._remoteFifos:
      print(f'{remoteFifo._totalWrites} ', end="")
    print('\n')
    


  def ReceiveByte(self, queueItem:ProcItem):
    """
    Receive data from a neighbor
    queueItem - tuple of (asic, dir, byte, inTime)
    """
    inDir     = queueItem.dir
    inByte    = queueItem.QPByte
    inTime    = queueItem.inTime
    inCommand = queueItem.command

    if self.connections[inDir] is None:
      print("WARNING receiving data from non-existent connection!")
    
    # if you receive an item from the DaqNode, there needs to be a broadcast
    outList = [] 
    isFromDaq = bool(inByte.originCol is None and inByte.originRow is None)

    # if you receive an item from the DaqNode, there needs to be a broadcast
    if isFromDaq:
      self.lastTsDir = inDir
      transactionCompleteTime = inTime + self.transferTime
      self.UpdateTime(transactionCompleteTime)
      self.state = AsicState.TransmitLocal

      # Broadcast everything you receive from the DaqNode
      for i in range(4):
        if i != inDir and self.connections[i]:
          outList.append((self.connections[i] , (i+2)%4, inByte, transactionCompleteTime, inCommand))

        self.lastTsDir = inDir
        self.state = AsicState.TransmitLocal
        transactionCompleteTime = inTime + self.transferTime
        self.UpdateTime(transactionCompleteTime)
        self._measuredTime.append(self.relTimeNow)
        self._command = inCommand

        # Broadcast everything you receive from the DaqNode
        for i, connection in enumerate(self.connections):
          if i != inDir and connection is not None:
            outList.append((connection, (i+2)%4, inByte, transactionCompleteTime, inCommand))

        # Build hits on local queues for default inCommand
        if inCommand == "Interrogate":
          # self._GeneratePoissonHits(inTime)
          self._ReadHits(inTime)
        # alternative responses to incoming daq nodes here
        
      #TODO - check that this makes sense
      else:
        # print("WARNING lost data! Can't send data while measuring!")
        self._remoteFifos[inDir].Write(inByte)

    # any data received elsewhere is stored in a remote FIFO
    else:
      # Don't forward source timestamps
      if not isFromDaq:
        self._remoteFifos[inDir].Write(inByte)

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
    # print(f'Generating Poisson Hits for ({self.row}, {self.col}) at target time {targetTime}')
    newHits = []

    for ch in range(self.nPixels):
      currentTime = self.lastAbsHitTime[ch]
      while currentTime < targetTime:

        # generate a posion distribution of absolute / reletive times
        p = random.random() #prints random real between 0 and 1
        nextAbsHitTime = currentTime + (-math.log(1.0 - p) / self.randomRate) # math.log is the natural log
        nextRelHitTime = int(math.floor(nextAbsHitTime / self.tOsc))

        # if hit happens before target time, add a new hit to the list
        if nextAbsHitTime < targetTime:
          newHits.append([ch, nextRelHitTime])
          currentTime = nextAbsHitTime
          self.lastAbsHitTime[ch] = currentTime
        elif nextAbsHitTime > targetTime:
          currentTime             = targetTime
          self.lastAbsHitTime[ch] = targetTime

    if not newHits:
      return 0

    # sort the new hits by time, group the channels with the same hit time, then add
    # them into the FIFO
    newHits.sort(key=lambda x : x[1], reverse=False)
    prevByte = QPByte(newHits[0][1], [newHits[0][0]], self.row, self.col, wordType="hit")

    #check to see if the hit time of the every new hit after the first is 
    #the same as the first hit time, then check with second hit, then third ...
    for ch, hitTime in newHits[1:]:
      if hitTime == prevByte.hitTime:
        prevByte.AddChannel(ch)
      else:
        self._localFifo.Write(prevByte)
        prevByte = QPByte(hitTime, [ch], self.row, self.col, wordType="hit")

    #write in the last byte
    self._localFifo.Write(prevByte)

    # print(f'giving asic ({self.row}, {self.col}) {len(newHits)} hits')
    return len(newHits)

  def _InjectHits(self, times = None, channels = None):
    """
    user function to place all injected times and channels into asic specific 
    time and channel arrays

    then sort each according to time
    """
    print(f'injecting hits for ({self.row}, {self.col})')

    # place all of the injected times and channels into self._times and self._channels
    for i in times:
      self._times.append(i)
    for j in channels:
      if j is None:
        print('there are no channels in this hit')
      self._channels.append(j)

    #sort the times and channels
    self._times, self._channels = zip(*sorted(zip(self._times, self._channels)))
    
    print(f'injected hits are at times {self._times} and ch {self._channels}')

  def _ReadHits(self, targetTime):
    """
    make times and channels arrays to contain all hits 
    within the last asic hit time and the target time

    read all of the hits in the times/channels arrays
    
    then write hits to local fifos
    """
    if not(len(self._times) ==  len(self._channels)):
      print('times and channels not the same length - something has gone horribly wrong')
    
    if len(self._times):
      self._times = np.array(self._times)
      #index times and channels such that they are within last asic hit time and target time
      TimesIndex = np.logical_and(self._times > self._lastAsicHitTime, self._times <= targetTime)
      times = self._times[TimesIndex]
      channels = []
      for i in range(len(self._channels)):
        if TimesIndex[i]:
          channels.append(self._channels[i])
      # channels = [self._channels for (self._channels, TimesIndex) in zip(self._channels, TimesIndex) if TimesIndex]
      
      newhitcount = 0
      for inTime, ch in zip(times, channels):
        if type(ch) is list:
          prevByte = QPByte(inTime, [ch[0]], self.row, self.col, wordType="hit")
          for addCh in ch[1:]:
            prevByte.AddChannel(addCh)
        else:
          prevByte = QPByte(inTime, [ch], self.row, self.col, wordType="hit")
        self._localFifo.Write(prevByte)
        newhitcount+=1
      
      self._lastAsicHitTime = targetTime

      return newhitcount
    
    else:
      # print(f'there are no hits for asic ({self.row}, {self.col})')
      return 0

  def Process(self, targetTime):
    """
    Transmits local and remote data when asked 
    """
    # nothing to process if DAQ or if target time is in past
    # print("proc:", self.row, self.col, end=" ")
    if self.isDaqNode or self._absTimeNow > targetTime:
      # print(f"good time! {self.relTicksNow:0.2e}")
      return []

    # Process incoming commands first
    if self._command == "Calibrate" or self._command == "Interrogate":

      self._command = None
      # all commands build local queues, and the command should build up any 'hit' of interest
      self.state = AsicState.TransmitLocal
      self._localFifo.Write(QPByte(self._measuredTime[-1], [], self.row, self.col, data=self.relTicksNow, wordType="ask")) #relTicks now is the total number of ticks of the ASIC

    if self.state == AsicState.Idle:
      return self._processMeasuringState(targetTime)

    if self.state == AsicState.TransmitLocal:
      return self._processTransmitLocalState(targetTime)

    if self.state == AsicState.TransmitRemote:
      return self._processTransmitRemoteState(targetTime)

    else:
      # undefined state
      print("WARNING! ASIC in undefined state")
      self.state = AsicState.Idle
      return []

  def _processMeasuringState(self, targetTime):
    """
    helper function when processing in Measuring state
    """
    # print("transfer Idle!")
    self.UpdateTime(targetTime)
    return []

  def _processTransmitLocalState(self, targetTime):
    """
    helper function for sending local data where it needs to go
    sends a single local state queue item into the outlist
    """

    transactionCompleteTime = self._absTimeNow + self.transferTime
    # print("transfer local!")

    # read an event from our local FIFO, if there is something in it, transmit it
    hit = self._localFifo.Read()
    if hit is not None:
      self.UpdateTime(transactionCompleteTime)
      return [(self.connections[self.lastTsDir], (self.lastTsDir+2)%4, hit, transactionCompleteTime)]
    else:
      self.state = AsicState.TransmitRemote
      self.timeoutStart = self._absTimeNow
      return []

  def _processTransmitRemoteState(self, targetTime):
    """
    helper function for sending remote data where it needs to go
    sends a single remote queue item from one of the remote queues 
    """

    # If we're timed out, just kill it
    if self._absTimeNow - self.timeoutStart > self.timeout:
      self.state = AsicState.Idle
      if self._localFifo._curSize > 0:
          print("Lost "+str(len(self._localFifo._curSize))+" hits that were left to forward!")
      return []

    hitsToForward = False
    for remote_fifo in self._remoteFifos:
      if remote_fifo._curSize > 0:
        hitsToForward = True

    # If there's nothing to forward, just bring us up to requested time
    if not(hitsToForward):
      self.UpdateTime(targetTime)
      self.state = AsicState.Measure
      return []

    else:
      hitlist = []
      for remote_fifo in self._remoteFifos:
        hit = remote_fifo.Read()
        if hit is not None:
          completeTime = self._absTimeNow + self.transferTime
          if self._absTimeNow - self.timeoutStart > self.timeout:
            self.state = AsicState.Idle
            self.UpdateTime(completeTime)
            return hitlist
          else:
            hitlist.append((self.connections[self.lastTsDir], (self.lastTsDir+2)%4 , hit, completeTime))
            self.UpdateTime(completeTime)
      return hitlist

    return []

  def UpdateTime(self, absTime):
    """
    How an ASIC keep track of its relative times.
    ARGS:
        absTime - absolute time of the simulation, that an ASIC is asked to process up to

    NOTE:
    should only move forward in time and update if the ASIC is not already this
    far forward in time.
    """

    if absTime > self._absTimeNow:
      self._absTimeNow = absTime

      # only update the relTime if the asic needs to
      if self._absTimeNow > self.relTimeNow:
        t_diff =  self._absTimeNow - self.relTimeNow
        cycles = int(t_diff/self.tOsc) + 1

        # update the local clock cycles
        self.relTimeNow += cycles * self.tOsc
        self.relTicksNow += cycles

class DaqNode(QPixAsic):
  def __init__(self, fOsc = 50e6, nPixels = 16, randomRate = 20.0 / 1., timeout = 1000, row = None, col = None,
               isDaqNode = True, transferTicks = 4*66, debugLevel=0):
    # makes itself basically like a qpixasic
    super().__init__(fOsc, nPixels, randomRate, timeout, row, col, 
                    transferTicks, debugLevel)
    # new members here
    # self.isDaqNode = True
    self.askData = {}
    self.hitData = {}
    self.daqData = {}
    self.daqHits = 0

  def ReceiveByte(self, queueItem:ProcItem):
    """
    Records Byte to daq
    """
    inDir     = queueItem.dir
    inByte    = queueItem.QPByte
    inTime    = queueItem.inTime
    inCommand = queueItem.command
    inWord    = inByte.wordType

    # how a DAQNode records and stores data to its local FIFO
    AsicKey = f"({inByte.originRow}, {inByte.originCol})"
    if AsicKey not in self.daqData:
      self.daqData[AsicKey] = []

    self.UpdateTime(queueItem.inTime)
    self.daqHits += 1
    self._localFifo.Write(inByte)

    # Put all of the attributes of the QPByte into a list 
    # (hitTime, channelList, originRow, originCol, data=None, wordType=None)
    # ByteList = list(vars(inByte).values())
    # self.daqData[AsicKey].append((self.relTicksNow, ByteList))

    if inWord == "hit":
      self.hitData[AsicKey].append((self.relTicksNow, inByte)) #ByteList or inByte
    elif inWord == "ask":
      self.askData[AsicKey].append((self.relTicksNow, inByte))
    else:
      print('there is no associated wordType with this byte')
    self.daqData[AsicKey].append((self.relTicksNow, inByte))

    if self._debugLevel > 0:
      print(f"DAQ-{self.relTicksNow} ",end=' ')
      print(f"from: ({inByte.originRow},{inByte.originCol})",end='\n\t')
      print(f"Hit Time: {inByte.hitTime} "+format(inByte.channelMask,'016b'),end='\n\t')
      print(f"absT: {inTime}", end='\n\t')
      print(f"tDiff (ns): {(self.relTimeNow-inTime)*1e9:2.2f}")

    return []
