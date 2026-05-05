SOURCES = hvsync_generator.v sin_rom.v project.v
NAME = wave-hi

PSOURCES = $(addprefix src/,$(SOURCES))

.PHONY: check
check:
	yosys -p 'read -vlog2k $(PSOURCES); check'

.PHONY: lint
lint:
	verilator --lint-only -Wall -Wno-DECLFILENAME $(PSOURCES)

wave-hi.vvp: $(PSOURCES)
	iverilog -v -o $@ $(PSOURCES)

.PHONY: icestick
icestick: $(NAME).bin

$(NAME).bin: $(PSOURCES) src/iceshim.v
	yosys icestick.ys
	nextpnr-ice40 --hx1k --package tq144 --json $(NAME).json --pcf icestick.pcf --asc $(NAME).asc --freq 25.175
	icepack $(NAME).asc $@
