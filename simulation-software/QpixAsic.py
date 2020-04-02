#!/usr/bin/python3

import random
import math

#Enum-like things
DIRECTIONS = ("North", "East", "South", "West")


# A Q-Pix ASIC fundamentally consists of:
# An oscillator of nominal frequency (~50 MHz)
# A number of channels (nominally 16 or 32)
#   - When a given channel is "hit", a timestamp is generated
# Four communications interfaces to contatct nearest neighbors
# Each has its own queue

# fOsc       - Oscillator Frequency in Hz
# queue      - Queue 0/1 are a ping/pong buffer mechanism
#              You switch from one to another upon receipt of a timestamp
# curQueue   - Tells us whether we're in ping or pong state
# lastTsDir  - Last direction timestamp was accepted from
# connQueues - A list of lists, one for each side, N E S W
# stateNum   - 0 - IDLE/MEASURING, 1 - REPORT_LOCAL, 2 - REPORT_REMOTE
# procQueue  - Data that is pending being pushed into this ASIC
#              Once pushed, it arrives at connQueues (if it is meant to)
class QPixAsic:
  def __init__(self, fOsc = 50e6, nPixels = 16, randomRate = 1.0/9.0, timeout = 0.5, row = None, col = None, isDaqNode = False, transferTicks = 4*66):
    self.nPixels        = 16
    self.fOsc           = fOsc
    self.tOsc           = 1.0/fOsc
    self.queues         = [[],[]]
    self.curQueue       = 0
    self.lastTsDir      = None
    self.absTimeNow     = 0
    self.lastAbsHitTime = [0] * self.nPixels
    self.connections    = [None] * 4
    self.connQueues     = [[],[],[],[]]
    self.maxConnDepths  = [0,0,0,0]
    self.maxDepth       = 0
    self.stateNum       = 0
    self.randomRate     = randomRate
    self.transferTicks  = transferTicks
    self.timeoutStart   = 0
    self.timeout        = timeout
    self.row            = row
    self.col            = col
    self.isDaqNode      = isDaqNode
    self.daqHits        = 0

  def PrintStatus(self):
    print(" ASIC ("+str(self.row)+","+str(self.col)+") ",end='')
    print(" STATE "+str(self.stateNum),end='')
    print(" N_LOCAL(A,B) "+str(len(self.queues[0])) + "," + str(len(self.queues[1])),end='')
    print(" N_REMOTE(N,E,S,W) ",end='')
    for d in range(0,4):
      print(str(len(self.connQueues[d])) + ",",end='')
    print(" t = "+str(self.absTimeNow))

  ############################################
  # Generate Poisson hits for the time step ##
  ############################################
  # Distribution of inter-arrival times can be modeled by throwing
  # p = Uniform(0,1) and feeding it to -ln(1.0 - p)/aveRate
  # General strategy for moving forward to some timestep is:
  #   foreach channel:
  #     currentTime = now
  #     while currentTime < targetTime:
  #       generate nextHitTime from distribution above
  #       if currentTime + nextHitTime < targetTime:
  #         Calculate number of ticks for timestamp and add it to the current queue
  #       else:
  #         this is last hit for this pixel, add the next time to the alternate queue
  #   Sort the overall list by timestamp
  #   foreach unique entry in the timestamp list, create a hit with proper parameters,
  #   add it to the queue (A or B)
  ############################################
  def GeneratePoissonHits(self, targetTime):
    # Temporary list
    tempList = []
    # Bookeeping for queues
    thisQueueNum = self.curQueue
    nextQueueNum = (self.curQueue + 1) % 2
    # Generate new hits
    for ch in range(0,self.nPixels):
      currentTime = self.lastAbsHitTime[ch]
      while currentTime < targetTime:
        p = random.random()
        nextAbsHitTime = currentTime + ( -math.log(1.0 - p) / self.randomRate )
        nextRelHitTime = int(math.floor(nextAbsHitTime / self.tOsc))
        if nextAbsHitTime < targetTime:
          tempList.append([ch,nextRelHitTime])
