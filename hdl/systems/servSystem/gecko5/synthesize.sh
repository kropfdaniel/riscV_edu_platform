#!/bin/bash
set -e

yosys -m ghdl.so -s yosys.script
nextpnr-ecp5 --threads 7 --timing-allow-fail --85k --package CABGA381 --json flash_programmer.json --lpf gecko5.lpf --textcfg flash_programmer.config
ecppack --compress --freq 62.0 --input flash_programmer.config --bit flash_programmer.bit
openFPGALoader flash_programmer.bit