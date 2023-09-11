
import logging
import array
from bitstruct import pack

import serial

from basil.TL.TransferLayer import TransferLayer

logger = logging.getLogger(__name__)


class uart_bridge(TransferLayer):
    def __init__(self, conf):
        super(uart_bridge, self).__init__(conf)

    def init(self):
        self._port = serial.Serial("COM5", 115200, timeout=1)

    def close(self):
        self._port.close()

    def write(self, addr, data):
        cmd = b"\x10" + pack("u8u32", len(data), addr) + bytearray(data)
        self._port.write(cmd)

    def read(self, addr, size):
        cmd = b"\x11" + pack("u8u32", size, addr)
        self._port.write(cmd)
        ret = self._port.read(size)
        return array.array("B", ret)
