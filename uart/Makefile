SRC = $(wildcard *.sv)

uart.bit: uart.config
	ecppack $< $@

uart.config: uart.json
	nextpnr-ecp5 --json $< --textcfg $@ --um5g-85k --lpf ../ecpix-5.lpf --package CABGA554 --freq 100 --lpf-allow-unconstrained

uart.json: $(SRC)
	yosys -p "synth_ecp5 -json $@" $<

clean:
	rm uart.bit uart.config uart.json
