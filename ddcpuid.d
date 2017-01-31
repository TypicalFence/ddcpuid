module ddcpuid;

import std.stdio : write, writef, writeln, writefln;
import std.string : strip;

/// Version
const enum VERSION = "0.3.0";

const enum { // Vendor strings
    VENDOR_INTEL     = "GenuineIntel",
    VENDOR_AMD       = "AuthenticAMD",
    VENDOR_VIA       = "VIA VIA VIA ",
    VENDOR_CENTAUR   = "CentaurHauls", // VIA aquired Centaur
    VENDOR_TRANSMETA = "GenuineTMx86",
    VENDOR_CYRIX     = "CyrixInstead",
    VENDOR_NEXGEN    = "NexGenDriven",
    VENDOR_UMC       = "UMC UMC UMC ",
    VENDOR_SIS       = "SiS SiS SiS ",
    VENDOR_NSC       = "Geode by NSC",
    VENDOR_RISE      = "RiseRiseRise",
    VENDOR_VORTEX    = "Vortex86 SoC",
    VENDOR_NS        = "Geode by NSC", // National Semiconductor
    // Older vendor strings
    VENDOR_OLDAMD       = "AMDisbetter!", // Early K5
    VENDOR_OLDTRANSMETA = "TransmetaCPU",
    // Virtual Machines
    VENDOR_VMWARE       = "VMwareVMware",
    VENDOR_XENHVM       = "XenVMMXenVMM",
    VENDOR_MICROSOFT_HV = "Microsoft Hv",
    VENDOR_PARALLELS    = " lrpepyh vr"
}

