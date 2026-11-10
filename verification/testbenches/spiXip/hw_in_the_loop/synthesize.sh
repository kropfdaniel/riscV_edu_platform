mkdir -p build
yosys -m ghdl.so -c yosys.tcl
nextpnr-ecp5 --threads 7 --timing-allow-fail --85k --package CABGA381 --json build/xip_hardware_tester.json --lpf gecko5.lpf --textcfg build/xip_hardware_tester.config
ecppack --compress --freq 62.0 --input build/xip_hardware_tester.config --bit build/xip_hardware_tester.bit
openFPGALoader build/xip_hardware_tester.bit