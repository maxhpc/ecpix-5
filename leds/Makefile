SRC = $(wildcard *.sv)

leds.bit: leds.config
	ecppack $< $@

leds.config: leds.json
	nextpnr-ecp5 --json $< --textcfg $@ --um5g-85k --lpf ../ecpix-5.lpf --package CABGA554 --freq 100 --lpf-allow-unconstrained

leds.json: $(SRC)
	yosys -p "synth_ecp5 -json $@" $<

clean:
	rm leds.bit leds.config leds.json