version(DLL)
{
import core.sys.windows.windows, core.sys.windows.dll;
/// Handle instance
__gshared HINSTANCE g_hInst;
 
/// DLL Entry point
version(Windows) extern(Windows) bool DllMain(void* hInstance, uint ulReason, void*)
{
    switch (ulReason)
    {
        default: assert(0);
        case DLL_PROCESS_ATTACH:
            dll_process_attach(hInstance, true);
            break;

        case DLL_PROCESS_DETACH:
            dll_process_detach(hInstance, true);
            break;

        case DLL_THREAD_ATTACH:
            dll_thread_attach(true, true);
            break;

        case DLL_THREAD_DETACH:
            dll_thread_detach(true, true);
            break;
    }
    return true;
}

// Trash
/// Gets the class object for this DLL
version(Windows) extern(Windows) void DllGetClassObject() {}
/// Returns if the DLL can unload now
version(Windows) extern(Windows) void DllCanUnloadNow() {}
/// Registers with the COM server
version(Windows) extern(Windows) void DllRegisterServer() {}
/// Unregisters with the COM server
version(Windows) extern(Windows) void DllUnregisterServer() {}
} else {
void main(string[] args)
{
    bool _raw = false; // Raw
    bool _det = false; // Detailed output
    bool _ovr = false; // Override max leaf
    bool _ver = false; // Verbose
    bool _exp = false; // Experiments

    foreach (s; args)
    {
        switch (s)
        {
        case "/?", "-h", "--help":
            writefln(" %s [<Options>]", args[0]);
            writefln(" %s {-h|--help|/?|-v|--version}", args[0]);
            writeln();
            writeln(" -d, --details      Show more details.");
            writeln(" -e, --experiments  Use experimental features.");
            writeln(" -o, --override     Override leafs to 20h and 8000_0020h.");
            writeln(" -V, --verbose      Show debugging information.");
            writeln(" -r, --raw          Only show raw CPUID data.");
            writeln();
            writeln(" --help, -h, /?  Print help and quit.");
            writeln(" --version, -v   Print version and quit.");
            return;
 
        case "-v", "--version", "/v", "/version":
            writefln("%s v%s", args[0], VERSION);
            writeln("Copyright (c) dd86k 2016");
            writeln("License: MIT License <http://opensource.org/licenses/MIT>");
            writeln("Project page: <https://github.com/guitarxhero/ddcpuid>");
            writefln("Compiled %s at %s, using %s version %s.",
                __FILE__, __TIMESTAMP__, __VENDOR__, __VERSION__);
            return;

        case "-d", "--details", "/d", "/details":
            if (_ver)
                writefln("[%4d] Details flag ON.", __LINE__);
            _det = true;
            break;

        case "-e", "--experiments", "/e", "/experiments":
            if (_ver)
                writefln("[%4d] Experimental flag ON.", __LINE__);
            _exp = true;
            break;

        case "-o", "--override", "/o", "/override":
            if (_ver)
                writefln("[%4d] Override flag ON.", __LINE__);
            _ovr = true;
            break;

        case "-r", "--raw", "/r", "/raw":
            if (_ver)
                writefln("[%4d] Raw flag ON.", __LINE__);
            _raw = true;
            break;

        case "-V", "--verbose", "/V", "/Verbose":
            _ver = true;
            if (_ver)
                writefln("[%4d] Verbose flag ON.", __LINE__);
            break;

        default:
        }
    }

    if (_ver)
        writefln("[%4d] Verbose mode on", __LINE__);

    // Maximum leaf
    uint max = _ovr ? 0x20 : getHighestLeaf();
    // Maximum extended leaf
    uint emax = _ovr ? 0x8000_0020 : getHighestExtendedLeaf();

    if (_ver)
        writefln("[%4d] Max: %d | Extended Max: %d", __LINE__, max, emax);

    if (_raw)
    {
        writeln("|   Leaf   | S | EAX      | EBX      | ECX      | EDX      |");
        writeln("|----------|---|----------|----------|----------|----------| ");
        uint _eax, _ebx, _ecx, _edx, _ebp, _esp, _edi, _esi;
        asm
        {
            mov _ebp, EBP;
            mov _esp, ESP;
            mov _edi, EDI;
            mov _esi, ESI;
        }
        uint subl = 0;
        for (int leaf = 0; leaf <= max;)
        {
            asm
            {
                mov EAX, leaf;
                mov ECX, subl;
                cpuid;
                mov _eax, EAX;
                mov _ebx, EBX;
                mov _ecx, ECX;
                mov _edx, EDX;
            }
            writefln("| %8X | %X | %8X | %8X | %8X | %8X |",
                leaf, subl, _eax, _ebx, _ecx, _edx);
                
            if (leaf == 0xB && subl < 2) {
                ++subl;
            } else {
                subl = 0;
                ++leaf;
            }
        }
        for (int eleaf = 0x8000_0000; eleaf <= emax; ++eleaf)
        {
            asm
            {
                mov EAX, eleaf;
                cpuid;
                mov _eax, EAX;
                mov _ebx, EBX;
                mov _ecx, ECX;
                mov _edx, EDX;
            }
            writefln("| %8X | %X | %8X | %8X | %8X | %8X |",
                eleaf, subl, _eax, _ebx, _ecx, _edx);
        }
        writefln("EBP=%-8X ESP=%-8X EDI=%-8X ESI=%-8X",
            _ebp, _esp, _edi, _esi);
    }
    else
    {
        if (_ver)
            writefln("[%4d] Getting info...", __LINE__);

        const CpuInfo ci = new CpuInfo;
        
        with (ci)
        {
            writeln("Vendor: ", Vendor);
            writeln("Model: ", ProcessorBrandString);
            if (_exp)
                writeln("Number of logical cores (Experimental): ", getnlc);

            if (_det)
                writefln("Identification: Family %Xh [%Xh:%Xh] Model %Xh [%Xh:%Xh] Stepping %Xh",
                    Family, BaseFamily, ExtendedFamily, Model, BaseModel, ExtendedModel, Stepping);
            else
                writefln("Identification: Family %d Model %d Stepping %d",
                    Family, Model, Stepping);

            write("Extensions: ");
            if (MMX)
                write("MMX, ");
            if (SSE)
                write("SSE, ");
            if (SSE2)
                write("SSE2, ");
            if (SSE3)
                write("SSE3, ");
            if (SSSE3)
                write("SSSE3, ");
            if (SSE41)
                write("SSE4.1, ");
            if (SSE42)
                write("SSE4.2, ");
            if (SSE4a)
                write("SSE4a, ");
            if (LongMode)
                switch (Vendor)
                {
                    case VENDOR_INTEL: write("Intel64, "); break;
                    case VENDOR_AMD  : write("AMD64, ");   break;
                    default          : write("x86-64,");
                }
            if (Virtualization)
                switch (Vendor)
                {
                    case VENDOR_INTEL: write("VT-x, ");   break; // VMX
                    case VENDOR_AMD  : write("AMD-V, ");  break; // SVM
                    case VENDOR_VIA  : write("VIA VT, "); break;
                    default          : write("VMX, ");
                }
            if (AESNI)
                write("AES-NI, ");
            if (AVX)
                write("AVX, ");
            if (AVX2)
                write("AVX2, ");
            if (SMX)
                write("SMX, ");
            if (DS_CPL)
                write("DS-CPL, ");
            if (FMA) 
                write("FMA, ");
            if (F16C)
                write("F16C, ");
            if (XSAVE)
                write("XSAVE, ");
            if (OSXSAVE)
                write("OSXSAVE, ");
            writeln();

            if (_det)
            {
                write("Single instructions: [ ");
                if (MONITOR)
                    write("MONITOR/MWAIT, ");
                if (PCLMULQDQ)
                    write("PCLMULQDQ, ");
                if (CX8)
                    write("CMPXCHG8B, ");
                if (CMPXCHG16B)
                    write("CMPXCHG16B, ");
                if (MOVBE)
                    write("MOVBE, "); // Intel Atom and quite a few AMD processorss.
                if (RDRAND)
                    write("RDRAND, ");
                if (MSR)
                    write("RDMSR/WRMSR, ");
                if (SEP)
                    write("SYSENTER/SYSEXIT, ");
                if (TSC)
                {
                    write("RDTSC");
                    if (TscDeadline || TscInvariant)
                    {
                        write(" (");
                        if (TscDeadline)
                            write("TSC-Deadline");
                        if (TscInvariant)
                            write(", TSC-Invariant");
                        write(")");
                    }
                    write(", ");
                }
                if (CMOV)
                    write("CMOV, ");
                if (FPU && CMOV)
                    write("FCOMI/FCMOV, ");
                if (CLFSH)
                    writef("CLFLUSH (Lines: %s), ", CLFLUSHLineSize);
                if (POPCNT)
                    write("POPCNT, ");
                if (FXSR)
                    write("FXSAVE/FXRSTOR, ");
                writeln("]");

                writefln("Highest Leaf: %02XH | Extended: %02XH", max, emax);
                write("Processor type: ");
                final switch (ProcessorType) // 2 bit value
                { // Should return 0 these days.
                    case 0:
                        writeln("Original OEM Processor");
                        break;
                    case 1:
                        writeln("Intel OverDrive Processor");
                        break;
                    case 2:
                        writeln("Dual processor");
                        break;
                    case 3:
                        writeln("Intel reserved");
                        break;
                }

                writeln("Brand Index: ", BrandIndex);
                writeln("Floating Point Unit [FPU]: ", FPU);
                writefln("APIC: %s (Initial ID: %s)", APIC, InitialAPICID);
                writeln("x2APIC: ", x2APIC);
                writeln("Maximum number of IDs: ", MaxIDs);
                writeln("64-bit DS Area [DTES64]: ", DTES64);
                writeln("Thermal Monitor [TM]: ", TM);
                writeln("Thermal Monitor 2 [TM2]: ", TM2);
                writeln("L1 Context ID [CNXT-ID]: ", CNXT_ID);
                writeln("xTPR Update Control [xTPR]: ", xTPR);
                writeln("Perfmon and Debug Capability [PDCM]: ", PDCM);
                writeln("Process-context identifiers [PCID]: ", PCID);
                writeln("Direct Cache Access [DCA]: ", DCA);
                writeln("Virtual 8086 Mode Enhancements [VME]: ", VME);
                writeln("Debugging Extensions [DE]: ", DE);
                writeln("Page Size Extension [PAE]: ", PAE);
                writeln("Machine Check Exception [MCE]: ", MCE);
                writeln("Memory Type Range Registers [MTRR]: ", MTRR);
                writeln("Page Global Bit [PGE]: ", PGE);
                writeln("Machine Check Architecture [MCA]: ", MCA);
                writeln("Page Attribute Table [PAT]: ", PAT);
                writeln("36-Bit Page Size Extension [PSE-36]: ", PSE_36);
                writeln("Processor Serial Number [PSN]: ", PSN);
                writeln("Debug Store [DS]: ", DS);
                writeln("Thermal Monitor and Software Controlled Clock Facilities [APCI]: ", APCI);
                writeln("Self Snoop [SS]: ", SS);
                writeln("Pending Break Enable [PBE]: ", PBE);
                writeln("Supervisor Mode Execution Protection [SMEP]: ", SMEP);
                write("Bit manipulation groups: ");
                if (BMI1 || BMI2)
                {
                    if (BMI1)
                        write("BMI1, ");
                    if (BMI2)
                        write("BMI2");
                }
                else
                    writeln("None");
            } // if (_det)
        } // with (c)
    } // else if
} // main

/***********
 * Classes *
 ***********/

/// <summary>
/// Provides a set of information about the processor.
/// </summary>
public class CpuInfo
{
    /// Initiates a CPU_INFO.
    this(bool fetch = true, bool verbose = false)
    {
        if (fetch)
            fetchInfo(verbose);
    }

    /// Fetches the information 
    public void fetchInfo(bool verbose = false)
    {
        Vendor = getVendor();
        ProcessorBrandString = strip(getProcessorBrandString());

        MaximumLeaf = getHighestLeaf();
        MaximumExtendedLeaf = getHighestExtendedLeaf();

        int a, b, c, d;
        for (int leaf = 1; leaf <= MaximumLeaf; ++leaf)
        {
            asm @nogc nothrow
            {
                mov EAX, leaf;
                cpuid;
                mov a, EAX;
                mov b, EBX;
                mov c, ECX;
                mov d, EDX;
            }

            switch (leaf)
            { // case 0 has already has been handled (max leaf and vendor).
                case 1: // 01H -- Basic CPUID Information
                    // EAX
                    BaseFamily     = a >>  8 &  0xF; // EAX[11:8]
                    ExtendedFamily = a >> 20 & 0xFF; // EAX[27:20]
                    BaseModel      = a >>  4 &  0xF; // EAX[7:4]
                    ExtendedModel  = a >> 16 &  0xF; // EAX[19:16]
                    switch (Vendor) // Vendor specific features.
                    {
                        case "GenuineIntel":
                            if (BaseFamily != 0)
                                Family = BaseFamily;
                            else
                                Family = cast(ubyte)(ExtendedFamily + BaseFamily);

                            if (BaseFamily == 6 || BaseFamily == 0)
                                Model = cast(ubyte)((ExtendedModel << 4) + BaseModel);
                            else // DisplayModel = Model_ID;
                                Model = BaseModel;

                            // ECX
                            DTES64         = c >>  2 & 1;
                            DS_CPL         = c >>  4 & 1;
                            Virtualization = c >>  5 & 1;
                            SMX            = c >>  6 & 1;
                            EIST           = c >>  7 & 1;
                            CNXT_ID        = c >> 10 & 1;
                            SDBG           = c >> 11 & 1;
                            xTPR           = c >> 14 & 1;
                            PDCM           = c >> 15 & 1;
                            PCID           = c >> 17 & 1;
                            DCA            = c >> 18 & 1;
                            DS             = d >> 21 & 1;
                            APCI           = d >> 22 & 1;
                            SS             = d >> 27 & 1;
                            TM             = d >> 29 & 1;
                            PBE            = d >> 31 & 1;
                            break;

                        case "AuthenticAMD":
                            if (BaseFamily < 0xF)
                            {
                                Family = BaseFamily;
                                Model = BaseModel;
                            }
                            else
                            {
                                Family = cast(ubyte)(ExtendedFamily + BaseFamily);
                                Model = cast(ubyte)((ExtendedModel << 4) + BaseModel);
                            }
                            break;

                            default:
                    }
                    ProcessorType = (a >> 12) & 3; // EAX[13:12]
                    Stepping      = a & 0xF;       // EAX[3:0]
                    // EBX
                    BrandIndex      = b & 0xFF;       // EBX[7:0]
                    CLFLUSHLineSize = b >> 8 & 0xFF;  // EBX[15:8]
                    MaxIDs          = b >> 16 & 0xFF; // EBX[23:16]
                    InitialAPICID   = b >> 24 & 0xFF; // EBX[31:24]
                    // ECX
                    SSE3        = c & 1;
                    PCLMULQDQ   = c >>  1 & 1;
                    MONITOR     = c >>  3 & 1;
                    TM2         = c >>  8 & 1;
                    SSSE3       = c >>  9 & 1;
                    FMA         = c >> 12 & 1;
                    CMPXCHG16B  = c >> 13 & 1;
                    SSE41       = c >> 19 & 1;
                    SSE42       = c >> 20 & 1;
                    x2APIC      = c >> 21 & 1;
                    MOVBE       = c >> 22 & 1;
                    POPCNT      = c >> 23 & 1;
                    TscDeadline = c >> 24 & 1;
                    AESNI       = c >> 25 & 1;
                    XSAVE       = c >> 26 & 1;
                    OSXSAVE     = c >> 27 & 1;
                    AVX         = c >> 28 & 1;
                    F16C        = c >> 29 & 1;
                    RDRAND      = c >> 30 & 1;
                    // EDX
                    FPU    = d & 1;
                    VME    = d >>  1 & 1;
                    DE     = d >>  2 & 1;
                    PSE    = d >>  3 & 1;
                    TSC    = d >>  4 & 1;
                    MSR    = d >>  5 & 1;
                    PAE    = d >>  6 & 1;
                    MCE    = d >>  7 & 1;
                    CX8    = d >>  8 & 1;
                    APIC   = d >>  9 & 1;
                    SEP    = d >> 11 & 1;
                    MTRR   = d >> 12 & 1;
                    PGE    = d >> 13 & 1;
                    MCA    = d >> 14 & 1;
                    CMOV   = d >> 15 & 1;
                    PAT    = d >> 16 & 1;
                    PSE_36 = d >> 17 & 1;
                    PSN    = d >> 18 & 1;
                    CLFSH  = d >> 19 & 1;
                    MMX    = d >> 23 & 1;
                    FXSR   = d >> 24 & 1;
                    SSE    = d >> 25 & 1;
                    SSE2   = d >> 26 & 1;
                    HTT    =(d >> 28 & 1) && (MaxIDs > 1);
                    break;

                case 2: // 02h -- Cache and TLB Information. | AMD: Reserved

                    break;

                case 6: // 06h -- Thermal and Power Management Leaf | AMD: Reversed
                    switch (Vendor)
                    {
                        case VENDOR_INTEL:
                            TurboBoost = a >> 1 & 1;
                            break;
                        default:
                    }
                    break;

                    default:

                case 7:
                    BMI1 = b >> 3 & 1;
                    AVX2 = b >> 5 & 1;
                    SMEP = b >> 7 & 1;
                    BMI2 = b >> 8 & 1;
                    break;
            }
        }

        /************
         * EXTENDED *
         ************/

        for (int eleaf = 0x8000_0000; eleaf < MaximumExtendedLeaf; ++eleaf)
        {
            asm @nogc nothrow
            {
                mov EAX, eleaf;
                cpuid;
                mov a, EAX;
                mov b, EBX;
                mov c, ECX;
                mov d, EDX;
            }

            switch (eleaf)
            {
                case 0x8000_0001:
                    switch (Vendor)
                    {
                        case VENDOR_AMD:
                            Virtualization = c >> 2 & 1; // SVM/VMX
                            SSE4a = c >> 6 & 1;
                            break;

                        default:
                    }

                    LongMode = d >> 29 & 1;

                    break;

                case 0x8000_0007:
                    switch (Vendor)
                    {
                        case VENDOR_AMD:
                            TM = d >> 4 & 1;
                            break;
                        default:
                    }

                    TscInvariant = d >> 8 & 1;
                    break;
                default:
            }
        }
    }

    /*************************
     * PROCESSOR INFORMATION *
     *************************/

    // ---- Basic information ----
    /// Processor vendor.
    string Vendor;
    /// Processor brand string.
    string ProcessorBrandString;

    /// Maximum leaf supported by this processor.
    int MaximumLeaf;
    /// Maximum extended leaf supported by this processor.
    int MaximumExtendedLeaf;

    /// Also known as Intel64 or AMD64.
    bool LongMode;

    /// Number of physical cores.
    ushort NumberOfCores;
    /// Number of logical cores.
    ushort NumberOfThreads;

    /// Processor family. ID and extended ID included.
    ushort Family;
    /// Base Family ID
    ubyte BaseFamily;
    /// Extended Family ID
    ubyte ExtendedFamily;
    /// Processor model. ID and extended ID included.
    ubyte Model;
    /// Base Model ID
    ubyte BaseModel;
    /// Extended Model ID
    ubyte ExtendedModel;
    /// Processor stepping.
    ubyte Stepping;
    /// Processor type.
    ubyte ProcessorType;

    /// MMX Technology.
    bool MMX;
    /// Streaming SIMD Extensions.
    bool SSE;
    /// Streaming SIMD Extensions 2.
    bool SSE2;
    /// Streaming SIMD Extensions 3.
    bool SSE3;
    /// Supplemental Streaming SIMD Extensions 3 (SSSE3).
    bool SSSE3;
    /// Streaming SIMD Extensions 4.1.
    bool SSE41;
    /// Streaming SIMD Extensions 4.2.
    bool SSE42;
    /// Streaming SIMD Extensions 4a. AMD-only.
    bool SSE4a;
    /// AESNI instruction extensions.
    bool AESNI;
    /// AVX instruction extensions.
    bool AVX;
    /// AVX2 instruction extensions.
    bool AVX2;

    // ---- 01h : Basic CPUID Information ----
    // -- EBX --
    /// Brand index. See Table 3-24. If 0, use normal BrandString.
    ubyte BrandIndex;
    /// The CLFLUSH line size. Multiply by 8 to get its size in bytes.
    ubyte CLFLUSHLineSize;
    /// Maximum number of addressable IDs for logical processors in this physical package.
    ubyte MaxIDs;
    /// Initial APIC ID that the process started on.
    ubyte InitialAPICID;
    // -- ECX --
    /// PCLMULQDQ instruction.
    bool PCLMULQDQ; // 1
    /// 64-bit DS Area (64-bit layout).
    bool DTES64;
    /// MONITOR/MWAIT.
    bool MONITOR;
    /// CPL Qualified Debug Store.
    bool DS_CPL;
    /// Virtualization | Virtual Machine eXtensions (Intel) | Secure Virtual Machine (AMD) 
    bool Virtualization;
    /// Safer Mode Extensions.
    bool SMX;
    /// Enhanced Intel SpeedStep® Technology.
    bool EIST;
    /// Thermal Monitor 2.
    bool TM2;
    /// L1 Context ID.
    bool CNXT_ID;
    /// Indicates the processor supports IA32_DEBUG_INTERFACE MSR for silicon debug.
    bool SDBG;
    /// FMA extensions using YMM state.
    bool FMA;
    /// CMPXCHG16B instruction.
    bool CMPXCHG16B;
    /// xTPR Update Control.
    bool xTPR;
    /// Perfmon and Debug Capability.
    bool PDCM;
    /// Process-context identifiers.
    bool PCID;
    /// Direct Cache Access.
    bool DCA;
    /// x2APIC feature (Intel programmable interrupt controller).
    bool x2APIC;
    /// MOVBE instruction.
    bool MOVBE;
    /// POPCNT instruction.
    bool POPCNT;
    /// Indicates if the APIC timer supports one-shot operation using a TSC deadline value.
    bool TscDeadline;
    /// Indicates the support of the XSAVE/XRSTOR extended states feature, XSETBV/XGETBV instructions, and XCR0.
    bool XSAVE;
    /// Indicates if the OS has set CR4.OSXSAVE[18] to enable XSETBV/XGETBV instructions for XCR0 and XSAVE.
    bool OSXSAVE;
    /// 16-bit floating-point conversion instructions.
    bool F16C;
    /// RDRAND instruction.
    bool RDRAND; // 30
    // -- EDX --
    /// Floating Point Unit On-Chip. The processor contains an x87 FPU.
    bool FPU; // 0
    /// Virtual 8086 Mode Enhancements.
    bool VME;
    /// Debugging Extensions.
    bool DE;
    /// Page Size Extension.
    bool PSE;
    /// Time Stamp Counter.
    bool TSC;
    /// Model Specific Registers RDMSR and WRMSR Instructions. 
    bool MSR;
    /// Physical Address Extension.
    bool PAE;
    /// Machine Check Exception.
    bool MCE;
    /// CMPXCHG8B Instruction.
    bool CX8;
    /// Indicates if the processor contains an Advanced Programmable Interrupt Controller.
    bool APIC;
    /// SYSENTER and SYSEXIT Instructions.
    bool SEP;
    /// Memory Type Range Registers.
    bool MTRR;
    /// Page Global Bit.
    bool PGE;
    /// Machine Check Architecture.
    bool MCA;
    /// Conditional Move Instructions.
    bool CMOV;
    /// Page Attribute Table.
    bool PAT;
    /// 36-Bit Page Size Extension.
    bool PSE_36;
    /// Processor Serial Number. 
    bool PSN;
    /// CLFLUSH Instruction.
    bool CLFSH;
    /// Debug Store.
    bool DS;
    /// Thermal Monitor and Software Controlled Clock Facilities.
    bool APCI;
    /// FXSAVE and FXRSTOR Instructions.
    bool FXSR;
    /// Self Snoop.
    bool SS;
    /// Hyper-threading technology.
    bool HTT;
    /// Thermal Monitor.
    bool TM;
    /// Pending Break Enable.
    bool PBE; // 31

    // ---- 06h - Thermal and Power Management Leaf ----
    /// Turbo Boost Technology (Intel)
    bool TurboBoost;


    // ---- 07h - Thermal and Power Management Leaf ----
    // -- EBX --
    /*
     * Note: BMI1, BMI2, and SMEP were introduced in 4th Generation Core processors.
     */
    /// Bit manipulation group 1 instruction support.
    bool BMI1; // 3
    /// Supervisor Mode Execution Protection.
    bool SMEP; // 7
    /// Bit manipulation group 2 instruction support.
    bool BMI2; // 8

    // ---- 8000_0007 -  ----
    /// TSC Invariation support
    bool TscInvariant; // 8
} // Class CpuInfo
} // version else

