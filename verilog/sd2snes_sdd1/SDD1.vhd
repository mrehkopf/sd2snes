----------------------------------------------------------------------------------
-- Company: Traducciones Magno
-- Engineer: Magno
--
-- Create Date: 29.03.2018 19:16:08
-- Design Name:
-- Module Name: SDD1 - Behavioral
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SDD1 is
	Port(	MCLK									: in	STD_LOGIC;
			SNES_cycle_start					: in	STD_LOGIC;
			SNES_cycle_end						: in	STD_LOGIC;
			SNES_REFRESH						: in	STD_LOGIC;
			RESET									: in	STD_LOGIC;
			SRAM_CS								: out STD_LOGIC;
			SRAM_RD								: out STD_LOGIC;
			SRAM_WR								: out STD_LOGIC;
			ROM_OE								: out STD_LOGIC;
			ROM_CS								: out STD_LOGIC;
			ROM_ADDR								: out STD_LOGIC_VECTOR(21 downto 0);
			ROM_DATA								: in	STD_LOGIC_VECTOR(15 downto 0);
			SNES_ADDR							: in	STD_LOGIC_VECTOR(23 downto 0);
			SNES_DATA_IN						: in	STD_LOGIC_VECTOR(7 downto 0);
			SNES_DATA_OUT						: out STD_LOGIC_VECTOR(7 downto 0);
			SNES_RD								: in	STD_LOGIC;
			SNES_WR								: in	STD_LOGIC;
			SNES_WR_End							: in	STD_LOGIC;
			DMA_Transferring					: out STD_LOGIC;
			Idle									: out STD_LOGIC );
end SDD1;


