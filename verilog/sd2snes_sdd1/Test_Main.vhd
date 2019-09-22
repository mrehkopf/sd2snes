----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 18.03.2018 22:42:12
-- Design Name:
-- Module Name: Test_FIFO_Input - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Test_Main is
--	Port ( );
end Test_Main;


architecture Behavioral of Test_Main is
	--constant SD2SNES_PERIOD						: time := 10.416 ns;
	constant SD2SNES_PERIOD						: time := 41.666 ns;
	constant CLK_PERIOD							: time := 46.56 ns;
	constant PHI2_PERIOD							: time := 6*CLK_PERIOD;
	constant tBAS									: time := 33 ns;
	constant tADS									: time := 30 ns;
	constant tMDS									: time := 30 ns;
	constant tLATCH								: time := 25 ns;
	constant tDECODER								: time := 25 ns;
	constant ROM_tACCESS							: time := 70 ns;


	COMPONENT main
		Port(	--input clock
				CLKIN									: in STD_LOGIC;
				-- SNES signals
				SNES_ADDR_IN						: in STD_LOGIC_VECTOR(23 downto 0);
				SNES_READ_IN						: in STD_LOGIC;
				SNES_WRITE_IN						: in STD_LOGIC;
				SNES_ROMSEL_IN						: in STD_LOGIC;
				SNES_DATA							: inout STD_LOGIC_VECTOR(7 downto 0);
				SNES_CPU_CLK_IN					: in STD_LOGIC;
				SNES_REFRESH						: in STD_LOGIC;
				SNES_IRQ								: out STD_LOGIC;
				SNES_DATABUS_OE					: out STD_LOGIC;
				SNES_DATABUS_DIR					: out STD_LOGIC;
				SNES_SYSCLK							: in STD_LOGIC;

				SNES_PA_IN							: in STD_LOGIC_VECTOR(7 downto 0);
				SNES_PARD_IN						: in STD_LOGIC;
				SNES_PAWR_IN						: in STD_LOGIC;

				-- SRAM signals
				-- Bus 1: PSRAM, 128Mbit, 16bit, 70ns
				ROM_DATA								: inout STD_LOGIC_VECTOR(15 downto 0);
				ROM_ADDR								: out STD_LOGIC_VECTOR(22 downto 0);
				ROM_CE								: out STD_LOGIC;
				ROM_OE								: out STD_LOGIC;
				ROM_WE								: out STD_LOGIC;
				ROM_BHE								: out STD_LOGIC;
				ROM_BLE								: out STD_LOGIC;

				-- Bus 2: SRAM, 4Mbit, 8bit, 45ns -> NOT USED; Backup RAM mapped to $E0:0000 in PSRAM
				RAM_DATA								: inout STD_LOGIC_VECTOR(7 downto 0);
				RAM_ADDR								: out STD_LOGIC_VECTOR(18 downto 0);
				RAM_CE								: out STD_LOGIC;
				RAM_OE								: out STD_LOGIC;
				RAM_WE								: out STD_LOGIC;

				-- MCU signals
				SPI_MOSI								: in STD_LOGIC;
				SPI_MISO								: inout STD_LOGIC;
				SPI_SS								: in STD_LOGIC;
				SPI_SCK								: inout STD_LOGIC;
				MCU_OVR								: in STD_LOGIC;
				MCU_RDY								: out STD_LOGIC;

				DAC_MCLK								: out STD_LOGIC;
				DAC_LRCK								: out STD_LOGIC;
				DAC_SDOUT							: out STD_LOGIC;

				-- SD signals
				SD_DAT								: in STD_LOGIC_VECTOR(3 downto 0);
				SD_CMD								: inout STD_LOGIC;
				SD_CLK								: inout STD_LOGIC;

				p113_out								: out STD_LOGIC);
	END COMPONENT;

	type bit_vector_file 						is file of bit_vector;
	type bytes_file 								is file of integer;
	file comp_data									: bit_vector_file;
	file descomp_data 							: bytes_file;
	shared variable Size							: integer := 0;

	--type ROM_Array_t								is array(2097151 downto 0) of STD_LOGIC_VECTOR(15 downto 0);
	type ROM_Array_t								is array(65535 downto 0) of STD_LOGIC_VECTOR(15 downto 0);
	signal MaskROM_0								: ROM_Array_t := (others => (others => '0'));
	--signal MaskROM_1								: ROM_Array_t := (others => (others => '0'));

	signal SD2SNES_CLK							: STD_LOGIC := '0';
	signal MCLK										: STD_LOGIC := '0';
	signal CPU_CLK									: STD_LOGIC := '0';
	signal RESET									: STD_LOGIC := '0';

	signal SRAM_CS									: STD_LOGIC := '1';
	signal SRAM_DATA								: STD_LOGIC_VECTOR(7 downto 0);
	signal SRAM_ADDR								: STD_LOGIC_VECTOR(18 downto 0);
	signal SRAM_OE									: STD_LOGIC;
	signal SRAM_WE									: STD_LOGIC;

	signal ROM_OE									: STD_LOGIC := '1';
	signal ROM_CS									: STD_LOGIC := '1';
	signal ROM_ADDR								: STD_LOGIC_VECTOR(22 downto 0) := (others => '0');
	signal ROM_DATA								: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
	signal ROM_WE									: STD_LOGIC;
	signal ROM_BHE									: STD_LOGIC;
	signal ROM_BLE									: STD_LOGIC;

	signal SNES_RD									: STD_LOGIC := '1';
	signal SNES_WR									: STD_LOGIC := '1';
	signal SNES_ADDR								: STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
	signal SNES_DATA								: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal SNES_IRQ								: STD_LOGIC;
	signal SNES_DATABUS_OE						: STD_LOGIC;
	signal SNES_DATABUS_DIR						: STD_LOGIC;
	signal SNES_ROMSEL							: STD_LOGIC;

	signal CPU_RD_CYCLE							: STD_LOGIC := '0';
	signal CPU_WR_CYCLE							: STD_LOGIC := '0';
	signal CPU_ADDR								: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
	signal CPU_BANK								: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal CPU_DATA								: STD_LOGIC_VECTOR(7 downto 0) := (others => 'Z');
	signal CPU_VDA									: STD_LOGIC := '0';
	signal CPU_VPA									: STD_LOGIC := '0';

	signal ROM_Data_tready						: STD_LOGIC := '0';
	signal ROM_Data_tvalid						: STD_LOGIC := '0';
	signal ROM_Data_tdata						: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

	signal DMA_Data_tvalid_Pipe				: STD_LOGIC_VECTOR(1 downto 0) := "00";
	signal DMA_Data_tvalid						: STD_LOGIC := '0';
	signal DMA_Data_dword						: STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

	signal Instruction_Addr						: STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
	signal Compressed_Addr						: STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
	signal Compressed_Size						: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
	signal Start_Decompression					: STD_LOGIC := '0';
	signal End_Decompression					: STD_LOGIC := '0';