#          print("generated hit in ("+str(self.row)+","+str(self.col)+") channel "+str(ch)+ " at absolute time "+str(nextAbsHitTime)+" rel time "+str(nextRelHitTime))
          currentTime = nextAbsHitTime
          self.lastAbsHitTime[ch] = currentTime
        elif nextAbsHitTime > targetTime:
          currentTime             = targetTime
          self.lastAbsHitTime[ch] = targetTime 
    tempList.sort(key=lambda x : x[1] , reverse = False)
    self.CombineHitsAndAppend(tempList,self.queues[thisQueueNum])
    # Return the number of total hits added
    return len(tempList)

  def CombineHitsAndAppend(self, hitList, queue):
    lastEntry = None
    nextEntry = None
    for i in range(0,len(hitList)):
      thisTime = hitList[i][1]
      thisCh   = hitList[i][0]
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

  # Receive data from a neighbor
  # Received data is of the form (asic, dir, hit, absTime)
  def ReceiveData(self, queueItem):
    # Output list of tuples for next actions, each entry of form (asic, dir, hit, absTime)
    outList = [] 
    #
    inDir     = queueItem[1]
    inHit     = queueItem[2]
    inAbsTime = queueItem[3]

    if self.isDaqNode:
#      print("DAQ node received: ",end='')
#      print(" from: ("+str(inHit.originRow)+","+str(inHit.originCol)+")",end='')
#      print(" Hit: "+str(inHit.hitTime)+" , "+format(inHit.channelMask,'016b'),end='')
#      print(" absT: "+str(inAbsTime))
      self.absTimeNow = inAbsTime
      self.daqHits    += 1
      return []

#    print("Receive data called for ASIC ("+str(self.row)+","+str(self.col)+")")
    # 0: MEASURING STATE
    #    Wait for timestamps... when we see one:
    #    a) Mark where the timestamp came from
    #    b) Generate Poisson hits up to the current time
    #    c) Add the timestamp as the last entry to the queue
    #    d) Swap queues
    #    e) Pass interrogation on to all other neighbors
    #       (i.e., add them to the outList)
    #    f) Advance to the next state
    if self.stateNum == 0:
      # If this is a timestamp from the DAQ node, do the above steps
      if inHit.channelMask == 0 and inHit.originCol == None and inHit.originRow == None:
        # a) Mark where the timestamp came from
        self.lastTsDir = inDir
        # b) Generate Poisson hits up to the current AbsTime
        self.GeneratePoissonHits(inAbsTime)
        # c) Add the timestamp as the last entry to the queue
        tsHit = PixelHit( inHit.hitTime, [], self.row, self.col )
        self.queues[self.curQueue].append(tsHit)
        #    update max queue depth
        if len(self.queues[self.curQueue]) > self.maxDepth:
          self.maxDepth = len(self.queues[self.curQueue])
        # d) Swap recording queues
        self.curQueue = (self.curQueue + 1) % 2
        # e) Pass interrogation to all other neighbors
        for i in range(0,4):
          transactionCompleteTime = inAbsTime + self.transferTicks * self.tOsc
          if i != inDir and self.connections[i]:
            outList.append( (self.connections[i] , (i+2)%4, inHit, transactionCompleteTime) )

          self.absTimeNow = transactionCompleteTime
        # f) Advance to the next state
        self.stateNum = 1
      # It the inbound hit is anything else, don't do anything, the data is lost
      else:
        pass

    # If we're in any other state, we should just queue up data into our local lists
    else:
      # Don't forward source timestamps
      if inHit.originRow != None and inHit.originCol != None:
#        print(str(self.row)+","+str(self.col)+" : adding hit from "+str(inHit.originRow)+","+str(inHit.originCol)+" at "+str(self.absTimeNow))
        self.connQueues[inDir].append(inHit)
        # update max queue depth
        if len(self.connQueues[inDir]) > self.maxConnDepths[inDir]:
          self.maxConnDepths[inDir] = len(self.connQueues[inDir])

    return outList

  # This is a state where we just process the current goings ons for this ASIC
  def Process(self,targetTime):
    if self.isDaqNode:
      return []

