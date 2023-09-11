import os
import sys
import time
import unittest
import logging
import utils
from basil.dut import Dut

import pytest
from parameterized import parameterized

import vsc


@vsc.covergroup
class cov(object):
    def __init__(self):
        self.with_sample(data=vsc.bit_t(8))
        self.data_cp = vsc.coverpoint(self.data, bins=dict(a=vsc.bin([0, 60]), b=vsc.bin([60, 255])))


class TestTDC(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cover = cov()

    @classmethod
    def tearDownClass(cls):
        vsc.write_coverage_db("ucis-coverage.xml")
        report = vsc.get_coverage_report_model()
        with open("metrics.txt", "a") as f:
            f.write(f"coverege {report.coverage}")

    def setUp(self):
        conf = utils.sim_setup(self)
        self.chip = Dut(conf)
        self.chip.init()

    def tearDown(self):
        self.chip.close()
        utils.sim_end(self)

    def rw_dut_spi(self, data):
        self.chip["SPI"].set_size(8)

        self.chip["SPI"].set_data([data])

        # need 2 times to read what was written
        for _ in range(2):
            self.chip["SPI"].start()
            while not self.chip["SPI"].is_ready:
                pass

        return self.chip["SPI"].get_data(size=1)[0]

    def write_config(self):
        self.chip["SPI"].set_size(8)

        self.chip["SPI"].set_data(self.chip["CONFIG_REG"].tobytes())

        self.chip["SPI"].start()
        while not self.chip["SPI"].is_ready:
            pass

    def test_i2c(self):
        ret = self.rw_dut_spi(55)

        logging.info(f"SPI:READ {ret}")
        self.assertEqual(ret, 55)

    def test_simple(self):
        self.assertEqual(self.chip["RX"].READY, 1)

        self.chip["CONFIG_REG"]["EN"] = 1
        self.write_config()

        self.assertEqual(self.chip["RX"].READY, 1)

        self.chip["RX"].ENABLE_RX = 1

        self.chip["TS_RESET"].DELAY = 1
        self.chip["TS_RESET"].WIDTH = 1

        self.chip["SIGNAL_SEQ"].set_data([0x00] * 32)
        self.chip["SIGNAL_SEQ"].set_data(
            [0x00] + [0x07] + [0x00] + [0x0F] + [0x00] + [0x1F] + [0x00] + [0x3F] + [0x00] * 16
        )
        self.chip["SIGNAL_SEQ"].REPEAT = 1
        self.chip["SIGNAL_SEQ"].SIZE = 8 * 8 + 8 * 16
        self.chip["SIGNAL_SEQ"].EN_EXT_START = 1

        self.chip["FIFO"].RESET
        self.chip["TS_RESET"].START

        while not self.chip["SIGNAL_SEQ"].READY:
            pass

        time.sleep(0.1)  # wait for all data in EMU mode

        self.assertEqual(self.chip["FIFO"].FIFO_SIZE, 16)
        logging.info(f"FIFO_SIZE: {self.chip['FIFO'].FIFO_SIZE}")

        tots = []
        tss = []
        data = self.chip["FIFO"].get_data()
        for i in range(len(data)):
            tot = data[i] & 0xFF
            ts = data[i] >> 8
            logging.info(f"DATA {i} {hex(data[i])} {ts} {tot}")
            tots.append(tot)
            tss.append(ts)

        tss = [x - 11 for x in tss]
        self.assertListEqual(tots, [2, 3, 4, 5])
        self.assertListEqual(tss, [0, 16, 32, 48])

    @parameterized.expand([[x] for x in range(4)])
    def test_parameterized(self, data):
        self.assertEqual(self.chip["RX"].READY, 1)

        self.cover.sample(data * 32)

        ret = self.rw_dut_spi(0x91)
        self.assertEqual(ret, 0x91)


if __name__ == "__main__":
    unittest.main()
