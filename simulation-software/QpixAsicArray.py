import QpixAsic as qpa
import random
import math
import time

class QpixAsicArray():
    """
    Class purpose is to streamline creation of a digital asic array tile for the
    QPix project. Controls main sequencing of spread of asic clock cycles
    VARS:
      nrows - rows within the array
      ncols - columns within the array
      nPixs=16 - number of channels
      fNominal=50e6  - Default clock frequency
      pctSpread=0.05 - std distribution of clocks within array
      deltaT=1.0     -
      timeEpsilon=1e-6 - stepping time interval for simulation
      debug=0.0 - debug level, values >= 5 produce text output
    """
    def __init__(self, nrows, ncols, nPixs=16, fNominal=50e6, pctSpread=0.05, deltaT=1.0, timeEpsilon=1e-6,
                debug=0.0):

        # array parameters
        self._nrows = nrows
        self._ncols = ncols
        self._debugLevel = debug
        self._nPixs = nPixs
        self.fNominal = fNominal
        self.pctSpread = pctSpread

        # Make the array and connections
        self._asics = self._makeArray()
        self._daqNode = qpa.QPixAsic(self.fNominal, 0, isDaqNode=True, debugLevel=self._debugLevel)
        self._asics[0][0].connections[3] = self._daqNode

        # the array also manages all of the processing queue times to use
        self._queue = qpa.ProcQueue()
        self._tickNow = 50e6
        self._timeEpsilon = 1e-6
        self._deltaT = deltaT
        self._deltaTick = 50e6 * self._deltaT
        self._timeNow = 0
    
    def __iter__(self):
        '''returns iterable through the asics within the array'''
        for asic_row in self._asics:
            for asic in asic_row:
                yield asic

    def __getitem__(self, row):
        '''
        make the array subscriptable to get whichever item we want
        '''
        assert row <= self._nrows - 1, "not enough rows in that array" 
        return self._asics[int(row)]

    def _makeArray(self):
        """
        helper function designed to construct QPix asic values within array type
        """
        matrix = [[] for j in range(self._nrows)]

        for i in range(self._nrows):
            for j in range(self._ncols):
                frq = random.gauss(self.fNominal,self.fNominal*self.pctSpread)
                matrix[i].append(qpa.QPixAsic(frq, self._nPixs, row = i, col = j, debugLevel=self._debugLevel))
                if self._debugLevel >= 0:
                    print(f"Created ASIC at row {i} col {j} with frq: {frq:.2f}")

        # connect the asics within the array
        for i in range(self._nrows):
            for j in range(self._ncols):
                if i > 0:
                    matrix[i][j].connections[0] = matrix[i-1][j]
                if i < self._nrows-1:
                    matrix[i][j].connections[2] = matrix[i+1][j]
                if j > 0:
                    matrix[i][j].connections[3] = matrix[i][j-1]
                if j < self._ncols-1:
                    matrix[i][j].connections[1] = matrix[i][j+1]    

        return matrix

    def readData(self):
        """
        function call to issue a command to read data from the full array
        """
        data = []
        readTime = time.perf_counter()

        for i in range(self._nrows):
            for j in range(self._ncols):
                data += self._asics[i][j].Process(readTime)

        stopTime = time.perf_counter()
        self._processTime = stopTime - readTime

        if self._debugLevel >= 5:
            print(f"processing time was: {self._processTime:.4f}")

        return data

    def Calibrate(self, interval=1.0):
        """
        function used to calibrate timing interval of all underlying asics, assuiming
        no current knowledge of underlying times / frequencies
        VARS:
            interval - time in seconds to issue two different commands and to read time value pairs back from asics
        """

        print("performing calibration..")
        calibrateSteps = self._Command(self._timeNow, command="Calibrate")

        timeEnd = self._timeNow + interval

        # hard reset asic time values
        for asic in self:
            asic._measurements = 0
            asic._hitReceptions = 0
            asic._remoteTransmissions = 0
            asic._localTransmissions = 0
            asic._measuredTime = 0

        print(f"current time is {self._timeNow}")
        calibrateSteps = self._Command(timeEnd, command="Calibrate")
        print(f"calibration complete time is:", self._timeNow)

    def timeStamp(self, interval=1.0):
        """
        Function for issueing command to base node from daq node, and beginning
        a full readout sequence of timestamp data
        VARS:
            interval - seconds of time for how long the array will process data
        """
        print("performing timestamp..")
        timeEnd = self._timeNow + interval
        readoutSteps = self._Command(timeEnd)
        print(f"timestamp complete in {readoutSteps} steps!")

    def _Command(self, timeEnd, command=None):
        """
        Function for issueing command to base node from daq node, and beginning
        a full readout sequence
        VARS:
            timeEnd - how long the array should be processed until
            command - string argument that the asics receive to tell them what readout is coming in from DAQnode
        """
        steps = 0
        while(self._timeNow < timeEnd):

            for asic in self:
                newProcessItems = asic.Process(self._timeNow - self._timeEpsilon)
                if newProcessItems:
                    print("WARNING: ASIC had things left to do at next maor time step")

            self._queue.AddQueueItem(self[0][0], 3, qpa.QPByte(self._tickNow, [], None, None), self._timeNow, command=command)

            while(self._queue.Length() > 0):

                steps += 1
                nextItem = self._queue.PopQueue()
                self.ProcessArray(self._queue, nextItem.inTime)

                newProcessItems = nextItem.asic.ReceiveData(nextItem)
                if newProcessItems:
                    for item in newProcessItems:
                        self._queue.AddQueueItem(*item)

                self.ProcessArray(self._queue, nextItem.inTime)

            self._timeNow += self._deltaT
            self._tickNow += self._deltaTick

        return steps

    def ProcessArray(self, procQueue, nextTime):
        """
        move all processing of the array up to absTime
        """
        processed = 0
        somethingToDo = True
        while somethingToDo:
            somethingToDo = False
            for asic in self:
                newProcessItems = asic.Process(nextTime)
                if newProcessItems:
                    processed += 1
                    somethingToDo = True
                    for item in newProcessItems:
                        procQueue.AddQueueItem(*item)
        return processed

    def PrintTsMap(self):
        """
        boiler plate code for printing interesting data about each asic
        """
        for i, asic in enumerate(self):
            print(asic.lastTsDir, end=" ")
            if (i+1)%self._nrows == 0:
                print()

    def PrintTimeMap(self):
        for i, asic in enumerate(self):
            print(asic.relTimeNow, end=" ")
            if (i+1)%self._nrows == 0:
                print()

    def PrintTicksMap(self):
        print("Total Ticks")
        for i, asic in enumerate(self):
            print(asic.relTicksNow, end=" ")
            if (i+1)%self._nrows == 0:
                print()

    def PrintMeasureMap(self):
        print("Measured Transmissions:")
        for i, asic in enumerate(self):
            print(asic._measurements, end=" ")
            if (i+1)%self._nrows == 0:
                print()

    def PrintReceiveMap(self):
        print("Received Transmissions:")
        for i, asic in enumerate(self):
            print(asic._hitReceptions, end=" ")
            if (i+1)%self._nrows == 0:
                print()

    def PrintTimes(self):
        print("Tick Values :")
        for i, asic in enumerate(self):
            print(f"{asic.relTicksNow:1.2E}", end=" ")
            if (i+1)%self._nrows == 0:
                print()
        print("Rel Time Values (us):")
        for i, asic in enumerate(self):
            print(f"{(asic.relTimeNow)*1e6:1.2E}", end=" ")
            if (i+1)%self._nrows == 0:
                print()
        print("Abs Time Values (us):")
        for i, asic in enumerate(self):
            print(f"{(asic._absTimeNow - self[0][0]._absTimeNow)*1e6:1.2E}", end=" ")
            if (i+1)%self._nrows == 0:
                print()
        print("Measured Time Values (us):")
        for i, asic in enumerate(self):
            print(f"{(asic._measuredTime - self[0][0]._measuredTime)*1e6:3.2f}", end=" ")
            if (i+1)%self._nrows == 0:
                print()

    def PrintTransactMap(self):
        print("Local Transmissions:")
        for i, asic in enumerate(self):
            print(asic._localTransmissions, end=" ")
            if (i+1)%self._nrows == 0:
                print()
        print("Remote Transmissions:")
        for i, asic in enumerate(self):
            print(asic._remoteTransmissions, end=" ")
            if (i+1)%self._nrows == 0:
                print()

if __name__ == "__main__":
    array = QpixAsicArray(2,2)
    array.Calibrate()
    data = array.readData()
    print("read the following data:\n", data)