architecture Behavioral of SDD1 is
	-- number of SD2SNES clock cycles of ROM time access -> 7 cycles = 73 ns for -70ns PSRAM
	--constant ROM_ACCESS_CYCLES					: integer := 7;
	-- number of SD2SNES clock cycles of ROM time access -> 9 cycles = 93.75 ns for -85ns PSRAM
	constant ROM_ACCESS_CYCLES					: integer := 9;

	COMPONENT Input_Manager
		Port(	clk									: in 	STD_LOGIC;
				-- control data
				DMA_Conf_Valid						: in	STD_LOGIC;
				DMA_In_Progress					: in	STD_LOGIC;
				Header_Valid						: out	STD_LOGIC;
				Header_BPP							: out	STD_LOGIC_VECTOR(1 downto 0);
				Header_Context						: out	STD_LOGIC_VECTOR(1 downto 0);
				-- data input from ROM
				ROM_Data_tready					: out STD_LOGIC;
				ROM_Data_tvalid					: in	STD_LOGIC;
				ROM_Data_tdata						: in	STD_LOGIC_VECTOR(15 downto 0);
				ROM_Data_tkeep						: in	STD_LOGIC_VECTOR(1 downto 0);
				-- Golomb decoded value
				Decoded_Bit_tready				: in	STD_LOGIC;
				Decoded_Bit_tuser					: in	STD_LOGIC_VECTOR(7 downto 0);
				Decoded_Bit_tvalid				: out STD_LOGIC;
				Decoded_Bit_tdata					: out STD_LOGIC;
				Decoded_Bit_tlast					: out STD_LOGIC);
	END COMPONENT;

	COMPONENT Probability_Estimator
		Port(	clk 									: in 	STD_LOGIC;
				-- control data
				DMA_In_Progress					: in	STD_LOGIC;
				Header_Valid						: in	STD_LOGIC;
				Header_Context						: in	STD_LOGIC_VECTOR(1 downto 0);
				-- run data from input manager
				Decoded_Bit_tready 				: out STD_LOGIC;
				Decoded_Bit_tuser					: out STD_LOGIC_VECTOR(7 downto 0);
				Decoded_Bit_tvalid				: in	STD_LOGIC;
				Decoded_Bit_tdata					: in	STD_LOGIC;
				Decoded_Bit_tlast					: in	STD_LOGIC;
				-- estimated bit value
				BPP_Bit_tready						: in	STD_LOGIC;
				BPP_Bit_tuser						: in	STD_LOGIC_VECTOR(9 downto 0);
				BPP_Bit_tvalid						: out STD_LOGIC;
				BPP_Bit_tdata						: out STD_LOGIC);
	END COMPONENT;

	COMPONENT Output_Manager
		Port(	clk 									: in 	STD_LOGIC;
				-- configuration received from DMA
				DMA_In_Progress					: out	STD_LOGIC;
				DMA_Transfer_End					: in	STD_LOGIC;
				Header_Valid						: in	STD_LOGIC;
				Header_BPP							: in	STD_LOGIC_VECTOR(1 downto 0);
				-- data input from Probability Estimator
				BPP_Bit_tready						: out	STD_LOGIC;
				BPP_Bit_tuser						: out	STD_LOGIC_VECTOR(9 downto 0);
				BPP_Bit_tvalid						: in	STD_LOGIC;
				BPP_Bit_tdata						: in	STD_LOGIC;
				-- data output to DMA
				DMA_Data_tready					: in 	STD_LOGIC;
				DMA_Data_tvalid					: out STD_LOGIC;
				DMA_Data_tdata						: out STD_LOGIC_VECTOR(7 downto 0) );
	END COMPONENT;

	type TipoEstado								is(WAIT_START, GET_DMA_CONFIG, START_DECOMPRESSION, WAIT_DMA_TRIGGERED, WAIT_DMA_START_TRANSFER,
															WAIT_TRANSFER_COMPLETE, WAIT_READ_CYCLE_END, END_DECOMPRESSION);
	signal estado									: TipoEstado := WAIT_START;

	signal DMA_Triggered							: STD_LOGIC := '0';
	signal DMA_Channel_Valid					: STD_LOGIC := '0';
	signal DMA_Channel_Select					: integer range 0 to 7 := 0;
	signal DMA_Channel_Transfer				: integer range 0 to 7 := 0;
	signal DMA_Channel_Select_Mask			: STD_LOGIC_VECTOR(7 downto 0) := X"00";
	signal DMA_Channel_Enable					: STD_LOGIC := '0';
	signal DMA_Target_Register					: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

	type DMA_Src_Addr_t							is array (0 to 7) of STD_LOGIC_VECTOR(23 downto 0);
	type DMA_Size_t								is array (0 to 7) of STD_LOGIC_VECTOR(15 downto 0);
	signal DMA_Src_Addr							: DMA_Src_Addr_t := (others => (others => '0'));
	signal DMA_Size								: DMA_Size_t := (others => (others => '0'));
	signal Curr_Src_Addr							: STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
	signal Curr_Size								: integer range 0 to 65535 := 0;
	signal ROM_Access_Cnt						: integer range 0 to 15 := 0;

	signal Register_Data_Out					: STD_LOGIC_VECTOR(7 downto 0) := X"00";
	signal Register_Access						: STD_LOGIC := '0';
	signal Bank_Map_C0							: STD_LOGIC_VECTOR(3 downto 0) := X"0";
	signal Bank_Map_D0							: STD_LOGIC_VECTOR(3 downto 0) := X"1";
	signal Bank_Map_E0							: STD_LOGIC_VECTOR(3 downto 0) := X"2";
	signal Bank_Map_F0							: STD_LOGIC_VECTOR(3 downto 0) := X"3";
	signal ROM_Data_Byte							: STD_LOGIC_VECTOR(7 downto 0) := X"00";
	signal ROM_Data_tready						: STD_LOGIC := '0';
	signal ROM_Data_tvalid						: STD_LOGIC := '0';
	signal ROM_Data_tdata						: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
	signal ROM_Data_tkeep						: STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
	signal DMA_Data_tready						: STD_LOGIC := '0';
	signal DMA_Data_tvalid						: STD_LOGIC := '0';
	signal DMA_Data_tdata						: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal DMA_Data_out							: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

	signal FSM_Sniff_DMA_Config				: STD_LOGIC := '0';
	signal FSM_Avoid_Collision					: STD_LOGIC := '0';
	signal FSM_DMA_Transferring				: STD_LOGIC := '0';
	signal FSM_Start_Decompression			: STD_LOGIC := '0';
	signal FSM_End_Decompression				: STD_LOGIC := '0';
	signal FSM_Idle								: STD_LOGIC := '0';
	signal FSM_Reset								: STD_LOGIC := '0';

	signal DMA_In_Progress						: STD_LOGIC := '0';
	signal Header_Valid							: STD_LOGIC := '0';
	signal Header_BPP								: STD_LOGIC_VECTOR(1 downto 0) := "00";
	signal Header_Context						: STD_LOGIC_VECTOR(1 downto 0) := "00";

	signal Decoded_Bit_tready					: STD_LOGIC := '0';
	signal Decoded_Bit_tuser					: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal Decoded_Bit_tvalid					: STD_LOGIC := '0';
	signal Decoded_Bit_tdata					: STD_LOGIC := '0';
	signal Decoded_Bit_tlast					: STD_LOGIC := '0';

	signal BPP_Bit_tready						: STD_LOGIC := '0';
	signal BPP_Bit_tuser							: STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
	signal BPP_Bit_tvalid						: STD_LOGIC := '0';
	signal BPP_Bit_tdata							: STD_LOGIC := '0';


	signal SNES_RD_Pipe							: STD_LOGIC_VECTOR(1 downto 0) := "11";
	signal ROM_ADDR_i								: STD_LOGIC_VECTOR(21 downto 0);
	signal ROM_CS_i								: STD_LOGIC := '0';
	signal FIFO_READ								: STD_LOGIC := '0';

	signal SNES_Refresh_Pipe					: STD_LOGIC_VECTOR(5 downto 0) := "000000";
	signal SNES_Refresh_Cycle					: STD_LOGIC := '0';
	signal Bus_Slot								: STD_LOGIC := '0';
	signal Bus_Slot_Free							: STD_LOGIC := '0';
	signal DMA_Src_Match							: STD_LOGIC := '0';

	signal SNES_cycle_start_i					: STD_LOGIC := '0';
	signal SNES_cycle_end_i						: STD_LOGIC := '0';

