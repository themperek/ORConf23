#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#


from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class tdc_rx(RegisterHardwareLayer):
    """Receiver controller interface for tdc_rx FPGA module"""

    _registers = {
        "RESET": {"descr": {"addr": 0, "size": 8, "properties": ["writeonly"]}},
        "RX_RESET": {"descr": {"addr": 1, "size": 8, "properties": ["writeonly"]}},
        "VERSION": {"descr": {"addr": 0, "size": 8, "properties": ["ro"]}},
        "READY": {"descr": {"addr": 2, "size": 1, "properties": ["ro"]}},
        "INVERT_RX": {"descr": {"addr": 2, "size": 1, "offset": 1}},
        "ENABLE_RX": {"descr": {"addr": 2, "size": 1, "offset": 2}},
        "FIFO_SIZE": {
            "default": 0,
            "descr": {"addr": 3, "size": 16, "properties": ["ro"]},
        },
        "DECODER_ERROR_COUNTER": {
            "descr": {"addr": 5, "size": 8, "properties": ["ro"]}
        },
        "LOST_DATA_COUNTER": {"descr": {"addr": 6, "size": 8, "properties": ["ro"]}},
    }
    _require_version = "==3"
