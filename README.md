# Assembly Text Utilities (x86, MASM)

## Overview
This utility demonstrates low-level string manipulation in **x86 Assembly (MASM)**.  
It showcases how MASM string primitive instructions and macros can be used to process text efficiently, while maintaining structure through modular procedures.

## Features
- Accepts user input and processes it as a string.  
- Converts lowercase letters to uppercase using string primitives.  
- Reverses strings and checks for palindromes.  
- Demonstrates the use of **macros** for common tasks like formatted output and validation.  

## Technical Highlights
- Implemented in **MASM x86 Assembly** using the Irvine32 library.  
- Uses **string primitives** (`MOVS`, `STOS`, `SCAS`, etc.) for efficient character-level operations.  
- Structured with **procedures and macros** for modular design and reduced redundancy.  
- Includes inline documentation for readability and maintainability.  

## What I Learned
- How to manipulate raw string data directly in memory at the assembly level.  
- How MASM string primitives can accelerate operations compared to manual loops.  
- How macros can simplify repetitive code and improve readability in assembly development.  

## How to Run
1. Open the program in Visual Studio with the Irvine32 library configured.  
2. Assemble and run.  
3. Input strings when prompted to see transformations applied.  
