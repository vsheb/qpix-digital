import sys
import time

# GUI things
from PyQt5 import QtCore
from PyQt5.QtWidgets import QWidget, QPushButton, QCheckBox, QSpinBox, QLabel, QDoubleSpinBox, QProgressBar
from PyQt5.QtCore import QProcess, QTimer
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QApplication, QMainWindow, QAction

class QPIX_GUI(QMainWindow):
    def __init__(self):
        super(QMainWindow, self).__init__()

        # main window
        self.main_wid = QWidget() # store the main layout
        self.setCentralWidget(self.main_wid)

        self._clock = QTimer()
        self._clock.timeout.connect(self.print_trigger)

        # testing button
        btn = QPushButton(self.main_wid)
        btn.setText('timer')
        btn.move(0,0)
        btn.clicked.connect(self.switch_clock)

        btn_print = QPushButton(self.main_wid)
        btn_print.setText('test')
        btn_print.move(0,40)
        btn_print.clicked.connect(self.print_test)

        btn_prog = QPushButton(self.main_wid)
        btn_prog.setText('proggers')
        btn_prog.move(0,80)
        btn_prog.clicked.connect(self.proggers)

        # progress tracker
        pbar = QProgressBar(self.main_wid)
        pbar.setRange(0, 100)
        pbar.move(240,240)
        pbar.setValue(50)
        self._progBar = pbar

        # button information for interrogation timer
        sBox_timeIter = QDoubleSpinBox(self.main_wid)
        sBox_timeIter.move(120,0)
        sBox_timeIter.setValue(0.5)
        sBox_timeIter.setRange(0.1, 100)
        self._timeValue = sBox_timeIter
        lsBox = QLabel(self.main_wid)
        lsBox.setText("Frq Iteration")
        lsBox.move(200, 0)

        # show the main window
        self.show()

    def proggers(self):
        """
        testing the progress bar
        """
        for i in range(10):
            print(f"step-{i}")
            time.sleep(0.25)
            self._progBar.setValue(i)

    def print_test(self):
        print('test')

    def print_trigger(self):
        print("ni hao")

    def switch_clock(self):
        val = self._timeValue.value()
        self._clock.setInterval(val*1000)
        print(f"setting value {val*1000} s")
        if self._clock.isActive():
            print("stopping clock..")
            self._clock.stop()
        else:
            print("starting clock..")
            self._clock.start()

if __name__ == "__main__":

    app = QApplication(sys.argv)
    window = QPIX_GUI()
    window.resize(800,700)
    app.exec_()
