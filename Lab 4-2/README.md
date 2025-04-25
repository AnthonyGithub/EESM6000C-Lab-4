# EESM6000C Lab 4-2
Student ID: 20726557

## Lab 4-2 
* Integrate Lab3-FIR & exmem-FIR (Lab4-1) into Caravel user project area (add WB interface)
* Execute RISC-V firmware (FIR) from user project memory
* Firmware to move data in/out FIR
* Challenged to optimize the performance by software/hardware co-design

## Folder Structure
```sh
| -- docs/             # HackMD Report
| -- src/              # Source files
| | -- rtl/.v          # Design sources, user_project design, including Exmem, FIR RTL
| | -- testbench/_tb.v # Firmware code, Testbench
| -- data/             # Simulation waveform data
| -- tests/            # Synthesis area report, timing report, and log files generated
```

## Build Setup
```sh
cd ~/caravel-soc_fpga-lab/lab-caravel_fir/testbench/counter_la_fir
source run_clean
source run_sim
```

## HackMD Report
https://hackmd.io/@JokerAnthonio/B1Zi9ADJee

## Reference
https://github.com/bol-edu/caravel-soc_fpga-lab/tree/main/lab-caravel_fir
