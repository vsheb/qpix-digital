from QpixAsic import QPByte, QPixAsic, ProcQueue, DaqNode
import random
import math
import time

class QpixAsicArray():
    """
    Class purpose is to streamline creation of a digital asic array tile for the
    QPix project. Controls main sequencing of spread of asic clock cycles
    VARS:
      nrows       - rows within the array
      ncols       - columns within the array
      nPixs=16    - number of channels for each ASIC
      fNominal    - Default clock frequency (default ~50 MHz)
      pctSpread   - std distribution of ASIC clocks (default 5%)
      deltaT      - stepping interval for the simulation
      timeEpsilon - stepping time interval for simulation (default 1e-6)
      debug       - debug level, values >= 0 produce text output (default 0)
    """
    def __init__(self, nrows, ncols, nPixs=16, fNominal=50e6, pctSpread=0.05, deltaT=1e-5, timeEpsilon=1e-6,
                timeout=1000, hitsPerSec = 20./1., debug=0.0):

        # array parameters
        self._tickNow = 0
        self._timeNow = 0
        self._nrows = nrows
        self._ncols = ncols
        self._debugLevel = debug
        self._nPixs = nPixs
        self.fNominal = fNominal
        self.pctSpread = pctSpread

        # the array also manages all of the processing queue times to use
        self._queue = ProcQueue()
        self._timeEpsilon = timeEpsilon
        self._deltaT = deltaT
        self._deltaTick = self.fNominal * self._deltaT

         # Make the array and connections
        self._asics = self._makeArray(timeout=timeout, randomRate=hitsPerSec)
        self._daqNode = DaqNode(fOsc = self.fNominal, nPixels = 0, isDaqNode = True, debugLevel=self._debugLevel, timeout=timeout, randomRate=hitsPerSec)
        for asic in self:
            self._daqNode.hitData[f'({asic.row}, {asic.col})'] = []
            self._daqNode.askData[f'({asic.row}, {asic.col})'] = []

        self._asics[0][0].connections[3] = self._daqNode

        self._alert = 0
   
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

    def _makeArray(self, timeout, randomRate):
        """
        helper function designed to construct QPix asic values within array type
        """
        matrix = [[] for j in range(self._nrows)]

        for i in range(self._nrows):
            for j in range(self._ncols):
                frq = random.gauss(self.fNominal,self.fNominal*self.pctSpread)
                # frq = [48141619.19, 49670982.15, 49863841.62, 50478983.94]
                # frq = [48141619.19, 50670982.15, 47863841.62, 50478983.94]

                # matrix[i].append(QPixAsic(frq[i+2*j], self._nPixs, row=i, col=j, debugLevel=self._debugLevel, timeout=timeout))
                matrix[i].append(QPixAsic(frq, self._nPixs, row=i, col=j, debugLevel=self._debugLevel, timeout=timeout, randomRate=randomRate))
                
                if self._debugLevel > 0:
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

        for asic in self:
            data += asic.Process(readTime)

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

        self._alert = 0
        t1 = self._timeNow + interval
        calibrateSteps = self._Command(t1, command="Calibrate")

        t2 = self._timeNow + interval
        calibrateSteps = self._Command(t2, command="Calibrate")
        # print(f"calibration complete time is: {self._timeNow}, steps: {calibrateSteps}")


    def Interrogate(self, interval=0.1, duration=1., times = [], channels = []): # tell daq to send an interrogation to all asics
        """
        Function for issueing command to base node from daq node, and beginning
        a full readout sequence of timestamp data.
        The ratio duration/interval gives the number of interrogations
        VARS:
            interval - how often the daq interrogates the asics
            duration - how long the simulation will run for
        """
        for asic in self:
            asic._times = times
            asic._channels = channels
        
        time = self._timeNow

        while time <= duration:
            self._alert=0
            time = self._timeNow + interval

            # print("performing timestamp..")
            readoutSteps = self._Command(time, command="Interrogate")
            # print(f"timestamp complete in {readoutSteps} steps")
            self._timeNow = time

            print(f'time is now {self._timeNow}s \n')

    def _Command(self, timeEnd, command=None):
        """
        Function for issueing command to base node from daq node, and beginning
        a full readout sequence
        VARS:
            timeEnd - how long the array should be processed until
            command - string argument that the asics receive to tell them what readout is coming in from DAQnode

        NOTE Basic Unit of simulation:
            ASIC      - receiving data
            Direction - source direction of incoming data
            QPByte    - source data, 64 bit word
            hitTime   - transaction complete time from source ASIC
            Command   - optional argument passed to receive data to tell receiving
                        ASIC to behave differently
        """

        # add the initial broadcast to the queue
        steps = 0
        self._queue = ProcQueue()
        self._queue.AddQueueItem(self[0][0], 3, QPByte(self._tickNow, [], None, None, wordType="ask"), self._timeNow, command=command)

        while(self._timeNow < timeEnd):

            for asic in self:
                newProcessItems = asic.Process(self._timeNow - self._timeEpsilon)
                if newProcessItems:
                    self._alert = 1
                    # print("WARNING: ASIC had things left to do at next major time step")
                    for item in newProcessItems:
                        recv += 1
                        self._queue.AddQueueItem(*item)

            while(self._queue.Length() > 0):

                if self._debugLevel > 0:
                    for asic in self:
                        print(asic.state, asic.row, asic.col, asic.fOsc)

                steps += 1
                # pop the next simulation unit
                nextItem = self._queue.PopQueue()
                asic = nextItem.asic
                direction = nextItem.dir
                hitTime = nextItem.inTime
                data = nextItem.QPByte
                command = nextItem.command

                # ASICs to catch up to this time, and to send data
                p1 = self.ProcessArray(hitTime)

                # ASIC to receive data
                newProcessItems = asic.ReceiveByte(nextItem)
                recv = 0
                if newProcessItems:
                    for item in newProcessItems:
                        recv += 1
                        self._queue.AddQueueItem(*item)

                p2 = self.ProcessArray(hitTime)

                # print(f"({asic.row},{asic.col}) from {direction} processed:", p1, recv, p2, f"items={self._queue.Length()}")
                # input("")

            self._timeNow += self._deltaT
            self._tickNow += self._deltaTick

        return steps

    def ProcessArray(self, nextTime):
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
                    somethingToDo = True
                    for item in newProcessItems:
                        processed += 1
                        self._queue.AddQueueItem(*item)
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
            print(f"{(asic._measuredTime[-1] - self[0][0]._measuredTime[-1])*1e6:3.2f}", end=" ")
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
