# Verilog Lab 1: Digital Design Implementation

## Overview

This project implements four fundamental digital circuit designs in Verilog as part of a Computer Architecture laboratory course. Each experiment progresses in complexity from basic arithmetic circuits to a complete single-cycle MIPS processor.

## Experiments

### 1. RCA32 - 32-bit Ripple Carry Adder

**Location:** `RCA32/`

**Description:**
A 32-bit adder built from cascaded 1-bit full adders demonstrating ripple carry architecture.

**Key Features:**

- Parametric full adder modules (`fa_1bit`)
- Generate loop for scalable design
- Subtraction mode using 2's complement
- Overflow detection for signed arithmetic
- Comprehensive edge case testing

**Modules:**

- `fa_1bit`: Single-bit full adder
- `rca_32bit`: 32-bit ripple carry adder with subtraction support
- `tb_rca_32bit`: Test bench with edge cases

**Test Cases:** 20+ including overflow, carry propagation, and subtraction modes

---

### 2. ALU - 16-bit Arithmetic Logic Unit

**Location:** `ALU/`

**Description:**
A versatile 16-bit ALU supporting arithmetic, logical, shift, and comparison operations.

**Key Features:**

- 16 operations organized in groups (arithmetic, logical, shift, comparison)
- Parity flag computation
- Parameterized width for scalability
- Comprehensive status flags (zero, carry, overflow, negative, parity)
- No begin/end for single-statement cases

**Operations:**

- Arithmetic: ADD, SUB, INC, DEC
- Logical: AND, OR, XOR, NOT, NAND, NOR
- Shift: SLL, SRL, SRA
- Comparison: EQ, SLT (signed), SLTU (unsigned)

**Test Cases:** 40+ covering all operations and edge cases

---

### 3. CPU - 32-bit Simple Processor

**Location:** `CPU/`

**Description:**
A basic 32-bit processor with custom instruction encoding demonstrating datapath and control unit design.

**Architecture:**

- 8 × 32-bit register file with register 0 always zero
- 32-bit ALU
- Control unit with 16 opcodes
- Program counter with branch/jump logic
- Memory interface

**Instruction Format:**

```
[31:27] = Opcode (5 bits)
[26:22] = Destination Register
[21:17] = Source Register 1
[16:12] = Source Register 2
[20:0]  = Immediate Value (21 bits)
```

**Instructions Supported:**

- R-type: ADD, SUB, AND, OR, XOR
- I-type: ADDI, ANDI, ORI, LW, SW
- Control: BEQ, JMP, HALT

**Features:**

- Different register initialization (each register initialized with its index)
- Debug/monitor signals in testbench
- Memory read/write support

---

### 4. SINGLE_CYCLE_MIPS - MIPS Single-Cycle Processor

**Location:** `SINGLE_CYCLE_MIPS/`

**Description:**
A complete single-cycle MIPS processor implementation following standard MIPS ISA architecture.

**Architecture:**

- 32 × 32-bit register file
- 32-bit ALU with multiple operations
- Control unit and ALU decoder
- Instruction/data memory interface
- Branch and jump support

**MIPS Instructions Supported:**

- R-type: ADD, SUB, AND, OR, SLT
- I-type: ADDI, ANDI, ORI, LW, SW
- Conditional: BEQ
- Unconditional: J

**Features:**

- Parametric register file (32 registers by default)
- Parametric ALU width
- Sign-extended immediates
- Jump address formation
- Branch target calculation

**Test Program:**
Fibonacci-like sequence with arithmetic, logical, memory, and control flow instructions

---

## Design Principles

### HDL Standards

- Proper port declarations with ANSI-style grouping
- Clear signal naming conventions
- Separation of combinational and sequential logic
- No implicit nets or latch inference
- Non-blocking assignments in sequential blocks
- Blocking assignments in combinational logic

### Code Organization

- Minimalist, human-readable comments
- Meaningful port names
- Logical module hierarchy
- Generate loops for scalable designs
- Conditional statements without unnecessary begin/end

