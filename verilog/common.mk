HOST = LINUX
XILINX_HOME = /opt/Xilinx/14.7/ISE_DS
XILINX_BIN = $(XILINX_HOME)/ISE/bin/lin64
XILINX_PATHS = ISE/bin/lin64 ISE/lib/lin64 PlanAhead/bin EDK/bin/lib64 EDK/lib/lin64

INTEL_BIN = /opt/intelFPGA_lite/18.1/quartus/linux64

XPLORER_PARAMS=-sf currentProps.stratfile -host_list hostlistfile.txt -max_runs 99 -best_n_runs 1
#XPLORER_PARAMS=-max_runs 5 -best_n_runs 1
