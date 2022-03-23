# MCPUINFO, Olde Processor Identification Tool

MCPUINFO is a MS-DOS application used to identify pre-Pentium processors and co-processors currently in use.

The list of detected processors:
- 8086
- 80286
- 80386
- 80486

The list of detected co-processors:
- 8087
- 80287
- 80387

For a more sofisticated tool that supports the CPUID instruction, see my [ddcpuid](https://github.com/dd86k/ddcpuid) utility.

## Compiling

This project uses NASM, because I like NASM.

It's as simple as:
```
nasm mcpuinfo.asm -fbin -omcpuinfo.com
```