# esp-caches

## Overview
This repository contains the SystemVerilog implementation of the cache hierarchy for [ESP](http://github.com/sld-columbia/esp), as well as SystemC wrappers for the caches that allow co-simulation with the existing SystemC testbenches in ESP.

### Usage

- **ESP** : To use the ESP SystemVerilog caches, clone the [ESP repository](http://github.com/sld-columbia/esp) follow the [ESP singlecore tutorial](https://esp.cs.columbia.edu/docs/singlecore/). Namely see the section *ESP Cache Hierarchy*. From the ESP GUI, you should check the `Use Caches` box and select  `SystemVerilog` from the `Implementation` dropdown. 

- **Simulation** : The caches use the SystemC testbench located within ESP. After cloning ESP, navigate to the `L2` or `LLC` folders (ESPROOT/rtl/src/sld/caches/esp-caches/llc). First, modify the `cache_cfg.svh` to test the configuration you'd like to simulate (see the *Assumptions and Limitations*  section for the currently supported configuration). From this folder you can run `make llc-sim` to run a command line simulation or `make llc-sim-gui` to launch the GUI and view waveforms. The caches currently use Cadence's Incisive simulator.  

### Structure
```
project
|   README.md    
+---common
|   |
|   +---rtl
|   |       ...      
|   +---defs
|           ...
+---l2
|   |   Makefile
|   |   cache_cfg.svh
|   +---rtl
|   |       ...      
|   +---sim
|           ...
+---llc
    |   Makefile
    |   cache_cfg.svh
    +---rtl
    |       ...      
    +---sim
            ...
```
`common` contains code that is used in both the LLC and the L2: `rtl` contains common SystemVerilog modules and `defs` contain SystemVerilog header files with constants and datatypes defined. The `l2` and `llc` folders are structured the same. Each contains a `Makefile` with commands for running simulations of the caches, which can be configured in the `cache_cfg.svh` file. The subfolders `rtl` and `sim` contain SystemVerilog modules and SystemC wrappers for cosimulation, respectively.

## Features
The caches implement the protocol described in [this paper](https://sld.cs.columbia.edu/pubs/giri_nocs18.pdf). In addition to enabling multi-processor SoCs in ESP, the caches allow accelerators to use one of three coherence models: non-coherent (DMA to main memory), LLC-coherent (DMA to the LLC), and fully coherent with the processors (only if the accelerator is equipped with an L2 cache). Aditionally, the integration of the caches in ESP allow for runtime selection of a coherence model. 

## LLC

### Functional Description
In addition to serving as the last level of on-device memory, the LLC also contains the directory controller. The LLC operates in a 6-phase loop, consisting of the following phases: `DECODE`, `ADDRESS`, `MEMORY`, `LOOKUP`, `PROCESS`, and `UPDATE`. These phases are described in more detail in the list of files below. 

### Files
`llc_rtl_top.sv` : Top-level verilog module, containing only the interface to the LLC wrapper. Takes incoming signals for each group and packs them into a SystemVerilog interface and unpacks outgoing interfaces into their respective signals.

`llc_core.sv` : Instantiates and connects all lower-level  LLC modules. 

`llc_input_decoder.sv` : Handles the `DECODE` and `ADDRESS` phases of LLC execution. In `DECODE`, looks at all incoming channels to determine what action to take. In `ADDRESS`, selects the appropriate address to forward to the local memory and read a whole set. 

`llc_localmem.sv` : Local memory that stores all of the data in the LLC as well as the information kept in the directory. All data is read in the `MEMORY` phase.  Uses dual-ported BRAMs, with one port per way to ensure that an entire set can be read in one cycle. If an entire way cannot fit in a single BRAM, BRAMs are replicated "horizontally" and the most significant address bits are used to multiplex from the correct BRAM. If the data is too wide to fit in a BRAM, BRAMs are replicated "vertically" and concatenated to form the full data (i.e. 128 bit lines in 32 bit BRAMs). The fields that are stored are as follows: 

- *line* : One cache line of data. 128 bits. Each line is spread over 8 8-bit wide BRAMs.

- *state* : The state of each cache line. 3 bits. Stored in 4-bit wide BRAMs. 

- *tag*: The tag bits for each cached address. 16-21 bits depending on number of sets. Stored in 3 8-bit wide BRAMs.

- *dirty bit* : Indicates if the cache line has been modified and must be written back to memory. 1 bit. Stored in 1-bit BRAMs. 

- *hprot*  : Write protections - 0 for instructions, 1 for data. 1-bit. Stored in 1-bit BRAMs.  

- *owner* : The current owner of the cache line. 4-bits due to current limitation of 16 coherent devices. Stored in 4-bit wide BRAMs. 

- *sharers* : Tracks all sharers of the current cache line - 1 bit for each possible sharer. 16 bits. Stored in 16-bit wide BRAMs. 

- *evict way* : Keeps track of the next way for each set to start the eviction search from. 2-4 bits depending on number of ways -  LLC is capped at 16 ways. Stored in 4-bit wide BRAMs. 

`llc_lookup.sv` : Active in the `LOOKUP` state. Checks each set for a tag hit. If no hit, checks for an empty-way. If no empty way, performs an eviction. First evicts a line in the `VALID` state, if none picks the first line that is not awaiting data, otherwise evicts from the *evict way*.  FIFO-like. Uses priority encoders (`pri_enc.sv`) to find the first way  that meets above criteria. Priority encoders are split into 4 smaller encoders (`pri_enc_quarter.sv`) for better timing. 

`llc_process_request.sv` : Active in the `PROCESS` state.  State machine that handles the next request, response, or forward. Can last 1 cycle (tag-hit) to many (those requiring a memory request and repsonse). Moves out of its idle state in `LOOKUP` to avoid a wasted cycle. 

`llc_uppdate.sv` : Active in the `UPDATE` state. Writes buffers back to memory.  

`llc_bufs.sv` : Temporary storage buffers for all data of the current set. Read in `MEMORY` and written back in `UPDATE`.

`llc_regs.sv` : Global registers used throughout the design.

`llc_interfaces.sv` : manages the incoming and outgoing interfaces. The interface uses a valid-ready protocol with a 1-item queue for holding one request. The 1-item queue allows the cache to accept a request, even if the cache is not internally ready to process the signal, avoiding applying backpressure to the rest of the system. The cache then pulls from the queue when it is ready to process the request. A similar process happens for outgoing the request. The controller for this interface is a simple 2-state FSM located in `interface_controller.sv` inside `common/rtl`.

### Assumptions and Limitations
- Currently only handles 32-bit addresses. 
- Supports 4, 8, or 16 ways.
- Testbench currently works for 4, 8, and 16 ways.

## L2

### Functional Description
The L2 cache is the last level of local storage for CPUs and, optionally, for accelerators in ESP. Accelerators can be equipped with an L2 cache from the ESP GUI. The L2 is largely similar to the LLC, with a few exceptions. First, the L2 does not need to track directory information as the LLC does, and thus does not need to store as many fields. Next, the L2 contains a small buffer for outstanding requests and has many more transient states than the LLC. In contrast with the LLC, which updates the memory at every iteration of processing, the L2 only updates its memory once a request is retired into a stable state. Finally, the L2 handles atomic requests from the CPU, whereas the LLC has no concept of whether a CPU is completing an atomic transaction or not; in contrast, the LLC handles DMA transactions for LLC-coherent DMA, whereas the L2 is not involved in these transactions. The states for the L2 can be broadly classified as follows: `DECODE`, `REQS_LOOKUP`, `TAG_LOOKUP`, and `ACTION`. However, not all states are used for all of CPU requests, forwards, responses, and flushes. For instance, responses are guaranteed to be addressing an outstanding request, so there is no need to do tag lookup from the local memory. In contrast, flushes do not act on outstanding requests and do not perform a lookup of the tags in the outstanding requests buffer.

### Files
`l2_rtl_top.sv` : Top-level verilog module, containing only the interface to the L2 wrapper. Takes incoming signals for each group and packs them into a SystemVerilog interface and unpacks outgoing interfaces into their respective signals.

`l2_core.sv` : Instantiates and connects all lower-level  L2 modules. 

`l2_input_decoder.sv` : Handles the `DECODE` phase of execution. Looks at all incoming signals and determines the appropriate action to take.  

`l2_localmem.sv` : Local memory that stores all of the data in the L2 as well as necessary information about the state of the line. Uses dual-ported BRAMs, with one port per way to ensure that an entire set can be read in one cycle. If an entire way cannot fit in a single BRAM, BRAMs are replicated "horizontally" and the most significant address bits are used to multiplex from the correct BRAM. If the data is too wide to fit in a BRAM, BRAMs are replicated "vertically" and concatenated to form the full data (i.e. 128 bit lines in 32 bit BRAMs). Not every request requires an access to the localmemory (i.e responses are always resolved from the outstanding request buffer). The fields that are stored are as follows: 

- *line* : One cache line of data. 128 bits. Each line is spread over 8 32-bit wide BRAMs.

- *state* : The state of each cache line. 3 bits. Stored in 4-bit wide BRAMs. 

- *tag*: The tag bits for each cached address. 16-21 bits depending on number of sets. Stored in 3 8-bit wide BRAMs.

- *hprot*  : Write protections - 0 for instructions, 1 for data. 1-bit. Stored in 1-bit BRAMs.  

- *evict way* : Keeps track of the next way for each set to start the eviction search from. 1-3 bits depending on number of ways -  L2 is capped at 8 ways. Stored in 4-bit wide BRAMs. 

`l2_reqs.sv` : Buffers that store a small finite set (default is 4) of outstanding requests. Also includes the logic to perform a lookup in the buffer for each type of action. Stores several fields including the following: 

- *cpu_msg* : `READ`, `READ_ATOMIC`, `WRITE`, or `WRITE_ATOMIC`

- *tag*, *set*, *way* : corresponding to the address of the request.

- *size* : size of the request - byte, halfword, or word

- *word_offset*, *byte_offset* : position in the cacheline of the desired data

- *state* : one of 13 unstable states

- *invack_cnt* : number of invalidate acknowledgements pending

- *word* : word to be written to the cache line

- *line* : cache line

`l2_lookup.sv` : Used in the event of a miss in the outstanding request buffer. Checks a given set for a tag hit. If no hit, checks for an empty-way. If there is no empty-way, the L2 evicts from the *evict_way*. 

`l2_fsm.sv` : State machine that governs execution in the L2. Has separate branches for CPU requests, responses, forwards, and flushes. 

`l2_bufs.sv` : Temporary storage buffers for all data of the current set.

`l2_regs.sv` : Global registers used throughout the design.

`l2_write_word.sv` : writes the word from the request into a cache line. Uses big endian for Leon3 and little endian for Ariane. 

`l2_interfaces.sv` : manages the incoming and outgoing interfaces. The interface uses a valid-ready protocol with a 1-item queue for holding one request. The 1-item queue allows the cache to accept a request, even if the cache is not internally ready to process the signal, avoiding applying backpressure to the rest of the system. The cache then pulls from the queue when it is ready to process the request. A similar process happens for outgoing the request. The controller for this interface is a simple 2-state FSM located in `interface_controller.sv` inside `common/rtl`.  

### Assumptions and Limitations
- Currently only handles 32-bit addresses. 
- Supports 2, 4, or 8 ways. 
- Testbench works for 4 or 8 ways.

