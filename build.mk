# maxhpc: Maxim Vorontsov

${PROJECT}.bit: ${PROJECT}.config
	ecppack $< $@

${PROJECT}.config: ${PROJECT}.json
	nextpnr-ecp5 --json $< --textcfg $@ --um5g-85k --lpf ../ecpix5.lpf --package CABGA554 --freq 100 --lpf-allow-unconstrained

${PROJECT}.json: project.v
	yosys -p "synth_ecp5 -json $@" $<

project.v: $(SRC)
	sv2v $< > $@

clean:
	rm project.v ${PROJECT}.bit ${PROJECT}.config ${PROJECT}.json