begin
	DMA_Transferring								<= FSM_DMA_Transferring;
	Idle												<= FSM_Idle;

	-- clock (edge) generation
	-- RG support two bus slots per SNES cycle.  One typically used by the SNES and one that is always free.
	Process( MCLK ) begin
		if rising_edge( MCLK ) then
			-- RG free slot always available.	 main blocks MCU during active S-DD1.
			-- SNES slot is available during a Src Match (DMA) or during refresh to provide more bandwidth.
			-- refresh seemed to fix the glitches.  SO (JP) was randomly corrupting the New Game screen whenever a refresh happened right after a $4801 <- 1 write.
			-- This left 1-2 free slots before the dead SNES_cycles which caused a problem.  does the decompressor require some number of bytes to always be available
			-- during a fixed period prior to DMA start?	this also fixed other glitches in SO and SFA.

			--	Bus_Slot											<= SNES_cycle_start OR SNES_cycle_end;
			--	Bus_Slot_Free										<= SNES_cycle_end;

			-- to reproduce the problem remove the Refresh term and toggle New Game (A button) then back (B button) repeatedly until there is a longer pause and graphics glitch on SO (JP).
			-- the byte that fails is the 7th decompressed byte from $FE5CF0 (should be $58, but is actually $78) on the transition to the New Game screen.
			-- this is a DMA to WRAM $7F2800.	 $7F2000/$2800 are used as some sort of lookup table and the corruption causes the SNES to execute incorrectly (but not crash most of the time).
			--Bus_Slot_Free							<= SNES_Cycle_End OR (SNES_Cycle_Start AND DMA_Src_Match) OR (SNES_Refresh_Pipe(1) XOR SNES_Refresh_Pipe(0));
			Bus_Slot_Free							<= SNES_Cycle_End OR (SNES_Cycle_Start AND FSM_DMA_Transferring) OR SNES_Refresh_Cycle;

			-- pipeline for avoiding glitches and metastability
			SNES_Refresh_Pipe 					<= SNES_Refresh_Pipe(4 downto 0) & SNES_REFRESH;
		end if;
	End Process;

	-- allow a ROM read slot just after REFRESH is started and just after REFRESH is finished
	SNES_Refresh_Cycle							<= '1' when SNES_Refresh_Pipe(5 downto 1) = "00011" OR SNES_Refresh_Pipe(5 downto 1) = "11100" else '0';

	-- decode SRAM access [$7X]:[$6000-$7FFF]; be careful with W-RAM $7E and $7F
	-- RG access only driven by address compare.
	Process(SNES_ADDR, SNES_RD, SNES_WR)
	Begin
		if( SNES_ADDR(23 downto 19) = B"01110" AND SNES_ADDR(15 downto 13) = "011" ) then
			SRAM_CS									<= SNES_RD AND SNES_WR;
			SRAM_RD									<= SNES_RD;
			SRAM_WR									<= SNES_WR;
		else
			SRAM_CS									<= '1';
			SRAM_RD									<= '1';
			SRAM_WR									<= '1';
		end if;
	End Process;

	-- decode ROM access; SNES CPU has priority over decompression core's input FIFO
	Process( SNES_ADDR, SNES_RD, FSM_DMA_Transferring, FSM_Avoid_Collision, Curr_Src_Addr, ROM_Data_tready,
				Bank_Map_C0, Bank_Map_D0, Bank_Map_E0, Bank_Map_F0, Bus_Slot_Free, ROM_Access_Cnt )
	Begin
		-- when CPU and SDD1 may collide
		-- RG allow DMA to use both slots.  Prefetch can only use the free slot.  Once an access is started, always drive the address and OE.
		if ( (FSM_DMA_Transferring = '1' AND Bus_Slot_Free = '1') OR (FSM_Avoid_Collision = '1' AND Bus_Slot_Free = '1') OR ROM_Access_Cnt /= 0 ) then
			-- check which megabit is mapped onto $C0
			if( Curr_Src_Addr(23 downto 20) = X"C" ) then
				ROM_ADDR_i							<= Bank_Map_C0(2 downto 0) & Curr_Src_Addr(19 downto 1);
				ROM_CS_i								<= NOT ROM_Data_tready;
				ROM_OE								<= NOT ROM_Data_tready;
			-- check which megabit is mapped onto $D0
			elsif( Curr_Src_Addr(23 downto 20) = X"D" ) then
				ROM_ADDR_i							<= Bank_Map_D0(2 downto 0) & Curr_Src_Addr(19 downto 1);
				ROM_CS_i								<= NOT ROM_Data_tready;
				ROM_OE								<= NOT ROM_Data_tready;
			-- check which megabit is mapped onto $E0
			elsif( Curr_Src_Addr(23 downto 20) = X"E" ) then
				ROM_ADDR_i							<= Bank_Map_E0(2 downto 0) & Curr_Src_Addr(19 downto 1);
				ROM_CS_i								<= NOT ROM_Data_tready;
				ROM_OE								<= NOT ROM_Data_tready;
			-- check which megabit is mapped onto $F0
			elsif( Curr_Src_Addr(23 downto 20) = X"F" ) then
				ROM_ADDR_i							<= Bank_Map_F0(2 downto 0) & Curr_Src_Addr(19 downto 1);
				ROM_CS_i								<= NOT ROM_Data_tready;
				ROM_OE								<= NOT ROM_Data_tready;
			else
				ROM_ADDR_i							<= Curr_Src_Addr(22 downto 1);
				ROM_CS_i								<= '1';
				ROM_OE								<= '1';
			end if;
		-- Perform non-SDD1 ROM access for SNES
		-- RG drive ROM based only on address compares.  The timing of the ROM access and internal SNES_RD signal requires this.
		else
			-- Low addresses are not mapped
			if( SNES_ADDR(22) = '0' AND SNES_ADDR(15) = '1' ) then
				ROM_ADDR_i							<= SNES_ADDR(23 downto 16) & SNES_ADDR(14 downto 1);
				ROM_CS_i								<= '0';
				ROM_OE								<= '0';
			-- check which megabit is mapped onto $C0
			elsif( SNES_ADDR(23 downto 20) = X"C" ) then
				ROM_ADDR_i							<= Bank_Map_C0(2 downto 0) & SNES_ADDR(19 downto 1);
				ROM_CS_i								<= '0';
				ROM_OE								<= '0';
			-- check which megabit is mapped onto $D0
			elsif( SNES_ADDR(23 downto 20) = X"D" ) then
				ROM_ADDR_i							<= Bank_Map_D0(2 downto 0) & SNES_ADDR(19 downto 1);
				ROM_CS_i								<= '0';
				ROM_OE								<= '0';
			-- check which megabit is mapped onto $E0
			elsif( SNES_ADDR(23 downto 20) = X"E" ) then
				ROM_ADDR_i							<= Bank_Map_E0(2 downto 0) & SNES_ADDR(19 downto 1);
				ROM_CS_i								<= '0';
				ROM_OE								<= '0';
			-- check which megabit is mapped onto $F0
			elsif( SNES_ADDR(23 downto 20) = X"F" ) then
				ROM_ADDR_i							<= Bank_Map_F0(2 downto 0) & SNES_ADDR(19 downto 1);
				ROM_CS_i								<= '0';
				ROM_OE								<= '0';
			else
				ROM_ADDR_i							<= SNES_ADDR(21 downto 0);
				ROM_CS_i								<= '1';
				ROM_OE								<= '1';
			end if;
		end if;
	End Process;

	ROM_CS											<= ROM_CS_i;
	ROM_ADDR											<= ROM_ADDR_i;

	-- decode data bus
	Process(SNES_RD, SNES_ADDR, ROM_DATA)
	Begin
		if( SNES_RD = '0' ) then
			if( SNES_ADDR(0) = '0' ) then
				ROM_Data_Byte						<= ROM_DATA(7 downto 0);
			else
				ROM_Data_Byte						<= ROM_DATA(15 downto 8);
			end if;
		else
			ROM_Data_Byte							<= X"00";
		end if;
	End Process;


	-- S-DD1 WRITE register map
	--		$4800 = x -> put S-DD1 to sniff configuration for DMA channel x from SNES address bus
	--		$4801 = x -> start decompression from DMA channel x
	--		$4802 = ? -> ???
	--		$4803 = ? -> ???
	--		$4804 = x -> maps the x-th megabit in ROM into SNES $C0-$CF
	--		$4805 = x -> maps the x-th megabit in ROM into SNES $D0-$DF
	--		$4806 = x -> maps the x-th megabit in ROM into SNES $E0-$EF
	--		$4807 = x -> maps the x-th megabit in ROM into SNES $F0-$FF
	Process( MCLK )
	Begin
		if rising_edge( MCLK ) then
			if( RESET = '0' ) then
				Bank_Map_C0								<= X"0";
				Bank_Map_D0								<= X"1";
				Bank_Map_E0								<= X"2";
				Bank_Map_F0								<= X"3";
				DMA_Channel_Valid						<= '0';
				DMA_Channel_Select_Mask				<= X"00";
				DMA_Channel_Enable					<= '0';
				DMA_Channel_Transfer					<= 0;
			else
				-- SNES bank $00 -> register $480X can be accessed from any LoROM bank
				if( SNES_WR_End = '1' AND SNES_ADDR(22) = '0' AND SNES_ADDR(15 downto 4) = X"480" ) then
					case SNES_ADDR(3 downto 0) is
						-- register $4800 -> select the DMA channels to sniff
						when X"0" =>
							-- register channel mask to sniff writes to $43X-
							DMA_Channel_Select_Mask	<= SNES_DATA_IN;
							-- if channel is 0, decoding is disabled; if not, decoding can be
							-- triggered again without writting to $4800
							if( SNES_DATA_IN = X"00" ) then
								DMA_Channel_Valid		<= '0';
							else
								DMA_Channel_Valid		<= '1';
							end if;

						-- register $4801 -> select the DMA channel to be triggered
						-- this is used to pre-fetch data from the source address before
						-- DMA is triggered writing to $420B
						when X"1" =>
							case SNES_DATA_IN is
								when X"02" =>
									DMA_Channel_Transfer	<= 1;
								when X"04" =>
									DMA_Channel_Transfer	<= 2;
								when X"08" =>
									DMA_Channel_Transfer	<= 3;
								when X"10" =>
									DMA_Channel_Transfer	<= 4;
								when X"20" =>
									DMA_Channel_Transfer	<= 5;
								when X"40" =>
									DMA_Channel_Transfer	<= 6;
								when X"80" =>
									DMA_Channel_Transfer	<= 7;
								when others =>
									DMA_Channel_Transfer	<= 0;
							end case;
							if( (DMA_Channel_Select_Mask AND SNES_DATA_IN) /= X"00" ) then
								DMA_Channel_Enable	<= '1';
							end if;

						-- register $4804
						when X"4" =>
							Bank_Map_C0					<= SNES_DATA_IN(3 downto 0);

						-- register $4805
						when X"5" =>
							Bank_Map_D0					<= SNES_DATA_IN(3 downto 0);

						-- register $4806
						when X"6" =>
							Bank_Map_E0					<= SNES_DATA_IN(3 downto 0);

						-- register $4807
						when X"7" =>
							Bank_Map_F0					<= SNES_DATA_IN(3 downto 0);

						when others =>
							DMA_Channel_Enable		<= '0';
					end case;
				else
					DMA_Channel_Enable				<= '0';
				end if;
			end if;
		end if;
	End Process;


	-- S-DD1 READ register map
	--		$4800 = x -> put S-DD1 to sniff configuration for DMA channel x from SNES address bus
	--		$4801 = x -> start decompression from DMA channel x
	--		$4802 = ? -> ???
	--		$4803 = ? -> ???
	--		$4804 = x -> maps the x-th megabit in ROM into SNES $C0-$CF
	--		$4805 = x -> maps the x-th megabit in ROM into SNES $D0-$DF
	--		$4806 = x -> maps the x-th megabit in ROM into SNES $E0-$EF
	--		$4807 = x -> maps the x-th megabit in ROM into SNES $F0-$FF
	Process( MCLK )
	Begin
		if rising_edge( MCLK ) then
			if( RESET = '0' ) then
				Register_Access						<= '0';
				Register_Data_Out						<= X"00";
			else
				-- SNES bank $00 -> register $480X can be accessed from any LoROM bank
				if( SNES_ADDR(22) = '0' AND SNES_ADDR(15 downto 4) = X"480" ) then
					Register_Access					<= '1';
					case SNES_ADDR(3 downto 0) is
						-- register $4800 -> select the DMA channels to sniff
						when X"0" =>
							Register_Data_Out			<= DMA_Channel_Select_Mask;

						-- register $4801 -> select the DMA channel to be triggered
						-- this is used to pre-fetch data from the source address before
						-- DMA is triggered writing to $420B
						when X"1" =>
							case DMA_Channel_Transfer is
								when 1 =>
									Register_Data_Out	<= X"02";
								when 2 =>
									Register_Data_Out	<= X"04";
								when 3 =>
									Register_Data_Out	<= X"08";
								when 4 =>
									Register_Data_Out	<= X"10";
								when 5 =>
									Register_Data_Out	<= X"20";
								when 6 =>
									Register_Data_Out	<= X"40";
								when 7 =>
									Register_Data_Out	<= X"80";
								when others =>
									Register_Data_Out	<= X"01";
							end case;


						-- register $4804
						when X"4" =>
							Register_Data_Out			<= X"0" & Bank_Map_C0;

						-- register $4805
						when X"5" =>
							Register_Data_Out			<= X"0" & Bank_Map_D0;

						-- register $4806
						when X"6" =>
							Register_Data_Out			<= X"0" & Bank_Map_E0;

						-- register $4807
						when X"7" =>
							Register_Data_Out			<= X"0" & Bank_Map_F0;

						when others =>
							Register_Data_Out			<= X"00";
					end case;
				else
					Register_Access					<= '0';
				end if;
			end if;
		end if;
	End Process;


	-- DMA channel mask decoded from register address $43X-
	with SNES_ADDR(7 downto 4) select
		DMA_Target_Register							<= X"01" when X"0",
																X"02" when X"1",
																X"04" when X"2",
																X"08" when X"3",
																X"10" when X"4",
																X"20" when X"5",
																X"40" when X"6",
																X"80" when X"7",
																X"00" when others;

	-- channel select to store configuration
	DMA_Channel_Select								<= conv_integer(SNES_ADDR(7 downto 4));


	-- capture DMA configuration from SNES bus
	-- RG DMA registers may be updated at any point. SO requires this: the source bank was
	-- changed outside of a decompression DMA and not updated for a later decompression DMA.
	Process( MCLK )
	Begin
		if rising_edge( MCLK ) then
			if( SNES_WR_End = '1' ) then
				-- capture source address low byte
				if( SNES_ADDR(22) = '0' AND SNES_ADDR(15 downto 8) = X"43" ) then
					if( SNES_ADDR(3 downto 0) = X"2" ) then
						DMA_Src_Addr(DMA_Channel_Select)(7 downto 0)	<= SNES_DATA_IN;
					end if;

					if( SNES_ADDR(3 downto 0) = X"3" ) then
						DMA_Src_Addr(DMA_Channel_Select)(15 downto 8)<= SNES_DATA_IN;
					end if;

					if( SNES_ADDR(3 downto 0) = X"4" ) then
						DMA_Src_Addr(DMA_Channel_Select)(23 downto 16)<= SNES_DATA_IN;
					end if;

					if( SNES_ADDR(3 downto 0) = X"5" ) then
						DMA_Size(DMA_Channel_Select)(7 downto 0)		<= SNES_DATA_IN;
					end if;

					if( SNES_ADDR(3 downto 0) = X"6" ) then
						DMA_Size(DMA_Channel_Select)(15 downto 8)		<= SNES_DATA_IN;
					end if;
				-- get DMA trigger
				elsif( SNES_ADDR(22) = '0' AND SNES_ADDR(15 downto 0) = X"420B" ) then
					DMA_Triggered												<= '1';
				else
					DMA_Triggered												<= '0';
				end if;
			else
				DMA_Triggered													<= '0';
			end if;
		end if;
	End Process;

	-- FSM for controlling configuration capture, decompression and signalling
	Process( MCLK )
	Begin
		if rising_edge( MCLK ) then
			if( RESET = '0' ) then
				estado									<= WAIT_START;
			else
				case estado is
					-- wait until register $4800 is written
					when WAIT_START =>
						if( DMA_Channel_Valid = '1' ) then
							estado						<= GET_DMA_CONFIG;
						end if;

					-- get DMA configuration after writing to $4801
					-- RG either exit when $4800 is cleared or continue when $4801 is written
					when GET_DMA_CONFIG =>
						if( DMA_Channel_Valid = '0' ) then
							estado          		  <= WAIT_START;
						elsif( DMA_Channel_Enable = '1' ) then
							estado						<= START_DECOMPRESSION;
						end if;

					-- update source address and size registers and launch decompression
					when START_DECOMPRESSION =>
						estado							<= WAIT_DMA_TRIGGERED;

					-- wait until DMA is triggered writting to $420B; until then, ROM access form SNES
					-- CPU has priority over decompression core and it is done each rising edge in SNES_RD
					when WAIT_DMA_TRIGGERED =>
						if( DMA_Triggered = '1' ) then
							estado						<= WAIT_DMA_START_TRANSFER;
						end if;

					-- wait until DMA starts; we know it starts when source address appears on address bus
					when WAIT_DMA_START_TRANSFER =>
						if( DMA_Src_Addr(DMA_Channel_Transfer) = SNES_ADDR ) then
							estado						<= WAIT_TRANSFER_COMPLETE;
						end if;

					-- wait until all bytes have been transferred
					when WAIT_TRANSFER_COMPLETE =>
						if( Curr_Size = 0 ) then
							estado						<= WAIT_READ_CYCLE_END;
						end if;

					-- wait until SNESread cycle ends
					when WAIT_READ_CYCLE_END =>
						if( SNES_RD = '1' ) then
						--if( SNES_RD_Pipe = "01" ) then
							estado						<= END_DECOMPRESSION;
						end if;

					-- stop decompression
					-- RG sdd1 is allowed to continue with further writes of $4801 until $4800 is cleared.  SO does this.
					when END_DECOMPRESSION =>
						estado							<= GET_DMA_CONFIG;
				end case;
			end if;
		end if;
	End Process;

	-- get configuration fom SNES data bus
	with estado select
		FSM_Sniff_DMA_Config							<= '1'	when GET_DMA_CONFIG,
																'1'	when START_DECOMPRESSION,
																'1'	when WAIT_DMA_TRIGGERED,
																'0'	when others;

	-- waiting for DMA to start
	with estado select
		FSM_Avoid_Collision							<= '1' 	when WAIT_DMA_TRIGGERED,
																'1' 	when WAIT_DMA_START_TRANSFER,
																'0'	when others;

	-- signal core to start decompression
	FSM_Start_Decompression							<= '1'	when estado = START_DECOMPRESSION else '0';

	-- decompression and DMA transfer in progress
	with estado select
		FSM_DMA_Transferring							<= '1'	when WAIT_TRANSFER_COMPLETE,
																'1'	when WAIT_READ_CYCLE_END,
																'0'	when others;

	-- signal core to stop decompression
	FSM_End_Decompression							<= '1' 	when estado = END_DECOMPRESSION else '0';

	-- signal idle for memory controller
	-- RG idle used to block MCU accesses
	-- ikari_01 consider GET_DMA_CONFIG idle as well because SFA never returns S-DD1 to WAIT_START
	with estado select
		FSM_Idle                                        <= '1' when WAIT_START,
		                                                   '1' when GET_DMA_CONFIG,
														   '0' when others;

	-- fetch data from ROM while decompressing
	Process( MCLK )
	Begin
		if rising_edge(MCLK) then
			if (RESET = '0') then
				ROM_Access_Cnt <= 0;
			else
				-- update source address
				if( FSM_Start_Decompression = '1' ) then
					Curr_Src_Addr							<= DMA_Src_Addr(DMA_Channel_Transfer);
					ROM_Access_Cnt							<= 0;
				-- after writting to $4801, SNES CPU can fetch new instructions (STA.w $420B and others), so
				-- ROM access must be time multiplexed; when decompressing from S-DD1, ROM is fully time-
				-- allocated to get data (after 3 master cycles)
				elsif( (FSM_DMA_Transferring = '1' AND Bus_Slot_Free = '1') OR (FSM_Avoid_Collision = '1' AND Bus_Slot_Free = '1')  OR ROM_Access_Cnt /= 0 ) then
					if( ROM_Data_tready = '1' ) then
						-- when ROM's access time finish, get data and increment source address
						if( ROM_Access_Cnt = ROM_ACCESS_CYCLES-1 ) then
							ROM_Access_Cnt					<= 0;
							-- if source address is odd, tkeep is "10" to register upper byte and source address
							-- is incremented by 1 to align source address
							if( Curr_Src_Addr(0) = '1' ) then
								Curr_Src_Addr				<= Curr_Src_Addr + 1;
							else
								Curr_Src_Addr				<= Curr_Src_Addr + 2;
							end if;
						else
							ROM_Access_Cnt					<= ROM_Access_Cnt + 1;
						end if;
					else
						ROM_Access_Cnt						<= 0;
					end if;
				else
					ROM_Access_Cnt							<= 0;
				end if;
			end if;
		end if;
	End Process;

	-- in the third read cycle, data is registered on the FIFO
	ROM_Data_tvalid									<= '1' when (FSM_DMA_Transferring = '1' AND ROM_Access_Cnt = (ROM_ACCESS_CYCLES-1) ) else
																'1' when (FSM_Avoid_Collision = '1' AND ROM_Access_Cnt = (ROM_ACCESS_CYCLES-1) ) else
																'0';
	-- if start address is odd, just register upper byte
	ROM_Data_tkeep										<= "10" when Curr_Src_Addr(0) = '1' else "11";
	-- data for decompression is always 16 bits
	ROM_Data_tdata										<= ROM_DATA;


	-- get data from ROM and decode it into N-order Golomb runs
	IM : Input_Manager
		Port map(clk 									=> MCLK,
					-- control data
					DMA_Conf_Valid						=> FSM_Start_Decompression,
					DMA_In_Progress					=> DMA_In_Progress,
					Header_Valid						=> Header_Valid,
					Header_BPP							=> Header_BPP,
					Header_Context						=> Header_Context,
					-- data input from ROM
					ROM_Data_tready					=> ROM_Data_tready,
					ROM_Data_tvalid					=> ROM_Data_tvalid,
					ROM_Data_tdata						=> ROM_Data_tdata,
					ROM_Data_tkeep						=> ROM_Data_tkeep,
					-- Golomb decoded value
					Decoded_Bit_tready				=> Decoded_Bit_tready,
					Decoded_Bit_tuser					=> Decoded_Bit_tuser,
					Decoded_Bit_tvalid				=> Decoded_Bit_tvalid,
					Decoded_Bit_tdata					=> Decoded_Bit_tdata,
					Decoded_Bit_tlast					=> Decoded_Bit_tlast  );

	-- get Golomb data and context to decode pixel
	PE : Probability_Estimator
		Port map(clk 									=> MCLK,
					-- control data
					DMA_In_Progress					=> DMA_In_Progress,
					Header_Valid						=> Header_Valid,
					Header_Context						=> Header_Context,
					-- run data from input manager
					Decoded_Bit_tready 				=> Decoded_Bit_tready,
					Decoded_Bit_tuser					=> Decoded_Bit_tuser,
					Decoded_Bit_tvalid				=> Decoded_Bit_tvalid,
					Decoded_Bit_tdata					=> Decoded_Bit_tdata,
					Decoded_Bit_tlast					=> Decoded_Bit_tlast,
					-- estimated bit value
					BPP_Bit_tready						=> BPP_Bit_tready,
					BPP_Bit_tuser						=> BPP_Bit_tuser,
					BPP_Bit_tvalid						=> BPP_Bit_tvalid,
					BPP_Bit_tdata						=> BPP_Bit_tdata );


	OM : Output_Manager
		Port map(clk 									=> MCLK,
					-- configuration received from DMA
					DMA_In_Progress					=> DMA_In_Progress,
					DMA_Transfer_End					=> FSM_End_Decompression,
					Header_Valid						=> Header_Valid,
					Header_BPP							=> Header_BPP,
					-- data input from Probability Estimator
					BPP_Bit_tready						=> BPP_Bit_tready,
					BPP_Bit_tuser						=> BPP_Bit_tuser,
					BPP_Bit_tvalid						=> BPP_Bit_tvalid,
					BPP_Bit_tdata						=> BPP_Bit_tdata,
					-- data output to DMA
					DMA_Data_tready					=> DMA_Data_tready,
					DMA_Data_tvalid					=> DMA_Data_tvalid,
					DMA_Data_tdata						=> DMA_Data_tdata );


	-- tri-State Buffer control
	SNES_DATA_OUT										<= DMA_Data_out		when (FSM_DMA_Transferring = '1') else
																Register_Data_Out	when (Register_Access = '1') else
																ROM_Data_Byte;

	-- send data to SNES while decompressing using DMA
	Process( MCLK )
	Begin
		if rising_edge(MCLK) then
			if (RESET = '0') then
				DMA_Data_tready <= '0';
			else
				-- register rising edge in SNES_RD from CPU
				SNES_RD_Pipe							<= SNES_RD_Pipe(0) & SNES_RD;

				-- update transfer size
				if( FSM_Start_Decompression = '1' ) then
					Curr_Size							<= conv_integer(DMA_Size(DMA_Channel_Transfer));
					DMA_Data_tready					<= '0';
				-- when source address appears on SNES_ADDR bus, data must be read from core's output FIFO
				elsif( FSM_DMA_Transferring = '1' ) then
					if( DMA_Src_Addr(DMA_Channel_Transfer) = SNES_ADDR ) then
						-- each falling edge in SNES_RD, a data is output from FIFO
						if( DMA_Data_tready = '1' AND DMA_Data_tvalid = '1' ) then
							DMA_Data_tready			<= '0';
						elsif( SNES_RD_Pipe = "10" ) then
							DMA_Data_tready			<= '1';
						end if;
					end if;
				end if;

				-- register decompressed data
				if( DMA_Data_tready = '1' AND DMA_Data_tvalid = '1' ) then
					DMA_Data_out						<= DMA_Data_tdata;
					Curr_Size							<= Curr_Size - 1;
				end if;
			end if;
		end if;
	End Process;
end Behavioral;
