#!/usr/bin/env python

import os
import socket
import struct
import sys
import glob
from enum import Enum
import time

# Qt5 dependencies
import PyQt5
from PyQt5.QtCore import QObject, QByteArray
from PyQt5.QtNetwork import QTcpSocket, QHostAddress

# global defualts to configure connection to socket
QP_IP      = '192.169.1.27'
QP_PORT    = 42069
BUFFER_SIZE = 1024

class QDBBadAddr(Exception):
    pass

class AsicREG(Enum):
    """
    Represents Addresses.

    Simple Enum to highlight remote addresses of QpixAsic.

    These address spaces are defined in QpixRegFile.vhd, within case selection.
    """
    CMD = 1
    TIMEOUT = 2
    DIR = 3

class AsicMask(Enum):
    """
    Represents Values.

    Simple Enum class to simplify remote ASIC direction values and enable manual routing.

    The mask values (1,2,4,8) are defined in QPixPkg.vhd.

    The 0x10 bit sets the manual routing bit, as defined in QpixRegFile.vhd.
    """
    DirUp = 1 + 0x10
    DirRight = 2 + 0x10
    DirDown = 4 + 0x10
    DirLeft = 8 + 0x10

class AsicCMD(Enum):
    """
    Represents Values.

    Simple Enum class to simplify remote ASIC individual commands.

    These remote commands can only be used at the specfic REG.ASIC(x, y,
    AsicREG.CMD) address.

    NOTE: using a 'trigger' calls the equivalent of an Interrogation at all remote ASICs.
    """
    Interrogation = 0x1
    ResetState = 0x2
    ResetAsic = 0x4

class REG():
    """
    REG is an class which returns a register address space for both the Zybo board
    and all of the remote ASICs in an array.

    There are two sets of addresses: Zybo address and remote ASIC address.

    A Zybo address is treated as a public member of this class, i.e. REG.CMD

    A remote ASIC address is retrieved with the ASIC(xpos, ypos, AsicREG) method, i.e.
    REG.ASIC(0, 0) returns the ASIC at x=0, y=0 position.
    NOTE: remote_addr is the subaddr space at the remote ASIC definedin QpixRegFile.vhd

    NOTE: There are two types of register transactions, either a read or a write; some
    addresses only support one type.

    specific register mappings are found in vhd files:
    QpixProtoPkg.vhd
    QpixRegFile.vhd
    """
    def __init__(self):

        # all of these addresses are defined in QpixProtoPkg.vhd
        self.SCRATCH   = 0x00
        self.CMD       = 0x0A
        self.STATUS    = 0x01
        self.HITMASK   = 0x02
        self.TIMESTAMP = 0x03
        self.EVTSIZE   = 0x04
        self.TRGTIME   = 0x05
        self.CHANMASK  = 0x06
        self.ASICMASK  = 0x07
        self.FRAMEERR  = 0x08
        self.BREAKERR  = 0x09
        self.TESTOUT_H = 0x0b
        self.TESTOUT_L = 0x0c
        self.TESTIN_H  = 0x0d
        self.TESTIN_L  = 0x0e


    def ASIC(self, xpos, ypos, remote_addr=AsicREG):
        """
        return address space for remote ASIC.

        This protocol is implemented in QpixDaqCtrl.vhd
        """
        if not isinstance(remote_addr, AsicREG):
            raise QDBBadAddr("Incorrect Remote ASIC ADDR!")
        else:
            # QpixDaqCtrl.vhd selects these address spaces:
            xp = ((xpos & 0b111)<<6)
            yp = ((ypos & 0b111)<<3)
            dest_flag = 1 << 9

            # this address flag is defined within QpixProtoRegMap.vhd
            asic_addr_flag = 3 << 16

            # combine and return net addr space
            addr = asic_addr_flag + dest_flag + xp + yp + remote_addr.value
            return addr


reg = REG()

