# possible values:
# CYGWIN (also use for MINGW64)
# LINUX (also use for a pure WSL environment)
# WSL (calls Xilinx tools in WSL since ISE is terminally broken on Windows 11)
HOST = WSL

# specify to run Xilinx tools in WSL environment
# (ISE is terminally broken on Windows 11)
XILINX_WSL = y

# set paths to Xilinx/Intel tools
# adjust these for your environment
# XILINX_HOME = D:/Xilinx/14.7/ISE_DS
# XILINX_BIN = $(XILINX_HOME)/ISE/bin/nt64
# XILINX_PATHS  = ISE/bin/nt64 ISE/lib/nt64
# XILINX_PATHS += PlanAhead/bin
# XILINX_PATHS += EDK/bin/lib64 EDK/lib/nt64
INTEL_BIN = D:/intelFPGA_lite/21.1/quartus/bin64

# HOST = LINUX / WSL
XILINX_HOME = /opt/Xilinx/14.7/ISE_DS
XILINX_BIN = $(XILINX_HOME)/ISE/bin/lin64
XILINX_PATHS = ISE/bin/lin64 ISE/lib/lin64 PlanAhead/bin EDK/bin/lin64 EDK/lib/lin64
# INTEL_BIN = /opt/intelFPGA_lite/20.1/quartus/linux64

# specify number of concurrent SmartXPlorer runs
XPLORER_CPUS = 8
XPLORER_PARAMS  = -sf currentProps.stratfile -host_list hostlistfile.txt
XPLORER_PARAMS += -max_runs 99 -best_n_runs 1
