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
    # special address where both data will be written over the top of addr
    CAL = 4
    # enable addr
    ENA = 5

def MemAddr(evt, pos):
    """
    Return address space for the event at a specific memory location.
    ARGS:
       evt - number of event
       pos - which 32 bit word within the event
    NOTE:
       Values are stored in BRAM located within DaqCtrl.vhd. only 32*3 bits are
       used (highest 32 are trimmed.)

       Readout procedure is also defined within DaqCtrl, where bottom two bits
       of the MemAddr is used to mux the word.
    """
    if pos not in [0,1,2]:
        raise QDBBadAddr("Incorrect Memory Read address! not acceptible word position!")
    if evt > 4095:
        raise QDBBadAddr("Incorrect Memory Read address! Evt too high!")

    # defined in ProtoRegMap
    evtMask = 1 << 16

    # defined as offset above addr for location in bram
    event = evt << 2

    # full address here
    return evtMask + event + pos

def AsicAddr(xpos=0, ypos=0, remote_addr=AsicREG.CMD):
    """
    return address space for remote ASIC.

    NOTE: remote_addr is the subaddr space at the remote ASIC definedin QpixRegFile.vhd

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

    These values should only be used at the specfic addr REG.ASIC(x, y, AsicREG.CMD).
    """
    Interrogation = 0x1
    ResetState = 0x2
    ResetAsic = 0x4


class AsicEnable(Enum):
    """
    Represents Values.

    Usage:
    qpi.regWrite(REG.ASIC(x, y, AsicREG.ENA), AsicEnable.SND)

    Simple Enum class to simplify remote ASIC enable types.

    These values can only be used at the specfic addr REG.ASIC(x, y, AsicREG.ENA).

    Values are defined in QpixRegFile.vhd and written to QpixConf type, defined
    in QPixPkg.vhd.
    """
    SND = 0x1 # enables analog data while sending
    RCV = 0x2 # enables analog data while receiving
    REG = 0x4 # enables analog data while broadcasting
    ALL = 0x7 # enables analog data in all situations
    OFF = 0x0 # disables analog data

    # combination states
    SND_RCV = 0x3
    SND_REG = 0x5
    RCV_REG = 0x6


class REG(Enum):
    """
    REG is an Enum class which returns a register address space for both the Zybo board
    and all of the remote ASICs in an array.

    There are two sets of addresses: Zybo address and remote ASIC address.

    A Zybo address is treated as a normal Enum member, i.e. REG.CMD.value

    A remote ASIC address is retrieved with REG.ASIC(xpos, ypos, AsicREG) method, i.e.
    REG.ASIC(0, 0) returns the ASIC at x=0, y=0 position.

    NOTE: There are two types of register transactions, either a read or a write; some
    addresses only support one type.

    specific register mappings are found in vhd files:
    QpixProtoPkg.vhd
    QpixRegFile.vhd
    """

    # all of these addresses are defined in QpixProtoPkg.vhd
    SCRATCH   = 0x00
    CMD       = 0x0A
    STATUS    = 0x01
    HITMASK   = 0x02
    TIMESTAMP = 0x03
    EVTSIZE   = 0x04
    TRGTIME   = 0x05
    CHANMASK  = 0x06
    ASICMASK  = 0x07
    FRAMEERR  = 0x08
    BREAKERR  = 0x09
    TESTOUT_H = 0x0b
    TESTOUT_L = 0x0c
    TESTIN_H  = 0x0d
    TESTIN_L  = 0x0e

    # event memory slots
    MEM = MemAddr

    # remote Asic Callable address class
    ASIC = AsicAddr


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
        connected = self._connect()

        if connected:
            # connect the write command to reading if anything comes back
            self._tcpsocket.readyRead.connect(lambda: self._readData())

            # make sure to check this works
            self._verify()

    def regRead(self, addr=REG) -> int:
        """
        read a Zybo register or a remote ASIC register as defined in REG class.

        Returns last 32 bit word from the register readout.
        """
        # allow passing of REG enum types directly
        if not isinstance(addr, REG) and hasattr(addr, "value"):
            raise QDBBadAddr("Incorrect REG address on regWrite!")
        elif hasattr(addr, "value"):
            addr = addr.value

        # form byte message
        args = ['QRR', addr]
        if isinstance(args, str): args = args.split(' ')
        hdr = args[0]+'\0'
        byte_arr = str.encode(hdr)
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
        # allow passing of REG enum types directly
        if not isinstance(addr, REG) and hasattr(addr, "value"):
            raise QDBBadAddr("Incorrect REG address on regWrite!")
        elif hasattr(addr, "value"):
            addr = addr.value
        if hasattr(val, "value"):
            val = val.value

        # form byte message
        args = ['QRW', addr, val]
        if isinstance(args, str): args = args.split(' ')
        hdr = args[0]+'\0'
        byte_arr = str.encode(hdr)
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
        version = self.regRead(REG.SCRATCH)
        print(f"Running version: 0x{version:08x}.. verifying..", end=" ")

        # update and check
        checksum = 0x0a0a_a0a0
        self.regWrite(REG.SCRATCH, checksum)
        verify  = self.regRead(REG.SCRATCH)
        if checksum != verify:
            print("warning verification failed")
            print(f"0x{checksum:08x} != 0x{verify:08x}")
        else:
            print("verification passed!")
            self.regWrite(REG.SCRATCH, version)

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
        connected = False
        try:
            addr = QHostAddress(self._QP_IP)
            self._tcpsocket.connectToHost(addr, self._QP_PORT)
            if self._tcpsocket.waitForConnected(1000):
                print("connected..")
                connected = True
            else:
                print("not connected..")

        except Exception as ex:
            print(ex)
            print("unconnected!")

        return connected

if __name__ == '__main__':
    qpi = qdb_interface()
    print()
    qpi.regRead(0)