class qdb_interface(QObject):
    """
    Generic interface class which manages the socket transactions and retrieves
    data from transactions.

    This class is responsible for handling signals and slots between the
    tcpsocket and the Zybo.

    The only public methods that should be used from this interface are reading
    and writing between registers: regRead and regWrite.

    It is up to the user to ensure that all addresses and values used in those two
    methods correspond to the above register classes.
    """

    def __init__(self, ip=QP_IP, port=QP_PORT):
        super().__init__()
        self._QP_IP = QHostAddress(QP_IP)
        self._QP_PORT = port
        # self._BUFFER_SIZE = BUFFER_SIZE

        # storage for retrieiving tcp data
        self.data = None

        # create the tcp socket
        self._tcpsocket = QTcpSocket(self)
        self._connect()

        # connect the write command to reading if anything comes back
        self._tcpsocket.readyRead.connect(lambda: self._readData())

        # make sure to check this works
        self._verify()

    def regRead(self, addr=REG) -> int:
        """
        read a Zybo register or a remote ASIC register as defined in REG class.

        Returns last 32 bit word from the register readout.
        """
        # if not isinstance(addr, REG):
        #     raise QDBBadAddr("Incorrect Remote REG address on regRead!")

        args = ['QRR', addr]
        if isinstance(args, str): args = args.split(' ')
        hdr = args[0]+'\0'
        byte_arr = str.encode(hdr)

        # form byte message
        for arg in args[1:]:
            if not isinstance(arg, int): arg = int(arg, 0)
            byte_arr += struct.pack('<I', arg)

        self._write(byte_arr)
        self._tcpsocket.waitForReadyRead(1000)

        # make sure there's new data to return
        if self.data is not None:
            data = self.data
            self.data = None
            return data
        else:
            print('WARNING: REG no data!')
            return None

    def regWrite(self, addr, val) -> int:
        """
        Register write command, used for either writing directly to remote ASICs
        or Zybo.
        """
        # if not isinstance(addr, REG):
        #     raise QDBBadAddr("Incorrect REG address on regWrite!")

        args = ['QRW', addr, val]
        if isinstance(args, str): args = args.split(' ')
        hdr = args[0]+'\0'
        byte_arr = str.encode(hdr)

        # form byte message
        for arg in args[1:]:
            if not isinstance(arg, int): arg = int(arg, 0)
            byte_arr += struct.pack('<I', arg)

        # returns number of bytes written
        cnt = self._write(byte_arr)
        self._tcpsocket.waitForReadyRead(1000)
        return cnt

    def _verify(self) -> bool:
        """
        initialization function to make sure that the interface can communicate
        with the scratch buffer.

        A correct verification performs a successful regRead and regWrite of the
        REG.SCRATCH buffer.
        """
        version = self.regRead(reg.SCRATCH)
        print(f"Running version: 0x{version:08x}.. verifying..", end=" ")

        # update and check
        checksum = 0x0a0a_a0a0
        self.regWrite(reg.SCRATCH, checksum)
        verify  = self.regRead(reg.SCRATCH)
        if checksum != verify:
            print("warning verification failed")
            print(f"0x{checksum:08x} != 0x{verify:08x}")
        else:
            print("verification passed!")
            self.regWrite(reg.SCRATCH, version)

        return checksum == verify

    def _readData(self) -> int:
        """
        PyQtSlot: Read data from the socket whenever something shows up.

        ARGS: opt: optional integer to fiure out which signal emitted call

        Returns the last 32 bit word from the socket, and handles tcp response
        """

        ## failed UDP socket?
        # while self._udpsocket.hasPendingDatagrams():
        #     datagram = QByteArray()
        #     datagram.resize(self._udpsocket.pendingDatagramSize())
        #     (sender, senderPort) = udpSocket.readDatagram(datagram.data(), datagram.size())
        #     print("read back udp datagram!")

        while self._tcpsocket.bytesAvailable():
            data = self._tcpsocket.read(4)
            val = struct.unpack('<I', data)[0]
            self.data = val

        return self.data

    def _write(self, data):
        wrote = self._tcpsocket.write(data)
        self._tcpsocket.waitForBytesWritten(1000)
        return wrote

    def _connect(self):
        """
        connect to the remote socket and find the zybo board.
        """
        print("..conecting..", end=" ")
        try:
            addr = QHostAddress(self._QP_IP)
            self._tcpsocket.connectToHost(addr, self._QP_PORT)
            if self._tcpsocket.waitForConnected(1000):
                print("connected..")
            else:
                print("not connected..")

        except Exception as ex:
            print(ex)
            print("unconnected!")

if __name__ == '__main__':
    qpi = qdb_interface()
    print()
    qpi.regRead(0)