/// Get the maximum leaf. 
extern (C) export int getHighestLeaf() pure @nogc nothrow
{
    asm pure @nogc nothrow {
        naked;
        mov EAX, 0;
        cpuid;
        ret;
    }
}

/// Get the maximum extended leaf.
extern (C) export int getHighestExtendedLeaf() pure @nogc nothrow
{
    asm pure @nogc nothrow {
        naked;
        mov EAX, 0x8000_0000;
        cpuid;
        ret;
    }
}

extern (C) export uint getnlc()
{
    uint cpubits, count, corebits;
    asm {
        naked;
        mov EAX, 1;
        cpuid;
        test EDX, 0x1000_0000; // Check if HTT
        jno HTT;               // If HTT bit is set
        mov EAX, 1;
        ret;
    HTT:
        shr EBX, 16;
        and EBX, 0xF;
        mov count, EBX;
    }

    uint ml = getHighestLeaf,
         eml = getHighestExtendedLeaf;

    switch (getVendor)
    {
        case VENDOR_INTEL:
        if (ml >= 0xB) asm {
            naked;
            mov EAX, 0xB;
            mov ECX, 0;
            cpuid;
            mov [cpubits], EAX; // EAX or EBX?!
            mov EAX, 0xB;
            mov ECX, 1;
            cpuid;
            mov corebits, EAX; // Same as above
        } else if (ml >= 4) {

        } else {

        }
        break;

        case VENDOR_AMD:
        
        break;

        default: return 1;
    }

    return count;
}


