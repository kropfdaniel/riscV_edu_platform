yosys -import

set IMPL_DIR [file normalize "../../../../hdl/modules/spiXip/vhdl"]

ghdl --std=08 \
     $IMPL_DIR/spiXip_pkg.vhdl \
     $IMPL_DIR/spiByteTransceiver.vhdl \
     $IMPL_DIR/spiXipController.vhdl \
     $IMPL_DIR/spiXipBus.vhdl \
     edgeDetector.vhdl \
     genClockDiv.vhdl \
     firmware.vhdl \
     xip_hardware_tester.vhdl \
     -e xip_hardware_tester

synth_ecp5 -json build/xip_hardware_tester.json