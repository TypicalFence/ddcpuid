# ddcpuid, CPUID tool

ddcpuid is a simple and fast x86/AMD64 processor information tool, works best
with Intel and AMD processors where features are documentated.

I will gladly implement features from VIA, Zhaoxin, and others once I get
documentation.

The ddcpuid Technical Manual is available here:
[dd86k.space](https://dd86k.space/docs/ddcpuid-manual.pdf) (PDF).

Both the manual and tool is meant to be used together to fully understand
available features on the processor.

# Compiling

It is highly recommended to use the `-betterC` switch when compiling.

DMD, GDC, and LDC compilers are supported. Best supported by DMD.

## GDC Notes

GDC support is still experimental. **Compiling above -O1 segfaults at run-time.**
(tested on GDC 8.3.0-6ubuntu1~18.04.1)

## LDC Notes

Since LDC 1.13.0 includes lld-link on Windows platforms, the project may fail
to link. Using the older linker from Microsoft will likely fail as well. No 
work-arounds has been found up to this date other than using LDC 1.12.x.

**UPDATE**: This has been fixed in 1.15. Linker now includes
`legacy_stdio_definitions.lib`.

Recent versions of LDC (tested on 1.8.0 and 1.15) may "over-optimize" the hleaf
function (when compiling with -O), and while it's supposed to return the
highest cpuid leaf, it may return 0. To test such situation, use the -r switch
and see if the condition applies.

**UPDATE**: This has been fixed in commit d64fbceb68dbd9135b0c130776e9bb2c13a96237.
New function receives structure as reference to be populated. `hleaf` removed.