# Recursive make is bad, but in this case we're cross compiling which is a
# pretty unusual use case.

CC = $(RISCV)/bin/riscv64-unknown-elf-gcc
OBJCOPY = $(RISCV)/bin/riscv64-unknown-elf-objcopy

all:	debug_rom.h debug_rom32.h

%.o:	%.S
	$(CC) -I.. -c $<

%.h:	%.raw
	xxd -i $^ | sed "s/^unsigned/static const unsigned/" > $@

%.raw:	%.elf
	$(OBJCOPY) -O binary --only-section .text $^ $@

%.elf:	%.o link.ld
	$(CC) -nostdlib -nostartfiles -Tlink.ld -o $@ $^

clean:
	rm -f debug_rom debug_rom.o debug_rom.raw debug_rom.h
