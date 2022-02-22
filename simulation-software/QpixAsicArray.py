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
      timeEnd=2.5 - stop time for simulation
      debug=5.0 - debug level, values >= 5 produce text output
    """
    def __init__(self, nrows, ncols, nPixs=16, fNominal=50e6, pctSpread=0.05, deltaT=1.0, timeEpsilon=1e-6,
                timeEnd=2.5, debug=5.0):

        # array parameters
        self._nrows = nrows
        self._ncols = ncols
        self._debugLevel = debug
        self._nPixs = nPixs
        self.fNominal = fNominal
        self.pctSpread = pctSpread

        # time tracking - track the global cpu time of when the array is first created
        self._start = time.perf_counter()

        # Make the array and connections
        self._asics = self._makeArray()
        self._daqNode = qpa.QPixAsic(self.fNominal, 0, isDaqNode=True)
        self._asics[0][0].connections[3] = self._daqNode

        # the array also manages all of the processing queue times to use
        self._queue = qpa.ProcQueue()
    
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
                matrix[i].append(qpa.QPixAsic(frq, self._nPixs, row = i, col = j))
                if self._debugLevel >= 5:
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
        for i in range(self._nrows):
            for j in range(self._ncols):
                newProcessItems = self._asics[i][j].Process(interval)
        print("calibration complete!")

    def Command(self, data):
        """
        funciton used to issue a command sequence given by data to all of the boards
        VARS:
            data - struct value sent to daq node, which relays information to the rest of the boards
        """

if __name__ == "__main__":
    array = QpixAsicArray(2,2)
    array.Calibrate()
    data = array.readData()
    print("read the following data:\n", data)