/*void tgetFrequency()
{
    
}*/

/// Gets the CPU Vendor string.
string getVendor() pure nothrow
{
    char[12] s;
    char[12]* p = &s;
    asm pure @nogc nothrow {
        mov EDI, p;
        mov EAX, 0;
        cpuid;
        mov [EDI], EBX;
        mov [EDI+4], EDX;
        mov [EDI+8], ECX;
    }
    return s.idup;
}

/// Get the Processor Brand string
string getProcessorBrandString() pure nothrow 
{
    char[48] s;
    char[48]* ps = &s;
    asm pure @nogc nothrow {
        mov EDI, ps;
        mov EAX, 0x8000_0002;
        cpuid;
        mov [EDI], EAX;
        mov [EDI+4], EBX;
        mov [EDI+8], ECX;
        mov [EDI+12], EDX;
        mov EAX, 0x8000_0003;
        cpuid;
        mov [EDI+16], EAX;
        mov [EDI+20], EBX;
        mov [EDI+24], ECX;
        mov [EDI+28], EDX;
        mov EAX, 0x8000_0004;
        cpuid;
        mov [EDI+32], EAX;
        mov [EDI+36], EBX;
        mov [EDI+40], ECX;
        mov [EDI+44], EDX;
    }
    return s.idup;
}