### Testing Methodology

- Automated test case execution
- Pass/fail tracking
- Edge case coverage
- Expected value comparison
- Debug output for failing tests
- VCD waveform generation for analysis

---

## File Structure

```
RCA32/
├── rca_32bit.v           # 32-bit ripple carry adder
├── tb_rca_32bit.v        # Test bench
└── rca_32bit.vcd         # Waveform dump

ALU/
├── alu_16bit.v           # 16-bit ALU
├── tb_alu_16bit.v        # Test bench
└── alu_16bit.vcd         # Waveform dump

CPU/
├── cpu_32bit.v           # 32-bit processor
├── tb_cpu_32bit.v        # Test bench
└── cpu_32bit.vcd         # Waveform dump

SINGLE_CYCLE_MIPS/
├── mips_scp.v            # MIPS single-cycle processor
├── tb_mips_scp.v         # Test bench
└── mips_scp.vcd          # Waveform dump

docs/
├── README.md             # This file
├── design_notes.txt      # Design decisions and notes
└── test_results.txt      # Test execution results
```

---

## Simulation and Verification

Each design includes comprehensive testbenches with:

### RCA32 Testbench

- Basic addition tests
- Unsigned overflow
- Signed overflow detection
- Carry propagation verification
- Subtraction mode testing
- Edge cases (max values, zero)

### ALU Testbench

- Arithmetic operations (all 4 operations)
- Logical operations (all 6 operations)
- Shift operations (logical and arithmetic)
- Comparison operations (signed and unsigned)
- Flag generation verification
- Edge cases and boundary conditions

### CPU Testbench

- R-type instruction execution
- I-type instruction execution
- Memory read/write operations
- Register writeback verification
- Program flow with multiple instructions
- Register file state inspection

### MIPS Testbench

- Complete MIPS program execution
- All instruction types (R, I, J)
- Arithmetic and logical operations
- Memory access (load/store)
- Branch prediction and jump execution
- Register and memory state verification

---

## Design Improvements

### Parametrization

- RCA32: Implicitly supports any width via generate loops
- ALU: `WIDTH` parameter for flexible bit width
- MIPS regfile: `REGS` parameter for variable register count

### Additional Features

- RCA32: Subtraction mode using 2's complement
- ALU: Parity flag for error detection
- CPU: Different instruction encoding scheme
- MIPS: Monitor signals for debug output

### Code Quality

- No begin/end for single statements where valid
- Consistent ANSI-style port declarations
- Minimalist but clear documentation
- Meaningful variable names throughout

---

## Performance Characteristics

### Critical Paths

- **RCA32:** O(n) for 32-bit addition due to ripple carry
- **ALU:** Combinational logic, single cycle operation
- **CPU:** Single cycle fetch-decode-execute-writeback
- **MIPS:** Single cycle per instruction (by design)

### Latency

- **RCA32:** ~32 gate delays for worst-case carry propagation
- **ALU:** Combinational output
- **CPU:** 1 clock cycle per instruction
- **MIPS:** 1 clock cycle per instruction

---

## Future Enhancements

1. **RCA32:** Implement carry lookahead for improved performance
2. **ALU:** Add multiply/divide operations
3. **CPU:** Implement full ISA with more instructions
4. **MIPS:** Add pipeline stages for multi-cycle operation
5. All designs: Add synthesis and place & route

---

## References

- Patterson & Hennessy, "Computer Architecture" (MIPS ISA definition)
- Harris & Harris, "Digital Design and Computer Architecture"
- Verilog-2001 Standard (IEEE 1364-2001)
- COAVL Online Virtual Labs (experiment theory)

---
**Created By:** Kelvin Byabato, UDSM.  
**Created:** 30th January, 2026  
**Laboratory:** Computer Architecture and Digital Design  
**Language:** Verilog  
**Tools:** Icarus Verilog (iverilog), GTKWave, Yosys, Logism. 