#    print("Process called for ASIC ("+str(self.row)+","+str(self.col)+")")
    outList = []
    # If the targetTime is greater than the current time, process once
    # Otherwise, we've run past the target time already so nothing to do yet
    if targetTime < self.absTimeNow:
      return outList

    # 0: MEASURING STATE: Do nothing, we already did everything we needed when we received data
    # 1: TRANSMIT LOCAL: Move a local hit out 
    # 2: TRANSMIT REMOTE: Until timeout, move a remote hit out if you have one
    if self.stateNum == 0:
      self.absTimeNow = targetTime
      return outList
    elif self.stateNum == 1:
      # Transmit local hits back to lastTsDir
      transactionCompleteTime = self.absTimeNow + self.transferTicks * self.tOsc
      # Note that hits come from the prior queue, since curQueue tracks where we're
      # now storing new hits, so the previous one is the one to empty now.
      if len(self.queues[(self.curQueue+1)%2]) > 0:
        hit =  self.queues[(self.curQueue+1)%2].pop(0)
        outList.append( (self.connections[self.lastTsDir] , (self.lastTsDir+2)%4, hit, transactionCompleteTime ) )
        self.absTimeNow = transactionCompleteTime
#        print(str(self.row)+","+str(self.col)+" : sending local hit to "+DIRECTIONS[self.lastTsDir]+" at "+str(transactionCompleteTime))
      else:
        self.stateNum = 2 
        self.timeoutStart = self.absTimeNow
      return outList

    # 2: TRANSMIT REMOTE
    elif self.stateNum == 2:
      # If we're timed out, just kill it
      if self.absTimeNow - self.timeoutStart > self.timeout:
        self.stateNum = 0
        for q in self.queues:
          if len(q) > 0:
            print("Lost "+str(len(q))+" hits that were left to forward!")
        self.queues = [[],[],[],[]]
        return outList

      # If there's nothing to forward, just bring us up to requested time
      hitsToForward = False
      for q in self.connQueues:
        if len(q) > 0:
          hitsToForward = True
      if not(hitsToForward):
        self.absTimeNow = targetTime
        if self.absTimeNow - self.timeoutStart > self.timeout:
          self.stateNum = 0
        return outList

      # Otherwise, check if there's a hit to forward, if so, forward it
      # Using a fixed priority here
      transactionCompleteTime = self.absTimeNow + self.transferTicks * self.tOsc
      hit = None
      for cq in self.connQueues:
        if len(cq) > 0:
          hit = cq.pop(0)
          break
      if hit:
#        print(str(self.row)+","+str(self.col)+" : forwarding hit from "+str(hit.originRow)+","+str(hit.originCol)+" at "+str(transactionCompleteTime))
        outList.append( (self.connections[self.lastTsDir], (self.lastTsDir+2)%4 , hit, transactionCompleteTime) )
        self.absTimeNow = transactionCompleteTime

    # Whatever state you were in, pass back the outbound transactions list
    return outList

# Something like a struct to store actual hits.
# A hit corresponds to what would be a bitmask of channels hit for a given timestamp
# We'll just treat that mask as a list of channels for now
class PixelHit:
  def __init__(self, hitTime, channelList, originRow, originCol):
    self.originRow   = originRow
    self.originCol   = originCol
    self.hitTime     = hitTime
    self.channelMask = 0
    for ch in channelList: 
      self.channelMask |= 0x1 << ch

  def AddChannel(self, channel):
    self.channelMask |= 0x1 << channel

# Processing queue that's used to determine which events to service next
# Each entry in the queue is a tuple of:
# 0 - asic, the ASIC being pushed to
# 1 - direction, where the new entry came from
# 2 - hit, a PixelHit object
# 3 - absTime, absolute time that the data would be received
class ProcQueue:
  def __init__(self):
    self.queue = []

  def AddQueueItem(self, asic, dir, hit, absTime):
    self.queue.append( (asic, dir, hit, absTime) )
    return len(self.queue)

  def SortQueue(self):
    self.queue.sort(key=lambda x : x[3] , reverse = False)
    return None

  def PopQueue(self):
    if len(self.queue) > 0:
      return self.queue.pop(0)
    else:
      return None

  def Length(self):
    return len(self.queue)