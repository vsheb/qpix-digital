import qpix_interface as qpi
import sys

# GUI things
from PyQt5 import QtCore
from PyQt5.QtWidgets import QWidget
from PyQt5.QtCore import QProcess
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QApplication, QMainWindow, QAction


class QPIX_GUI(QMainWindow):
    def __init__(self, ip, port):
        super(QMainWindow, self).__init__()
        self.setWindowTitle('QDB Viewer')
        self._QP_IP = ip
        self._QP_PORT = port
        self._BUFFER_SIZE = 1024
        self._asicReg = qpi.ASIC_REQ_OFFSET
        self.qpc = qpi.QPController(ip=self._QP_IP, port=self._QP_PORT)

        # main window
        self.main_wid = QWidget() # store the main layout

        # main window interactive items
        self.setCentralWidget(self.main_wid)

        # initialize the sub menus
        self._make_menuBar()

        # show the main window
        self.show()


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

    def run(self):
        """current placeholder for the GUI"""
        print("qpc trying to read an event:")
        self.qpc.readEvent()

        input("waiting.. qpc sending a trigger?")
        self.qpc.sendTrg() # flash Rx

        input(f"waiting.. qpc reading from ASIC reg request at 0x{asicReg:02x}")
        self.qpc.regRead(asicReg) # flash Tx

if __name__ == "__main__":

    ip = '192.168.1.27'
    port = 7

    window = QPIX_GUI(ip, port)
    window.resize(800,700)
    app.exec_()
