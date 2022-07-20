#!/usr/bin/python3

from audioop import add
from io import IncrementalNewlineDecoder
import random
import math
import time
from enum import Enum
import numpy as np
from dataclasses import dataclass

#Enum-like things
DIRECTIONS = ("North", "East", "South", "West")

## helper functions
def PrintFifoInfo(asic):
  print("\033[4m" + f"asic ({asic.row},{asic.col}) Local Fifo" + "\033[0m")
  print(f'  data: {asic._localFifo._data} (should be empty if interrogation/calibration was successful)')
  print(f'  did it reach max capacity?: {asic._localFifo._full}')
  print(f'  max size: {asic._localFifo._maxSize}')
  print(f'  total writes: {asic._localFifo._totalWrites}')

  print("\033[4m" + f"asic ({asic.row},{asic.col}) Remote Fifos (NESW)" + "\033[0m")
  print(f'  data: ', end="")
  for remoteFifo in asic._remoteFifos:
    print(f'{remoteFifo._data} ', end="")
  print(f'\n  did it reach max capacity?: ', end="")
  for remoteFifo in asic._remoteFifos:
    print(f'{remoteFifo._full} ', end="")
  print(f'\n  max size:', end="")
  for remoteFifo in asic._remoteFifos:
    print(f'{remoteFifo._maxSize} ', end="")
  print(f'\n  total writes: ', end="")
  for remoteFifo in asic._remoteFifos:
    print(f'{remoteFifo._totalWrites} ', end="")
  print('\n')
##

class QPExcpetion(Exception):
  pass

class AsicDirections(Enum):
  North = 0
  East = 1
  South = 2
  West = 3

class AsicState(Enum):
  """
  Enum class based on the QpixRoute.vhd FSM states. Transitions to and from these
  states should be modeled on the inputs defined in QpixRoute.vhd.
  """
  Idle = 0
  TransmitLocal = 1
  TransmitRemote = 2
  TransmitReg = 3
  Finish = 4

class AsicWord(Enum):
  """
  Enum class to represent the different types of word types that a QPByte class
  can receive.

  These word types are 4 bits and their values are defined in QPixPkg.vhd
  """
  DATA = 1
  REGREQ = 3
  REGRESP = 4
  EVTEND = 5

@dataclass
class AsicConfig():
  """
  Struct like class that is based on the QpixConfigType record defined in QpixPkg.vhd

  This struct manages the configuration values stored in the QpixRegFile.vhd and should
  determine enables, timeouts, and directional routing
  ARGS:
    frq - frequency of asic frequency, required to determine number of timeout clicks
    timeout - number of ticks that an asic should undergo before leaving transmitRemote state
    DirMask - directional mask
    ManRoute - flag to enable manual routing, or use default routing
    EnableSnd - enable send flag
    EnableRcv - enable receive flag
    EnableReg - enagle register flag
  """
  # def __init__(self, frq, timeout=1.5e4, dirMask=0, ManRoute=False, EnableSnd=True, EnableRcv=True, EnableReg=True):
  DirMask: int
  timeout: int 
  ManRoute = False
  EnableSnd = True
  EnableRcv = True
  EnableReg = True
  something = False

