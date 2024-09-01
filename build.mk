# maxhpc: Maxim Vorontsov

${PROJECT}.bit: ${PROJECT}.cfg
	ecppack $< $@

${PROJECT}.cfg: ${PROJECT}.json
	nextpnr-ecp5 --json $< --textcfg $@ --um5g-85k --lpf ../ecpix5.lpf --package CABGA554 --freq 100 --lpf-allow-unconstrained --report ${PROJECT}.rpt

${PROJECT}.json: project.v
	yosys -p "synth_ecp5 -json $@" $<

project.v: $(SRC)
	sv2v ${SV2V_FLAGS} $^ > $@

clean:
	rm -rf ${PROJECT}.{rpt.bit,cfg,json} project.v
