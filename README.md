# ddcpuid
## A CPUID tool

Some more D practice with some inline assembly and structs/classes.

This small utility will reveal everything through `CPUID` -- A CPU instruction to get information about the CPU.

One day I'll figure how to generate a DLL, or use a LIB through C#.

Progress:
- Intel: 02H
- AMD: --

## Compiling
You must use the Digital Mars D (dmd) compiler, since the GNU D Compiler (gdc) does not support inline assembly. 

License: [MIT License](LICENSE)