class QPByte:
  """
  This struct-style class stores no more than the 64 bit information transfered
  on a 64 bit Tx/Rx Endeavor protocol.

  ARGS:
    wordType    : 4 bit regWord type
    originRow   : 4 bit value representing x position
    originCol   : 4 bit value representing y position
    # if wordtype == AsicWord.REGREQ
    # else this is a data word
    timeStamp   : 32 bit time stamp
    channelList : 16 bit channel map
    data        : extra value for simulation 

  NOTE: refactored PixelHit object! Data that are transferred are Bytes~ NOT
  'hits'. A hit is always a time stamp, but what is transferred is the more
  generic byte.

  NOTE: 2 bits are currently reserved, and formating is defined in QpixPkg.vhd
  """
  def __init__(self, originRow, originCol, wordType, timeStamp=None, channelList=None, Asic=None, data=None):
    if not isinstance(wordType, AsicWord):
      print('WARNING!! undefined word type in current byte!')

    self.wordType  = wordType
    self.originRow = originRow
    self.originCol = originCol
    # if the wordType is a reg request, then this byte is a has different data
    self.timeStamp = timeStamp
    self.channelMask = 0
    self.data = data
    if channelList is not None:
      for ch in channelList: 
        self.channelMask |= 0x1 << ch

  def __repr__(self):
    """
    how to represent a Byte when print out
    """
    msg = f"({self.originRow},{self.originCol}): {self.wordType} {self.channelMask:04x} @ {self.timeStamp} - {self.data}"
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

    if not isinstance(data, QPByte):
      raise QPException("Can not add this data-type to a QPFifo!")

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
    self.config = AsicConfig(timeout)
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

    # useful things for InjectHits
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
  
  def ReceiveByte(self, queueItem:ProcItem):
    """
    Receive data from a neighbor
    queueItem - tuple of (asic, dir, byte, inTime)

    The byte that's received in this function should simulate the behavior of
    the logic found in QpixParser.vhd
    """
    inDir     = queueItem.dir
    inByte    = queueItem.QPByte
    inTime    = queueItem.inTime
    inCommand = queueItem.command

    if self.connections[inDir] is None:
      print("WARNING receiving data from non-existent connection!")
    
    outList = [] 
    isFromDaq = bool(inByte.originCol is None and inByte.originRow is None)

    if self.state == AsicState.Idle and isFromDaq:

      self.state = AsicState.TransmitLocal
      transactionCompleteTime = inTime + self.transferTime
      self.UpdateTime(transactionCompleteTime)
      self._measuredTime.append(self.relTimeNow)
      self._command = inCommand

      # Broadcast everything you receive from the DaqNode
      for i, connection in enumerate(self.connections):
        if i != inDir and connection is not None:
          outList.append((connection, (i+2)%4, inByte, transactionCompleteTime, inCommand))

      # DAQ requests are either interrogations or register requests
      if inCommand == "Interrogate":
        # self._GeneratePoissonHits(inTime)
        self._ReadHits(inTime)

      if inByte.wordType == AsicWord.REGREQ:
        # dynamic routing
        self.lastTsDir = inDir
      else:
        print("WARNING! unknown incoming DAQ word!")

    # Data received elsewhere is stored in a remote FIFO
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
    prevByte = QPByte(newHits[0][1], [newHits[0][0]], self.row, self.col, wordType=AsicWord.DATA)

    #check to see if the hit time of the every new hit after the first is 
    #the same as the first hit time, then check with second hit, then third ...
    for ch, hitTime in newHits[1:]:
      if timestamp == prevByte.timestamp:
        prevByte.AddChannel(ch)
      else:
        self._localFifo.Write(prevByte)
        prevByte = QPByte(timestamp, [ch], self.row, self.col, wordType=AsicWord.DATA)

    #write in the last byte
    self._localFifo.Write(prevByte)

    # print(f'giving asic ({self.row}, {self.col}) {len(newHits)} hits')
    return len(newHits)

  def InjectHits(self, times, channels=None):
    """
    user function to place all injected times and channels into asic specific 
    time and channel arrays

    then sort each according to time
    """
    print(f'injecting hits for ({self.row}, {self.col})')

    # place all of the injected times and channels into self._times and self._channels
    self._times.extend(times)
    
    # include default channels
    if channels is None:
      channels = [[1,3,8]] * len(times)
    else:
      self._channels.extend(channels)

    #sort the times and channels
    self._times, self._channels = zip(*sorted(zip(self._times, self._channels)))
    
    # print(f'injected hits are at times {self._times} and ch {self._channels}')

  def _ReadHits(self, targetTime):
    """
    make times and channels arrays to contain all hits within the last asic hit
    time and the target time

    read all of the hits in the times/channels arrays, with times before
    targetTime

    then write hits to local fifos
    """
    if not(len(self._times) ==  len(self._channels)):
      print('times and channels not the same length - something has gone horribly wrong')
    
    if len(self._times):
      self._times = np.asarray(self._times)
      #index times and channels such that they are within last asic hit time and target time
      TimesIndex = np.logical_and(self._times > self._lastAsicHitTime, self._times <= targetTime)
      times = self._times[TimesIndex]
      channels = []
      for i in range(len(self._channels)):
        if TimesIndex[i]:
          channels.append(self._channels[i])
      
      newhitcount = 0
      for inTime, ch in zip(times, channels):
        if type(ch) is list:
          prevByte = QPByte(inTime, [ch[0]], self.row, self.col, wordType=AsicWord.DATA)
          for addCh in ch[1:]:
            prevByte.AddChannel(addCh)
        else:
          prevByte = QPByte(inTime, [ch], self.row, self.col, wordType=AsicWord.DATA)
        self._localFifo.Write(prevByte)
        newhitcount+=1
      
      self._lastAsicHitTime = targetTime

      return newhitcount
    
    else:
      # print(f'there are no hits for asic ({self.row}, {self.col})')
      return 0

  def Process(self, targetTime):
    """
    This function simulates the FSM within QpixRoute.vhd.
    ARGS:
      targetTime - time to push the FSM foward.
    """
    # nothing to process if DAQ or if target time is in past
    if self.isDaqNode or self._absTimeNow > targetTime:
      return []

    # Process incoming commands first
    # all commands move ASIC into transmit local state local queues, and the
    # command should build up any 'hit' of interest
    if self._command == "Calibrate":
      self._command = None
      self.state = AsicState.TransmitLocal
      curTicks = self.relTicksNow
      self._localFifo.Write(QPByte(curTicks, [], self.row, self.col, data=self._measuredTime[-1], wordType=AsicWord.REGREQ)) 

    # an ASIC timestamp request
    elif self._command == "Interrogate":
      self._command = None
      self.state = AsicState.TransmitLocal

    ## QPixRoute State machine
    elif self.state == AsicState.Idle:
      return self._processMeasuringState(targetTime)

    elif self.state == AsicState.TransmitLocal:
      return self._processTransmitLocalState(targetTime)

    elif self.state == AsicState.Finish:
      return self._processFinishState(targetTime)

    elif self.state == AsicState.TransmitRemote:
      return self._processTransmitRemoteState(targetTime)

    else:
      # undefined state
      print("WARNING! ASIC in undefined state")
      self.state = AsicState.Idle
      return []

  def _processMeasuringState(self, targetTime):
    """
    Function simulates the IDLE state with QpixRoute.vhd. In this case the only
    thing to be done is to update the time.
    """
    self.UpdateTime(targetTime)
    return []

  def _processRegisterResponse(self, targetTime):
    """
    This function simulates the register response state within QpixRoute.vhd

    This state sends a REGRESP word back to the local fifo and then returns to
    the IDLE/measuring state.
    """
    self.state = AsicState.Idle
    transactionCompleteTime = self._absTimeNow + self.transferTime
    self.UpdateTime(transactionCompleteTime)
    respByte = QPByte(0, [0], self.row, self.col, wordType=AsicWord.REGRESP)
    return [(self.connections[self.lastTsDir], (self.lastTsDir+2)%4, respByte, transactionCompleteTime)]

  def _processTransmitLocalState(self, targetTime):
    """
    helper function for sending local data where it needs to go
    sends a single local state queue item into the outlist
    """

    transactionCompleteTime = self._absTimeNow + self.transferTime

    # read an event from our local FIFO, if there is something in it, transmit it
    hit = self._localFifo.Read()
    if hit is not None:
      self.UpdateTime(transactionCompleteTime)
      return [(self.connections[self.lastTsDir], (self.lastTsDir+2)%4, hit, transactionCompleteTime)]
    else:
      self.state = AsicState.Finish
      return []

  def _processFinishState(self, targetTime):
    """
    Finish state based on QpixRoute.vhd state. Should pack a single word into
    the event fifo, send it, and proceed to the transmit remote state.
    """
    self.state = AsicState.TransmitRemote
    transactionCompleteTime = self._absTimeNow + self.transferTime
    self.UpdateTime(transactionCompleteTime)
    finishByte = QPByte(0, [0], self.row, self.col, wordType=AsicWord.EVTEND)
    self.timeoutStart = self._absTimeNow
    return [(self.connections[self.lastTsDir], (self.lastTsDir+2)%4, finishByte, transactionCompleteTime)]

  def _processTransmitRemoteState(self, targetTime):
    """
    process state is based on QpixRoute.vhd REP_REMOTE_S state. This state should always
    bring the asic back to the idle state after a timeout
    """

    # If we're timed out, just kill it
    if self._absTimeNow - self.timeoutStart > self.config.timeout / self.fOsc:
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
      if self._absTimeNow - self.timeoutStart > self.config.timeout / self.fOsc:
        self.state = AsicState.Idle
      return []

    else:
      hitlist = []
      for remote_fifo in self._remoteFifos:
        hit = remote_fifo.Read()
        if hit is not None:
          completeTime = self._absTimeNow + self.transferTime
          if self._absTimeNow - self.timeoutStart > self.config.timeout / self.fOsc:
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
  def __init__(self, fOsc = 50e6, nPixels = 16, randomRate = 20.0 / 1., timeout=1000, row=None, col=None,
               transferTicks = 4*66, debugLevel=0):
    # makes itself basically like a qpixasic
    super().__init__(fOsc, nPixels, randomRate, timeout, row, col, 
                    transferTicks, debugLevel)
    # new members here
    self.isDaqNode = True
    self.hitData = {}
    self.regData = {}
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
    if inWord == AsicWord.DATA:
      self.hitData[AsicKey].append((self.relTicksNow, inByte)) 
    elif inWord == AsicWord.REGREQ:
      self.regData[AsicKey].append((self.relTicksNow, inByte))
    elif inWord == AsicWord.EVTEND:
      pass
    else:
      print(f"WARNING! there is no associated wordType with this byte {inWord} @ {AsicKey}")
    self.daqData[AsicKey].append((self.relTicksNow, inByte))

    if self._debugLevel > 0:
      print(f"DAQ-{self.relTicksNow} ",end=' ')
      print(f"from: ({inByte.originRow},{inByte.originCol})",end='\n\t')
      print(f"Hit Time: {inByte.timestamp} "+format(inByte.channelMask,'016b'),end='\n\t')
      print(f"absT: {inTime}", end='\n\t')
      print(f"tDiff (ns): {(self.relTimeNow-inTime)*1e9:2.2f}")

    return []