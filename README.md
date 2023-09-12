# Example of Reusable Verification for [ORConf23](https://orconf.org/)

[![CI](https://github.com/themperek/ORConf23/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/themperek/ORConf23/actions/workflows/ci.yml)


## Installation
 
- Install [conda](https://conda.io/miniconda.html) for Python3

- Install dependencies (check prerequisites for [cocotb](https://docs.cocotb.org/en/stable/install.html#installation-of-prerequisites) ):
```bash
conda env tdc -f environment.yml
conda activate tdc
```

## Running simulation

```bash
[WAVES=1] py.test [-n auto] test
```

## Building firmware

You need to install [f4pga](https://f4pga.org/) or use [docker](https://hdl.github.io/containers/ToolsAndImages.html#tools-and-images-f4pga)
```bash
pip install -r requirements.txt
cd fw
f4pga -vv build --flow ./flow.json
```


## Running emulation

```bash
openFPGALoader -b arty fw/build/tdc_emu_top.bit
EMU=1 py.test -s test
```
