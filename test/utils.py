import os
import yaml
import threading
import basil
import time
from cocotb_test.run import run as run_sim
import socketserver
import sys


def sim_setup(test):
    
    proj_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    this_dir = os.path.dirname(os.path.abspath(__file__))
    sys.path = [proj_dir, os.path.dirname(os.getcwd())] + sys.path

    with open(proj_dir + "/tdc.yaml") as conf_file:
        conf = yaml.safe_load(conf_file)
    
    if not os.getenv("EMU"):
        
        basil_dir = os.path.dirname(basil.__file__)
        basil_include_dirs = [
            basil_dir + "/firmware/modules",
            basil_dir + "/firmware/modules/includes",
        ]

        defines = []
        if os.getenv("WAVES") is not None:
            defines = ["WAVES=1"]

        # Find free port
        with socketserver.TCPServer(("localhost", 0), None) as s:
            free_port = s.server_address[1]

        os.environ["SIMULATION_END_ON_DISCONNECT"] = "1"
        os.environ["COCOTB_REDUCED_LOG_FMT"] = "1"
        os.environ["SIMULATION_PORT"] = str(free_port)
        os.environ["SIMULATION_BUS"] = "basil.utils.sim.BasilSbusDriver"

        sim_args = {
            "verilog_sources": [proj_dir + "/test/tdc_tb.v"],
            "toplevel": "tb",
            "module": "basil.utils.sim.Test",
            "includes": [proj_dir, proj_dir + "/fw", proj_dir + "/dut"]  + basil_include_dirs,
            "sim_build": "sim_build/" + type(test).__name__ + "." + test._testMethodName,
            "defines" : defines,
            "waves": False
        }

        test.sim_thread = threading.Thread(target=run_sim, kwargs=sim_args, name="cocotb-test")
        test.sim_thread.start()

        conf["transfer_layer"][0]["type"] = "SiSim"
        conf["transfer_layer"][0]["tcp_connection"] = "False"
        conf["transfer_layer"][0]["init"]["port"] = free_port

    return conf

def sim_end(test):
    if not os.getenv("EMU"):
        # test.sim_thread.exit()
        while test.sim_thread.is_alive():
            time.sleep(0.1)
