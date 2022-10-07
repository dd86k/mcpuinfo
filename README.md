# MCPUINFO, Olde Processor Identification Tool

MCPUINFO is an MS-DOS application used to identify pre-Pentium processors
and co-processors currently in use.

Example output: `8086+8087` with a newline.

Processors detected:
- 8086
- 80286
- 80386
- 80486

Co-processors detected:
- 8087
- 80287
- 80387

Command-line switches:
- `--help`, `/?`: Show help page and quit
- `--version`: Show version page and quit
- `--ver`: Print version only and quit

For a more sofisticated processor information tool,
see [ddcpuid](https://github.com/dd86k/ddcpuid).

## Compiling

This project uses NASM, because I like NASM.

It's as simple as:
```
nasm mcpuinfo.asm -fbin -omcpuinfo.com
```