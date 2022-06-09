# interfacing dependcies
from qdb_interface import AsicREG, AsicCMD, AsicMask, qdb_interface, QDBBadAddr, REG
import sys
import time

# GUI things
from PyQt5 import QtCore
from PyQt5.QtWidgets import QWidget, QPushButton
from PyQt5.QtCore import QProcess
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QApplication, QMainWindow, QAction

# for output data
from array import array
import ROOT

class QPIX_GUI(QMainWindow):
    def __init__(self):
        super(QMainWindow, self).__init__()

        # IO interfaces
        self.qpi = qdb_interface()
        self._tf = ROOT.TFile("./test.root", "RECREATE")
        self._tt = ROOT.TTree("qdbData", "data_tree")

        # storage tree setup words
        self._data = {
            "trgT" : array('L', [0]),
            "daqT" : array('L', [0]),
            "asicT" : array('L', [0]),
            "asicX" : array('H', [0]),
            "asicY" : array('H', [0]),
            "wordType" : array('H', [0])}
        types = ["trgT/i", "daqT/i", "asicT/i", "asicX/b", "asicY/b", "wordType/b"]
        for data, typ in zip(self._data.items(), types):
            self._tt.Branch(data[0], data[1], typ)

        # window setup
        self.setWindowTitle('QDB Viewer')

        # main window
        self.main_wid = QWidget() # store the main layout

        # main window interactive items
        self.setCentralWidget(self.main_wid)

        # initialize the sub menus
        self._make_menuBar()

        ###################
        ## Zybo commands ##
        ###################
        btn = QPushButton(self.main_wid)
        btn.setText('trigger')
        btn.move(0,80)
        btn.clicked.connect(self.trigger)

        btn_readEvents = QPushButton(self.main_wid)
        btn_readEvents.setText('get events')
        btn_readEvents.move(0,120)
        btn_readEvents.clicked.connect(self.readEvents)

        btn_trgTime = QPushButton(self.main_wid)
        btn_trgTime.setText('get trigger time')
        btn_trgTime.move(0,160)
        btn_trgTime.clicked.connect(self.getTrigTime)

        btn_getFrq = QPushButton(self.main_wid)
        btn_getFrq.setText('get frequency')
        btn_getFrq.move(0,200)
        btn_getFrq.clicked.connect(self.estimateFrequency)

        ###################
        ## ASIC commands ##
        ###################
        btn_rst = QPushButton(self.main_wid)
        btn_rst.setText('reset')
        btn_rst.move(0,0)
        btn_rst.clicked.connect(self.resetAsic)

        btn_mask = QPushButton(self.main_wid)
        btn_mask.setText('mask')
        btn_mask.move(0,40)
        btn_mask.clicked.connect(self.setAsicDirMask)

        btn_gtimeout = QPushButton(self.main_wid)
        btn_gtimeout.setText('get timeout')
        btn_gtimeout.move(80,0)
        btn_gtimeout.clicked.connect(self.getAsicTimeout)

        btn_stimeout = QPushButton(self.main_wid)
        btn_stimeout.setText('set timeout')
        btn_stimeout.move(160,0)
        btn_stimeout.clicked.connect(self.setAsicTimeout)

        # show the main window
        self.show()

    ############################
    ## Zybo specific Commands ##
    ############################
    def trigger(self):
        """
        Send a basic trigger packet to the board.

        This interrogation will be sent to all ASICs in the array, and memory
        will be recorded into the BRAM within QpixDaqCtrl.vhd.
        """
        addr = REG.CMD
        val = AsicCMD.Interrogation.value
        wrote = self.qpi.regWrite(addr, val)

    def readEvents(self):
        """
        Main Data Read function.

        Will read the evtSize from the Zybo and will read and fill stored TTree member.

        After all events have been read, the TFile is updated with a Write.

        NOTE: The RxByte  is a 64 bit word defined in QpixPkg.vhd where a Byte
              is formed from the record transaction. The 'getMeta' helper
              function below details how the meta-data is stored into 64 bits.
        """
        addr = REG.EVTSIZE
        evts = self.qpi.regRead(addr)
        if evts:
            print("found evts:", evts)
        else:
            print("no events recorded.")
            return

        # If we have events, we should record when a trigger went out to store them
        trigTime = self.getTrigTime()
        self._data["trgT"][0] = trigTime

        def getMeta(data):
            """
            helper function to extract useful data from middle word in event
            """
            # y pos is lowest 4 bits
            y = d & 0xf

            # x pos is bits 7 downto 4
            x = (d >> 4) & 0xf

            # chanMask is next 16 bits
            chanMask = (d >> 8) & 0xffff

            # wordType is next 24 bits
            wordType = (d >> 24) & 0xf

            return y, x, chanMask, wordType

        # read back all of the events now, and each event has 32*3 bits..
        for evt in range(evts):
            # read each word in the event
            asicTime = self.qpi.regRead(REG.MEM(evt, 0))
            d = self.qpi.regRead(REG.MEM(evt, 1))
            y, x, chanMask, wordType = getMeta(d)
            daqTime = self.qpi.regRead(REG.MEM(evt, 2))

            # store and fill each event into the tree, writing when done
            self._data["daqT"][0] = daqTime
            self._data["asicT"][0] = asicTime
            self._data["asicX"][0] = x
            self._data["asicY"][0] = y
            self._data["wordType"][0] = wordType
            self._tt.Fill()

        self._tf.Write()

    def getTrigTime(self) -> int:
        """
        Read in the trgTime register value.

        the trgTime value is the daqTime recorded on the zybo whenever a trigger
        is initiated.
        """
        trgTime = self.qpi.regRead(REG.TRGTIME)
        return trgTime

    def estimateFrequency(self):
        """
        Similar to Calibration method within the simulation.

        ARGS: Delay - how long to wait in seconds

        Issues two different 'Calibration' Triggers to record times on the Zybo
        and QDB arrays. print out interesting time measurements between the trigger
        to estimate a frequency: counts / time
        """

        # get the starting times
        time_start = time.time()
        self.trigger()
        time_trig_start = time.time()
        time_s = (time_start + time_trig_start)/2
        daq_trig_start = self.getTrigTime()

        time.sleep(1)

        # get the end times
        time_end = time.time()
        self.trigger()
        time_trig_end = time.time()
        time_e = (time_end + time_trig_end)/2
        daq_trig_end = self.getTrigTime()

        daq_cnt = daq_trig_end - daq_trig_start
        dt = time_e - time_s
        print(f"Estimated Daq Frq: {(daq_cnt / dt)/1e6:0.4f} MHz")


    ############################
    ## ASIC specific Commands ##
    ############################
    def resetAsic(self, xpos=0, ypos=0):
        """
        Reset asic at position (xpos, ypos)
        """
        print("reseting asic:", xpos, ypos)
        addr = REG.ASIC(xpos, ypos, AsicREG.CMD)
        val = AsicCMD.ResetAsic.value
        self.qpi.regWrite(addr, val)

    def setAsicDirMask(self, xpos=0, ypos=0, mask=AsicMask.DirDown):
        """
        Change ASIC mask at position (xpos, ypos)
        """
        if not isinstance(mask, AsicMask):
            raise QDBBadAddr("Incorrect AsicMask!")
        addr = REG.ASIC(xpos, ypos, AsicREG.DIR)
        val = mask.value
        self.qpi.regWrite(addr, val)

    def setAsicTimeout(self, xpos=0, ypos=0, timeout=15000):
        """
        Change ASIC timeout value at position (xpos, ypos)
        """
        addr = REG.ASIC(xpos, ypos, AsicREG.TIMEOUT)
        val = timeout
        self.qpi.regWrite(addr, val)

    def getAsicTimeout(self, xpos=0, ypos=0):
        """
        Change ASIC timeout value at position (xpos, ypos)
        """
        addr = REG.ASIC(xpos, ypos, AsicREG.TIMEOUT)
        read = self.qpi.regRead(addr)
        # note that request data from an asic resets MEM addr,
        # and that the MEM addr goes back to zero..
        self._readAsicMemory()

    def _readAsicMemory(self):
        """
        special helper function to unpack ASIC request word from BRAM memory.

        Layering of ASIC data is stored within QpixPkg.vhd, fQpixRegToByte function.
        """
        word1 = self.qpi.regRead(REG.MEM(0, 0))
        word2 = self.qpi.regRead(REG.MEM(0, 1))
        # records the last trigger event, and not related to ASIC reg request
        # daqTime = self.qpi.regRead(REG.MEM(0, 2))

        # first 32 bits
        data = word1 & 0xffff
        addr = (word1 >> 16) & 0xffff

        # next 32 bits
        y = word2 & 0xf
        x = (word2 >> 4) & 0xf
        wordType = (word2 >> 24) & 0xf

        print(f"Read x{wordType:01x} ASIC @ {addr:04x} data: 0x{data:04x}", data)


    ###########################
    ## GUI specific Commands ##
    ###########################
    def _make_menuBar(self):
        menubar = self.menuBar()
        menubar.setNativeMenuBar(False)

        # exit action
        exitAct = QAction(QIcon('exit.png'), '&Exit', self)
        exitAct.setShortcut('Ctrl+Q')
        exitAct.setStatusTip('Exit application')
        exitAct.triggered.connect(self.close)

        # add the actions to the menuBar
        fileMenu = menubar.addMenu('File')
        fileMenu.addAction(exitAct)

if __name__ == "__main__":

    app = QApplication(sys.argv)
    window = QPIX_GUI()
    window.resize(800,700)
    app.exec_()
