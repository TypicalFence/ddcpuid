import std.stdio : write, writef, writeln, writefln;
import std.string : strip;

/// Version
const string ver = "0.2.1";

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
    bool _dbg = false; // Debug
    bool _det = false; // Detailed output
    bool _oml = false; // Override max leaf

    foreach (s; args)
    {
        switch (s)
        {
        case "/?":
        case "-h":
        case "--help":
            writeln(" ddcpuid [<Options>]");
            writeln();
            writeln(" --details, -D    Gets more details.");
            writeln(" --override, -O   Overrides leafs to 0x20 and 0x8000_0020");
            writeln(" --debug          Gets debugging information.");
            writeln();
            writeln(" --help      Prints help and quit.");
            writeln(" --version   Prints version and quit.");
            return;
 
        case "-v":
        case "--version":
            writeln("ddcpuid ", ver);
            writeln("Copyright (c) guitarxhero 2016");
            writeln("License: MIT License <http://opensource.org/licenses/MIT>");
            writeln("Project page: <https://github.com/guitarxhero/ddcpuid>");
            writefln("Compiled %s at %s, using %s version %s.",
                __FILE__, __TIMESTAMP__, __VENDOR__, __VERSION__);
            return;

        case "-D":
        case "--details":
            _det = true;
            break;

        case "-O":
        case "--override":
            _oml = true;
            break;

        case "--debug":
            _dbg = true;
            break;

        default:
        }
    }

    // Maximum leaf
    int max = _oml ? 0x20 : getHighestLeaf();
    // Maximum extended leaf
    int emax = _oml ? 0x8000_0020 : getHighestExtendedLeaf();

    if (_dbg)
    {
        writeln("|   Leaf   | Sub-leaf | EAX      | EBX      | ECX      | EDX      |");
        writeln("|----------|----------|----------|----------|----------|----------| ");
        uint _eax, _ebx, _ecx, _edx, _ebp, _esp, _edi, _esi;
        for (int leaf = 0; leaf <= max; ++leaf)
        {
            asm
            {
                mov EAX, leaf;
                cpuid;
                mov _eax, EAX;
                mov _ebx, EBX;
                mov _ecx, ECX;
                mov _edx, EDX;
            }
            writefln("| %8X |        0 | %8X | %8X | %8X | %8X |",
                leaf, _eax, _ebx, _ecx, _edx);
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
            writefln("| %8X |        0 | %8X | %8X | %8X | %8X |",
                eleaf, _eax, _ebx, _ecx, _edx);
        }
        asm
        {
            mov _ebp, EBP;
            mov _esp, ESP;
            mov _edi, EDI;
            mov _esi, ESI;
        }
        writefln("EBP=%-8X ESP=%-8X EDI=%-8X ESI=%-8X", _ebp, _esp, _edi, _esi);
        writeln();
    }
    else
    {
        const CPU_INFO cpuinfo = new CPU_INFO();
        with (cpuinfo)
        {
            writeln("Vendor: ", Vendor);
            writeln("Model: ", ProcessorBrandString);
            writefln("Identification: Family %X [%X:%X] Model %X [%X:%X] Stepping %X",
                Family, BaseFamily, ExtendedFamily,
                Model, BaseModel, ExtendedModel,
                Stepping);

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
                    case "GenuineIntel": write("Intel64, "); break;
                    case "AuthenticAMD": write("AMD64, ");   break;
                    default:
                }
            if (Virtualization)
                switch (Vendor)
                {
                    case "GenuineIntel": write("VT-x, ");  break; // VMX
                    case "AuthenticAMD": write("AMD-V, "); break; // SVM
                    default:
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

            writeln();
            writeln("Hyper-Threading Technology: ", HTT);
            writeln("Turbo Boost Available: ", TurboBoost);
            writeln("Enhanced Intel SpeedStep technology: ", EIST);
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
                    write("MOVBE, "); // Intel Atom only!, and quite a few AMDs.
                if (RDRAND)
                    write("RDRAND, ");
                if (MSR)
                    write("RDMSR/WRMSR, ");
                if (SEP)
                    write("SYSENTER/SYSEXIT, ");
                if (TSC)
                {
                    write("RDTSC");
                    if (TSC_Deadline || TscInvariant)
                    {
                        write(" (");
                        if (TSC_Deadline)
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

                writeln();
                writeln(" Floating Point");
                writeln(" ================");
                writeln();

                writeln();
                writeln(" Details");
                writeln(" ================");
                writeln();
                writefln("Highest Leaf: %02XH | Extended: %02XH", max, emax);
                write("Processor type: ");
                final switch (ProcessorType) // 2 bit value
                { // Only Intel uses this, AMD will always return 0.
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
                // MaximumNumberOfAddressableIDs / 2 (if HTT) for # cores?
                writeln("Logical processor count*: ", MaxIDs);
                writeln("Floating Point Unit [FPU]: ", FPU);
                writefln("APIC: %s (Initial ID: %s)", APIC, InitialAPICID);
                writeln("x2APIC: ", x2APIC);
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
public class CPU_INFO
{
    /// Initiates a CPU_INFO.
    this(bool fetch = true)
    {
        if (fetch)
            fetchInfo();
    }

    /// Fetches the information 
    public void fetchInfo()
    {
        Vendor = getVendor();
        ProcessorBrandString = strip(getProcessorBrandString());

        MaximumLeaf = getHighestLeaf();
        MaximumExtendedLeaf = getHighestExtendedLeaf();

        int a, b, c, d;
        for (int leaf = 1; leaf <= MaximumLeaf; ++leaf)
        {
            asm
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
                                Family = BaseFamily;
                            else
                                Family = cast(ubyte)(ExtendedFamily + BaseFamily);

                            if (BaseFamily < 0xF)
                                Model = BaseModel;
                            else
                                Model = cast(ubyte)((ExtendedModel << 4) + BaseModel);
                            break;

                            default:
                    }
                    ProcessorType = (a >> 12) & 3; // EAX[13:12]
                    Stepping = a & 0xF; // EAX[3:0]
                    // EBX
                    BrandIndex = b & 0xFF; // EBX[7:0]
                    CLFLUSHLineSize = b >> 8 & 0xFF; // EBX[15:8]
                    MaxIDs = b >> 16 & 0xFF; // EBX[23:16]
                    InitialAPICID = b >> 24 & 0xFF; // EBX[31:24]
                    // ECX
                    SSE3         = c & 1;
                    PCLMULQDQ    = c >>  1 & 1;
                    MONITOR      = c >>  3 & 1;
                    TM2          = c >>  8 & 1;
                    SSSE3        = c >>  9 & 1;
                    FMA          = c >> 12 & 1;
                    CMPXCHG16B   = c >> 13 & 1;
                    SSE41        = c >> 19 & 1;
                    SSE42        = c >> 20 & 1;
                    x2APIC       = c >> 21 & 1;
                    MOVBE        = c >> 22 & 1;
                    POPCNT       = c >> 23 & 1;
                    TSC_Deadline = c >> 24 & 1;
                    AESNI        = c >> 25 & 1;
                    XSAVE        = c >> 26 & 1;
                    OSXSAVE      = c >> 27 & 1;
                    AVX          = c >> 28 & 1;
                    F16C         = c >> 29 & 1;
                    RDRAND       = c >> 30 & 1;
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
                    HTT    = (d >> 28 & 1) && (MaxIDs > 1);
                    break;

                case 2: // 02h -- Cache and TLB Information. | AMD: Reserved

                    break;

                case 6: // 06h -- Thermal and Power Management Leaf | AMD: Reversed
                    switch (Vendor)
                    {
                        case "GenuineIntel":
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
            asm
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
                        case "AuthenticAMD":
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
                        case "AuthenticAMD":
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
    public string Vendor;
    /// Processor brand string.
    public string ProcessorBrandString;

    /// Maximum leaf supported by this processor.
    public int MaximumLeaf;
    /// Maximum extended leaf supported by this processor.
    public int MaximumExtendedLeaf;

    /// Also known as Intel64 or AMD64.
    public bool LongMode;

    /// Number of physical cores.
    public ushort NumberOfCores;
    /// Number of logical cores.
    public ushort NumberOfThreads;

    /// Processor family. ID and extended ID included.
    public ushort Family;
    /// Base Family ID
    public ubyte BaseFamily;
    /// Extended Family ID
    public ubyte ExtendedFamily;
    /// Processor model. ID and extended ID included.
    public ubyte Model;
    /// Base Model ID
    public ubyte BaseModel;
    /// Extended Model ID
    public ubyte ExtendedModel;
    /// Processor stepping.
    public ubyte Stepping;
    /// Processor type.
    public ubyte ProcessorType;

    /// MMX Technology.
    public bool MMX;
    /// Streaming SIMD Extensions.
    public bool SSE;
    /// Streaming SIMD Extensions 2.
    public bool SSE2;
    /// Streaming SIMD Extensions 3.
    public bool SSE3;
    /// Supplemental Streaming SIMD Extensions 3 (SSSE3).
    public bool SSSE3;
    /// Streaming SIMD Extensions 4.1.
    public bool SSE41;
    /// Streaming SIMD Extensions 4.2.
    public bool SSE42;
    /// Streaming SIMD Extensions 4a. AMD-only.
    public bool SSE4a;
    /// AESNI instruction extensions.
    public bool AESNI;
    /// AVX instruction extensions.
    public bool AVX;
    /// AVX2 instruction extensions.
    public bool AVX2;

    //TODO: Single instructions

    // ---- 01h : Basic CPUID Information ----
    // -- EBX --
    /// Brand index. See Table 3-24. If 0, use normal BrandString.
    public ubyte BrandIndex;
    /// The CLFLUSH line size. Multiply by 8 to get its size in bytes.
    public ubyte CLFLUSHLineSize;
    /// Maximum number of addressable IDs for logical processors in this physical package.
    public ubyte MaxIDs;
    /// Initial APIC ID for this processor.
    public ubyte InitialAPICID;
    // -- ECX --
    /// PCLMULQDQ instruction.
    public bool PCLMULQDQ; // 1
    /// 64-bit DS Area (64-bit layout).
    public bool DTES64;
    /// MONITOR/MWAIT.
    public bool MONITOR;
    /// CPL Qualified Debug Store.
    public bool DS_CPL;
    /// Virtualization | Virtual Machine Extensions (Intel) | Secure Virtual Machine (AMD) 
    public bool Virtualization;
    /// Safer Mode Extensions.
    public bool SMX;
    /// Enhanced Intel SpeedStep® technology.
    public bool EIST;
    /// Thermal Monitor 2.
    public bool TM2;
    /// L1 Context ID. If true, the L1 data cache mode can be set to either adaptive or shared mode. 
    public bool CNXT_ID;
    /// Indicates the processor supports IA32_DEBUG_INTERFACE MSR for silicon debug.
    public bool SDBG;
    /// FMA extensions using YMM state.
    public bool FMA;
    /// CMPXCHG16B instruction.
    public bool CMPXCHG16B;
    /// xTPR Update Control.
    public bool xTPR;
    /// Perfmon and Debug Capability.
    public bool PDCM;
    /// Process-context identifiers.
    public bool PCID;
    /// Direct Cache Access.
    public bool DCA;
    /// x2APIC feature (Intel programmable interrupt controller).
    public bool x2APIC;
    /// MOVBE instruction.
    public bool MOVBE;
    /// POPCNT instruction.
    public bool POPCNT;
    /// Indicates if the APIC timer supports one-shot operation using a TSC deadline value.
    public bool TSC_Deadline;
    /// Indicates the support of the XSAVE/XRSTOR extended states feature, XSETBV/XGETBV instructions, and XCR0.
    public bool XSAVE;
    /// Indicates if the OS has set CR4.OSXSAVE[18] to enable XSETBV/XGETBV instructions for XCR0 and XSAVE.
    public bool OSXSAVE;
    /// 16-bit floating-point conversion instructions.
    public bool F16C;
    /// RDRAND instruction.
    public bool RDRAND; // 30
    // -- EDX --
    /// Floating Point Unit On-Chip. The processor contains an x87 FPU.
    public bool FPU; // 0
    /// Virtual 8086 Mode Enhancements.
    public bool VME;
    /// Debugging Extensions.
    public bool DE;
    /// Page Size Extension.
    public bool PSE;
    /// Time Stamp Counter.
    public bool TSC;
    /// Model Specific Registers RDMSR and WRMSR Instructions. 
    public bool MSR;
    /// Physical Address Extension.
    public bool PAE;
    /// Machine Check Exception.
    public bool MCE;
    /// CMPXCHG8B Instruction.
    public bool CX8;
    /// Indicates if the processor contains an Advanced Programmable Interrupt Controller.
    public bool APIC;
    /// SYSENTER and SYSEXIT Instructions.
    public bool SEP;
    /// Memory Type Range Registers.
    public bool MTRR;
    /// Page Global Bit.
    public bool PGE;
    /// Machine Check Architecture.
    public bool MCA;
    /// Conditional Move Instructions.
    public bool CMOV;
    /// Page Attribute Table.
    public bool PAT;
    /// 36-Bit Page Size Extension.
    public bool PSE_36;
    /// Processor Serial Number. 
    public bool PSN;
    /// CLFLUSH Instruction.
    public bool CLFSH;
    /// Debug Store.
    public bool DS;
    /// Thermal Monitor and Software Controlled Clock Facilities.
    public bool APCI;
    /// FXSAVE and FXRSTOR Instructions.
    public bool FXSR;
    /// Self Snoop.
    public bool SS;
    /// Hyper-threading technology.
    public bool HTT;
    /// Thermal Monitor.
    public bool TM;
    /// Pending Break Enable.
    public bool PBE; // 31

    // ---- 06h - Thermal and Power Management Leaf ----
    /// Turbo Boost Technology (Intel)
    public bool TurboBoost;


    // ---- 07h - Thermal and Power Management Leaf ----
    // -- EBX --
    /*
     * Note: BMI1, BMI2, and SMEP were introduced in 4th Generation Core-ix processors.
     */
    /// Bit manipulation group 1 instruction support.
    public bool BMI1; // 3
    /// Supervisor Mode Execution Protection.
    public bool SMEP; // 7
    /// Bit manipulation group 2 instruction support.
    public bool BMI2; // 8

    // ---- 8000_0007 -  ----
    /// TSC Invariation support
    public bool TscInvariant; // 8
}
} // version else

/// <summary>
/// Gets the highest leaf possible for this processor.
/// </summay>
extern (C) export int getHighestLeaf()
{
    asm
    {
        naked;
        mov EAX, 0;
        cpuid;
        ret;
    }
}

/// <summary>
/// Get the Processor Brand string
/// </summary>
extern (C) export int getHighestExtendedLeaf()
{
    asm
    {
        naked;
        mov EAX, 0x8000_0000;
        cpuid;
        ret;
    }
}

/// <summary>
/// Gets the CPU Vendor string.
/// </summay>
string getVendor()
{
    string s;
    int ebx, edx, ecx;
    char* p = cast(char*)&ebx; // char.sizeof == 1
    asm
    {
        mov EAX, 0;
        cpuid;
        mov ebx, EBX;
        mov ecx, ECX;
        mov edx, EDX;
    }
    for (int a = 0; a < int.sizeof * 3; ++a)
        s ~= *(p + a);
    return s;
}

/// <summary>
/// Get the Processor Brand string
/// </summary>
string getProcessorBrandString()
{
    string s;
    int eax, ebx, ecx, edx;
    char* p = cast(char*)&eax;
    for (int i = 0x80000002; i <= 0x80000004; ++i)
    {
        asm
        {
            mov EAX, i;
            cpuid;
            mov eax, EAX;
            mov ebx, EBX;
            mov ecx, ECX;
            mov edx, EDX;
        }
        for (int a = 0; a < int.sizeof * 4; ++a)
            s ~= *(p + a);
    }
    return s;
}