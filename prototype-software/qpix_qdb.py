from qdb_interface import reg, AsicREG, AsicCMD, AsicMask, qdb_interface, QDBBadAddr
import sys

# GUI things
from PyQt5 import QtCore
from PyQt5.QtWidgets import QWidget, QPushButton
from PyQt5.QtCore import QProcess
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QApplication, QMainWindow, QAction


class QPIX_GUI(QMainWindow):
    def __init__(self):
        super(QMainWindow, self).__init__()

        # network interface
        self.qpi = qdb_interface()

        # window setup
        self.setWindowTitle('QDB Viewer')

        # main window
        self.main_wid = QWidget() # store the main layout

        # main window interactive items
        self.setCentralWidget(self.main_wid)

        # initialize the sub menus
        self._make_menuBar()

        btn = QPushButton(self.main_wid)
        btn.setText('trigger')
        btn.move(0,0)
        btn.clicked.connect(self.trigger)

        btn_rst = QPushButton(self.main_wid)
        btn_rst.setText('reset')
        btn_rst.move(0,32)
        btn_rst.clicked.connect(self.resetAsic)

        btn_mask = QPushButton(self.main_wid)
        btn_mask.setText('mask')
        btn_mask.move(0,64)
        btn_mask.clicked.connect(self.setAsicDirMask)

        # show the main window
        self.show()

    def trigger(self):
        """
        send a basic trigger packet to the board
        """
        addr = reg.CMD
        val = AsicCMD.Interrogation.value
        wrote = self.qpi.regWrite(addr, val)
        try:
            print(f"read back 0x{wrote:08x}")
        except:
            print("bad wrote type", wrote)

    def resetAsic(self, xpos=0, ypos=0):
        """
        Reset asic at position (xpos, ypos)
        """
        print("reseting asic:", xpos, ypos)
        addr = reg.ASIC(xpos, ypos, AsicREG.CMD)
        val = AsicCMD.ResetAsic.value
        print("reseting", f"0x{addr:08x}", val)
        self.qpi.regWrite(addr, val)


    def setAsicDirMask(self, xpos=0, ypos=0, mask=AsicMask.DirDown):
        """
        Change ASIC mask at position (xpos, ypos)
        """
        if not isinstance(mask, AsicMask):
            raise QDBBadAddr("Incorrect AsicMask!")
        print("setting asic mask:", xpos, ypos)
        addr = reg.ASIC(xpos, ypos, AsicREG.DIR)
        val = mask.value
        self.qpi.regWrite(addr, val)

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