begin

	uut : main
		Port map(CLKIN								=> SD2SNES_CLK,
					-- SNES signals
					SNES_ADDR_IN					=> SNES_ADDR,
					SNES_READ_IN					=> SNES_RD,
					SNES_WRITE_IN					=> SNES_WR,
					SNES_ROMSEL_IN					=> SNES_ROMSEL,
					SNES_DATA						=> SNES_DATA,
					SNES_CPU_CLK_IN				=> CPU_CLK,
					SNES_REFRESH					=> '0',
					SNES_IRQ							=> SNES_IRQ,
					SNES_DATABUS_OE				=> SNES_DATABUS_OE,
					SNES_DATABUS_DIR				=> SNES_DATABUS_DIR,
					SNES_SYSCLK						=> MCLK,

					SNES_PA_IN						=> X"00",
					SNES_PARD_IN					=> '1',
					SNES_PAWR_IN					=> '1',

					-- SRAM signals
					-- Bus 1: PSRAM, 128Mbit, 16bit, 70ns
					ROM_DATA							=> ROM_DATA,
					ROM_ADDR							=> ROM_ADDR,
					ROM_CE							=> ROM_CS,
					ROM_OE							=> ROM_OE,
					ROM_WE							=> ROM_WE,
					ROM_BHE							=> ROM_BHE,
					ROM_BLE							=> ROM_BLE,

					-- Bus 2: SRAM, 4Mbit, 8bit, 45ns -> NOT USED; Backup RAM mapped to $E0:0000 in PSRAM
					RAM_DATA							=> SRAM_DATA,
					RAM_ADDR							=> SRAM_ADDR,
					RAM_CE							=> SRAM_CS,
					RAM_OE							=> SRAM_OE,
					RAM_WE							=> SRAM_WE,

					-- MCU signals
					SPI_MOSI							=> '0',
					SPI_MISO							=> open,
					SPI_SS							=> '1',
					SPI_SCK							=> open,
					MCU_OVR							=> '0',
					MCU_RDY							=> open,

					DAC_MCLK							=> open,
					DAC_LRCK							=> open,
					DAC_SDOUT						=> open,

					-- SD signals
					SD_DAT							=> X"0",
					SD_CMD							=> open,
					SD_CLK							=> open,

					p113_out							=> open );



	Process(SNES_ADDR)
	Begin
		if( SNES_ADDR(23 downto 16) = X"7E" OR SNES_ADDR(23 downto 16) = X"7F" ) then
			SNES_ROMSEL								<= '1';
		elsif( SNES_ADDR >= X"000000" AND SNES_ADDR < X"400000" AND SNES_ADDR(15) = '0' ) then
			SNES_ROMSEL								<= '1';
		elsif( SNES_ADDR >= X"800000" AND SNES_ADDR < X"C00000" AND SNES_ADDR(15) = '0' ) then
			SNES_ROMSEL								<= '1';
		else
			SNES_ROMSEL								<= '0';
		end if;
	End Process;


	Process
		variable next_vector 					: bit_vector (0 downto 0);
		variable actual_len 						: natural;
	Begin
		--Size 											:= 4194304;
		--file_open(comp_data, "StarOcean.smc", READ_MODE);
		--Size 											:= 3072;
		--file_open(comp_data, "sdd1_chunk_0000.bin", READ_MODE);
		Size 											:= 4034;
		file_open(comp_data, "sdd1_chunk_1100.bin", READ_MODE);

		file_open(descomp_data, "StarOcean_main.smc", WRITE_MODE);

		-- read full ROM from file to memory
		for i in 0 to (Size/2)-1 loop
			-- read word from file
			if not endfile(comp_data) then
				read(comp_data, next_vector, actual_len);
				if actual_len > next_vector'length then
					report "vector too long";
				else
					MaskROM_0(i)(15 downto 8) 		<= conv_std_logic_vector(bit'pos(next_vector(0)),8);
				end if;

				read(comp_data, next_vector, actual_len);
				if actual_len > next_vector'length then
					report "vector too long";
				else
					MaskROM_0(i)(7 downto 0) 		<= conv_std_logic_vector(bit'pos(next_vector(0)),8);
				end if;
			end if;

			wait for 1ps;
		end loop;

--		for i in 0 to 1048575 loop
--			-- read word from file
--			if not endfile(comp_data) then
--				read(comp_data, next_vector, actual_len);
--				if actual_len > next_vector'length then
--					report "vector too long";
--				else
--					MaskROM_1(i)(7 downto 0) 		<= conv_std_logic_vector(bit'pos(next_vector(0)),8);
--				end if;

--				read(comp_data, next_vector, actual_len);
--				if actual_len > next_vector'length then
--					report "vector too long";
--				else
--					MaskROM_1(i)(15 downto 8) 		<= conv_std_logic_vector(bit'pos(next_vector(0)),8);
--				end if;
--			end if;

--			wait for 1 ps;
--		end loop;

		-- begin reset
		RESET											<= '0';
		wait for 1 us;
		RESET											<= '1';
		wait until falling_edge(MCLK);
		wait for	100 ns;
		wait until falling_edge(CPU_CLK);
		wait for (PHI2_PERIOD-CLK_PERIOD/2);


		-- decompress from $DBA078, size $0C00, code $C0238E
		Instruction_Addr							<= X"C0238E";
		--Compressed_Addr							<= X"DBA078";
		Compressed_Addr							<= X"C00000";
		Compressed_Size							<= conv_std_logic_Vector(16384, 16);
		Start_Decompression						<= '1';
		wait until (End_Decompression = '1');
		Start_Decompression						<= '0';

		--assert false report "NONE. End of simulation." severity failure;
		wait;
	End Process;



	-- process to generate instructions to SDD1 core from real ROM
	Process
		variable Instruction_Addr_i			: STD_LOGIC_VECTOR(23 downto 0);
	Begin
		wait until (Start_Decompression = '1');
		End_Decompression							<= '0';
		Instruction_Addr_i						:= Instruction_Addr;
		-- STA $4800 = $01
		-- PHI2 CYCLE 0
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 1
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 2
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 3
		SNES_ADDR 									<= X"004800";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004800";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004800";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004800";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004800";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004800";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);


		-- STX $4302 = $A078
		Instruction_Addr_i						:= Instruction_Addr_i+3;
		-- PHI2 CYCLE 0
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 1
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 2
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 3
		SNES_ADDR 									<= X"004302";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004302";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004302";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004302";
		SNES_DATA 									<= Compressed_Addr(7 downto 0);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004302";
		SNES_DATA 									<= Compressed_Addr(7 downto 0);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004302";
		SNES_DATA 									<= Compressed_Addr(7 downto 0);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 4
		SNES_ADDR 									<= X"004303";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004303";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004303";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004303";
		SNES_DATA 									<= Compressed_Addr(15 downto 8);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004303";
		SNES_DATA 									<= Compressed_Addr(15 downto 8);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004303";
		SNES_DATA 									<= Compressed_Addr(15 downto 8);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);


		-- STA $4304 = $DB
		Instruction_Addr_i						:= Instruction_Addr_i+3;
		-- PHI2 CYCLE 0
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 1
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 2
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 3
		SNES_ADDR 									<= X"004304";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004304";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004304";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004304";
		SNES_DATA 									<= Compressed_Addr(23 downto 16);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004304";
		SNES_DATA 									<= Compressed_Addr(23 downto 16);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004304";
		SNES_DATA 									<= Compressed_Addr(23 downto 16);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);


		-- STX $4305 = $0C00
		Instruction_Addr_i						:= Instruction_Addr_i+3;
		-- PHI2 CYCLE 0
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 1
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 2
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 3
		SNES_ADDR 									<= X"004305";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004305";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004305";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004305";
		SNES_DATA 									<= Compressed_Size(7 downto 0);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004305";
		SNES_DATA 									<= Compressed_Size(7 downto 0);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004305";
		SNES_DATA 									<= Compressed_Size(7 downto 0);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 4
		SNES_ADDR 									<= X"004306";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004306";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004306";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004306";
		SNES_DATA 									<= Compressed_Size(15 downto 8);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004306";
		SNES_DATA 									<= Compressed_Size(15 downto 8);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004306";
		SNES_DATA 									<= Compressed_Size(15 downto 8);
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);


		-- STA $4801 = $01
		Instruction_Addr_i						:= Instruction_Addr_i+3;
		-- PHI2 CYCLE 0
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 1
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 2
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 3
		SNES_ADDR 									<= X"004801";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004801";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004801";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004801";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004801";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"004801";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);


		-- PHA
		Instruction_Addr_i						:= Instruction_Addr_i+3;
		-- PHI2 CYCLE 0
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 1 (IO)
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 2 (SLOW)
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);



		-- PLA
		Instruction_Addr_i						:= Instruction_Addr_i+1;
		-- PHI2 CYCLE 0
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 1 (IO)
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 2 (IO)
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 3 (SLOW)
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"0001F0";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);

		-- STA $420B = $01
		Instruction_Addr_i						:= Instruction_Addr_i+1;
		-- PHI2 CYCLE 0
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 1
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 2
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i+2;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		-- PHI2 CYCLE 3
		SNES_ADDR 									<= X"00420B";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"00420B";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"00420B";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"00420B";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"00420B";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"00420B";
		SNES_DATA 									<= X"01";
		SNES_RD										<= '1';
		SNES_WR										<= '0';
		wait until falling_edge(MCLK);


		-- STZ $4800 = $00
		Instruction_Addr_i						:= Instruction_Addr_i+3;
		-- PHI2 CYCLE 0
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= Instruction_Addr_i;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '0';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);

		-- DMA pre-sync (0 to 7 cycles)
		SNES_ADDR 									<= Instruction_Addr_i+1;
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);

		-- DMA setup (8 cycles)
		SNES_ADDR 									<= X"00FFFF";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"00FFFF";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"00FFFF";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"00FFFF";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"00FFFF";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"00FFFF";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"00FFFF";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);
		SNES_ADDR 									<= X"00FFFF";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		wait until falling_edge(MCLK);

		-- DMA transfer
		for i in 1 to conv_integer(Compressed_Size) loop
			DMA_Data_tvalid							<= '0';
			SNES_ADDR 									<= Compressed_Addr;
			SNES_DATA 									<= (others => 'Z');
			SNES_RD										<= '1';
			SNES_WR										<= '1';
			wait until falling_edge(MCLK);
			SNES_ADDR 									<= Compressed_Addr;
			SNES_DATA 									<= (others => 'Z');
			SNES_RD										<= '1';
			SNES_WR										<= '1';
			wait until falling_edge(MCLK);
			SNES_ADDR 									<= Compressed_Addr;
			SNES_DATA 									<= (others => 'Z');
			SNES_RD										<= '1';
			SNES_WR										<= '1';
			wait until falling_edge(MCLK);
			SNES_ADDR 									<= Compressed_Addr;
			SNES_DATA 									<= (others => 'Z');
			SNES_RD										<= '1';
			SNES_WR										<= '1';
			wait until falling_edge(MCLK);
			SNES_ADDR 									<= Compressed_Addr;
			SNES_DATA 									<= (others => 'Z');
			SNES_RD										<= '0';
			SNES_WR										<= '1';
			wait until falling_edge(MCLK);
			SNES_ADDR 									<= Compressed_Addr;
			SNES_DATA 									<= (others => 'Z');
			SNES_RD										<= '0';
			SNES_WR										<= '1';
			wait until falling_edge(MCLK);
			SNES_ADDR 									<= Compressed_Addr;
			SNES_DATA 									<= (others => 'Z');
			SNES_RD										<= '0';
			SNES_WR										<= '1';
			wait until falling_edge(MCLK);
			SNES_ADDR 									<= Compressed_Addr;
			SNES_DATA 									<= (others => 'Z');
			SNES_RD										<= '0';
			SNES_WR										<= '1';
			DMA_Data_tvalid							<= '1';
			wait until falling_edge(MCLK);
		end loop;

		SNES_ADDR 									<= X"C00000";
		SNES_DATA 									<= (others => 'Z');
		SNES_RD										<= '1';
		SNES_WR										<= '1';
		DMA_Data_tvalid							<= '0';
		End_Decompression							<= '1';
		wait until (Start_Decompression = '0');
	End Process;



	-- read from MaskROM
 	process( ROM_OE, ROM_CS, ROM_ADDR, ROM_BHE, ROM_BLE )
	Begin
		if( ROM_CS = '0' AND ROM_OE = '0' ) then
			if( ROM_BHE = '0' ) then
				ROM_DATA(15 downto 8)			<= MaskROM_0(conv_integer(ROM_ADDR))(15 downto 8)	after ROM_tACCESS;
			else
				ROM_DATA(15 downto 8)			<= (others => 'Z') after 15 ns;
			end if;

			if( ROM_BLE = '0' ) then
				ROM_DATA(7 downto 0)				<= MaskROM_0(conv_integer(ROM_ADDR))(7 downto 0)	after ROM_tACCESS;
			else
				ROM_DATA(7 downto 0)				<= (others => 'Z') after 15 ns;
			end if;
		else
			ROM_DATA									<= (others => 'Z') after 15 ns;
		end if;
	End Process;


	-- output data file
	process( MCLK )
		variable valor 							: integer;
		variable	DMA_Data_Idx					: integer := 0;
	begin
		if rising_edge( MCLK ) then
			if( DMA_Data_tvalid = '1' ) then
				if( DMA_Data_Idx = 3 ) then
					-- write word to disk
					valor								:= conv_integer(SNES_DATA & DMA_Data_dword(31 downto 8));
					write(descomp_data, valor);
					DMA_Data_Idx					:= 0;
				else
					DMA_Data_dword					<= SNES_DATA & DMA_Data_dword(31 downto 8);
					DMA_Data_Idx					:= DMA_Data_Idx + 1;
				end if;
			end if;
		end if;
	end process;

	-- clock generator
	Process
	Begin
		MCLK											<= '0';
		wait for CLK_PERIOD/2;
		MCLK											<= '1';
		wait for CLK_PERIOD/2;
	End Process;

	Process
	Begin
		CPU_CLK										<= '1';
		wait for PHI2_PERIOD/2;
		CPU_CLK										<= '0';
		wait for PHI2_PERIOD/2;
	End Process;


	Process
	Begin
		wait for 3ns;
		loop
			SD2SNES_CLK									<= '1';
			wait for SD2SNES_PERIOD/2;
			SD2SNES_CLK									<= '0';
			wait for SD2SNES_PERIOD/2;
		end loop;
	End Process;
end Behavioral;
