joytest65.prg: joytest65.asm
	acme -r joytest65.rpt joytest65.asm

.PHONY: clean
clean:
	rm joytest65.rpt joytest65.prg
