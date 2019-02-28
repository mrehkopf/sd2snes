----------------------------------------------------------------------------------
-- Company: Traducciones Magno
-- Engineer: Magno
--
-- Create Date: 23.03.2018 07:46:09
-- Design Name:
-- Module Name: Output_Manager - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Output_Manager is
		Port(	clk 									: in 	STD_LOGIC;
				-- configuration received from DMA
				DMA_In_Progress					: out	STD_LOGIC;
				DMA_Transfer_End					: in	STD_LOGIC;
				Header_Valid						: in	STD_LOGIC;
				Header_BPP							: in	STD_LOGIC_VECTOR(1 downto 0);
				-- data input from Probability Estimator
				BPP_Bit_tready						: out	STD_LOGIC;
				BPP_Bit_tuser						: out	STD_LOGIC_VECTOR(9 downto 0);
				BPP_Bit_tvalid						: in 	STD_LOGIC;
				BPP_Bit_tdata						: in	STD_LOGIC;
				-- data output to DMA
				DMA_Data_tready					: in 	STD_LOGIC;
				DMA_Data_tvalid					: out STD_LOGIC;
				DMA_Data_tdata						: out STD_LOGIC_VECTOR(7 downto 0) );
end Output_Manager;


architecture Behavioral of Output_Manager is

	COMPONENT FIFO_B2B
		Generic( FIFO_DEPTH						: integer := 32;
					PROG_FULL_TH					: integer := 16	);
		Port(	clk									: IN 	STD_LOGIC;
				srst 									: IN 	STD_LOGIC;
				din_tready							: OUT	STD_LOGIC;
				din_tvalid							: IN 	STD_LOGIC;
				din_tdata 							: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);
				dout_tready							: IN 	STD_LOGIC;
				dout_tvalid							: OUT STD_LOGIC;
				dout_tdata							: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
				prog_full							: OUT STD_LOGIC;
				full									: OUT STD_LOGIC;
				empty									: OUT STD_LOGIC );
	END COMPONENT;

	type TipoEstado								is(WAIT_HEADER, SET_MODE7_BITPLANE, SET_2_BITPLANES, SET_4_BITPLANES, SET_8_BITPLANES,
															BPP0_BIT_0, BPP0_BIT_1, BPP0_BIT_2, BPP0_BIT_3, BPP0_BIT_4, BPP0_BIT_5, BPP0_BIT_6, BPP0_BIT_7,
															BPP0_BIT_0_WAIT, BPP0_BIT_1_WAIT, BPP0_BIT_2_WAIT, BPP0_BIT_3_WAIT, BPP0_BIT_4_WAIT, BPP0_BIT_5_WAIT, BPP0_BIT_6_WAIT, BPP0_BIT_7_WAIT,
															BPP1_BIT_0, BPP1_BIT_1, BPP1_BIT_2, BPP1_BIT_3, BPP1_BIT_4, BPP1_BIT_5, BPP1_BIT_6, BPP1_BIT_7, BPP_BIT_STALL,
															BPP1_BIT_0_WAIT, BPP1_BIT_1_WAIT, BPP1_BIT_2_WAIT, BPP1_BIT_3_WAIT, BPP1_BIT_4_WAIT, BPP1_BIT_5_WAIT, BPP1_BIT_6_WAIT, BPP1_BIT_7_WAIT,
															MODE7_BIT_0, MODE7_BIT_1, MODE7_BIT_2, MODE7_BIT_3, MODE7_BIT_4, MODE7_BIT_5, MODE7_BIT_6, MODE7_BIT_7, MODE7_BIT_STALL,
															MODE7_BIT_0_WAIT, MODE7_BIT_1_WAIT, MODE7_BIT_2_WAIT, MODE7_BIT_3_WAIT, MODE7_BIT_4_WAIT, MODE7_BIT_5_WAIT, MODE7_BIT_6_WAIT, MODE7_BIT_7_WAIT	);
	signal estado									: TipoEstado := WAIT_HEADER;

	signal BPP0_Byte								: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal BPP1_Byte								: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal BPP2_Byte								: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal BPP3_Byte								: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal BPP4_Byte								: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal BPP5_Byte								: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal BPP6_Byte								: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal BPP7_Byte								: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

	signal BPP0_Previous							: STD_LOGIC := '0';
	signal BPP1_Previous							: STD_LOGIC := '0';
	signal BPP2_Previous							: STD_LOGIC := '0';
	signal BPP3_Previous							: STD_LOGIC := '0';
	signal BPP4_Previous							: STD_LOGIC := '0';
	signal BPP5_Previous							: STD_LOGIC := '0';
	signal BPP6_Previous							: STD_LOGIC := '0';
	signal BPP7_Previous							: STD_LOGIC := '0';

	signal Tile_Count								: integer range 0 to 7 := 0;
	signal Max_BPP									: integer range 0 to 7 := 0;
	signal Cnt_BPP									: integer range 0 to 7 := 0;
	signal Cnt_Pair								: integer range 0 to 3 := 0;
	signal Cnt_Even								: integer range 0 to 1 := 0;
	signal Flag_MODE7_Bitplane					: STD_LOGIC := '0';

	signal FIFO_Data_tready						: STD_LOGIC := '0';
	signal FIFO_Data_tready_n					: STD_LOGIC := '1';
	signal FIFO_Data_tvalid						: STD_LOGIC := '0';
	signal FIFO_Data_tdata						: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

	signal FSM_BPP_Bit_tready					: STD_LOGIC := '0';
	signal FSM_Reset								: STD_LOGIC := '1';
	signal FSM_DMA_In_Progress					: STD_LOGIC := '0';
	signal FSM_New_MODE7							: STD_LOGIC := '0';
	signal FSM_Next_BPP0							: STD_LOGIC := '0';
	signal FSM_Next_BPP1							: STD_LOGIC := '0';
	signal FSM_Ready_BPP0						: STD_LOGIC := '0';
	signal FSM_Ready_BPP1						: STD_LOGIC := '0';
	signal FSM_Ready_BPP2						: STD_LOGIC := '0';
	signal FSM_Ready_BPP3						: STD_LOGIC := '0';
	signal FSM_Ready_BPP4						: STD_LOGIC := '0';
	signal FSM_Ready_BPP5						: STD_LOGIC := '0';
	signal FSM_Ready_BPP6						: STD_LOGIC := '0';
	signal FSM_Ready_BPP7						: STD_LOGIC := '0';
	signal FSM_Ready_MODE7						: STD_LOGIC := '0';
	signal FSM_New_Tile							: STD_LOGIC := '0';

begin
	-- current bitplane results from concatenation of current even/odd bitplane and
	-- number of BPP0/BPP1 to decode
	Cnt_BPP											<= Cnt_Pair + Cnt_Pair + Cnt_Even;

	-- process for controlling data planes
	Process( clk )
	Begin
		if rising_edge( clk ) then
			if( FSM_Reset = '1' ) then
				Max_BPP									<= 0;
				Cnt_Pair									<= 0;
				Tile_Count								<= 0;
				Flag_MODE7_Bitplane					<= '0';
				FSM_Ready_MODE7						<= '0';
				BPP0_Previous							<= '0';
				BPP1_Previous							<= '0';
				BPP2_Previous							<= '0';
				BPP3_Previous							<= '0';
				BPP4_Previous							<= '0';
				BPP5_Previous							<= '0';
				BPP6_Previous							<= '0';
				BPP7_Previous							<= '0';
				BPP0_Byte								<= X"00";
				BPP1_Byte								<= X"00";
				BPP2_Byte								<= X"00";
				BPP3_Byte								<= X"00";
				BPP4_Byte								<= X"00";
				BPP5_Byte								<= X"00";
				BPP6_Byte								<= X"00";
				BPP7_Byte								<= X"00";
				FSM_Ready_BPP0							<= '0';
				FSM_Ready_BPP2							<= '0';
				FSM_Ready_BPP4							<= '0';
				FSM_Ready_BPP6							<= '0';
				FSM_Ready_BPP1							<= '0';
				FSM_Ready_BPP3							<= '0';
				FSM_Ready_BPP5							<= '0';
				FSM_Ready_BPP7							<= '0';
			else
				-- set counter's maximum value
				if( estado = SET_2_BITPLANES ) then
					Max_BPP								<= 0;
					Cnt_Pair								<= 0;
					Tile_Count							<= 0;
					Flag_MODE7_Bitplane				<= '0';
				elsif( estado = SET_4_BITPLANES ) then
					Max_BPP								<= 1;
					Cnt_Pair								<= 0;
					Tile_Count							<= 0;
					Flag_MODE7_Bitplane				<= '0';
				elsif( estado = SET_8_BITPLANES ) then
					Max_BPP								<= 3;
					Cnt_Pair								<= 0;
					Tile_Count							<= 0;
					Flag_MODE7_Bitplane				<= '0';
				elsif( estado = SET_MODE7_BITPLANE ) then
					Max_BPP								<= 3;
					Cnt_Pair								<= 0;
					Tile_Count							<= 0;
					Flag_MODE7_Bitplane				<= '1';
				end if;

				-- when mode "11" (MODE7), each new pixel belongs to a different bitplane
				if( Flag_MODE7_Bitplane = '1' ) then
					if( FSM_New_MODE7 = '1' ) then
						if( Cnt_Pair = Max_BPP ) then
							Cnt_Pair						<= 0;
						else
							Cnt_Pair						<= Cnt_Pair + 1;
						end if;
					end if;
				else
					-- increment bitplane when each the pair BPP0/BPP1 has been complete
					if( FSM_Next_BPP1 = '1' ) then
						-- when 8 lines of 1 2BPP tile have been complete, change bitplane
						if( Tile_Count = 7 ) then
							if( Cnt_Pair = Max_BPP ) then
								Cnt_Pair					<= 0;
							else
								Cnt_Pair					<= Cnt_Pair + 1;
							end if;
							Tile_Count					<= 0;
						else
							Tile_Count					<= Tile_Count + 1;
						end if;
					end if;
				end if;

				-- store last decoded bit in corresponding bitplane
				if( BPP_Bit_tvalid = '1' ) then
					case Cnt_BPP is
						-- BPP0
						when 0 =>
							BPP0_Previous				<= BPP0_Byte(7);
							BPP0_Byte					<= BPP0_Byte(6 downto 0) & BPP_Bit_tdata;

						-- BPP1
						when 1 =>
							BPP1_Previous				<= BPP1_Byte(7);
							BPP1_Byte					<= BPP1_Byte(6 downto 0) & BPP_Bit_tdata;

						-- BPP2
						when 2 =>
							BPP2_Previous				<= BPP2_Byte(7);
							BPP2_Byte					<= BPP2_Byte(6 downto 0) & BPP_Bit_tdata;

						-- BPP3
						when 3 =>
							BPP3_Previous				<= BPP3_Byte(7);
							BPP3_Byte					<= BPP3_Byte(6 downto 0) & BPP_Bit_tdata;

						-- BPP4
						when 4 =>
							BPP4_Previous				<= BPP4_Byte(7);
							BPP4_Byte					<= BPP4_Byte(6 downto 0) & BPP_Bit_tdata;

						--BPP5
						when 5 =>
							BPP5_Previous				<= BPP5_Byte(7);
							BPP5_Byte					<= BPP5_Byte(6 downto 0) & BPP_Bit_tdata;

						-- BPP6
						when 6 =>
							BPP6_Previous				<= BPP6_Byte(7);
							BPP6_Byte					<= BPP6_Byte(6 downto 0) & BPP_Bit_tdata;

						-- BPP7
						when 7 =>
							BPP7_Previous				<= BPP7_Byte(7);
							BPP7_Byte					<= BPP7_Byte(6 downto 0) & BPP_Bit_tdata;
					end case;
				end if;

				-- when MODE7, a new byte is completed when BPP0 is asserted
				FSM_Ready_MODE7						<= FSM_Next_BPP0 AND Flag_MODE7_Bitplane;

				-- decide which BPP will go to output register when completed
				if( FSM_Next_BPP0 = '1' ) then
					case Cnt_BPP is
						-- BPP0
						when 0 =>
							FSM_Ready_BPP0				<= '1';
							FSM_Ready_BPP2				<= '0';
							FSM_Ready_BPP4				<= '0';
							FSM_Ready_BPP6				<= '0';

						-- BPP2
						when 2 =>
							FSM_Ready_BPP0				<= '0';
							FSM_Ready_BPP2				<= '1';
							FSM_Ready_BPP4				<= '0';
							FSM_Ready_BPP6				<= '0';

						-- BPP4
						when 4 =>
							FSM_Ready_BPP0				<= '0';
							FSM_Ready_BPP2				<= '0';
							FSM_Ready_BPP4				<= '1';
							FSM_Ready_BPP6				<= '0';

						-- BPP6
						when 6 =>
							FSM_Ready_BPP0				<= '0';
							FSM_Ready_BPP2				<= '0';
							FSM_Ready_BPP4				<= '0';
							FSM_Ready_BPP6				<= '1';

						when others =>
							FSM_Ready_BPP0				<= '0';
							FSM_Ready_BPP2				<= '0';
							FSM_Ready_BPP4				<= '0';
							FSM_Ready_BPP6				<= '0';
					end case;

					FSM_Ready_BPP1						<= '0';
					FSM_Ready_BPP3						<= '0';
					FSM_Ready_BPP5						<= '0';
					FSM_Ready_BPP7						<= '0';
				elsif( FSM_Next_BPP1 = '1' ) then
					case Cnt_BPP is
						-- BPP1
						when 1 =>
							FSM_Ready_BPP1				<= '1';
							FSM_Ready_BPP3				<= '0';
							FSM_Ready_BPP5				<= '0';
							FSM_Ready_BPP7				<= '0';

						-- BPP3
						when 3 =>
							FSM_Ready_BPP1				<= '0';
							FSM_Ready_BPP3				<= '1';
							FSM_Ready_BPP5				<= '0';
							FSM_Ready_BPP7				<= '0';

						-- BPP5
						when 5 =>
							FSM_Ready_BPP1				<= '0';
							FSM_Ready_BPP3				<= '0';
							FSM_Ready_BPP5				<= '1';
							FSM_Ready_BPP7				<= '0';

						-- BPP7
						when 7 =>
							FSM_Ready_BPP1				<= '0';
							FSM_Ready_BPP3				<= '0';
							FSM_Ready_BPP5				<= '0';
							FSM_Ready_BPP7				<= '1';

						when others =>
							FSM_Ready_BPP1				<= '0';
							FSM_Ready_BPP3				<= '0';
							FSM_Ready_BPP5				<= '0';
							FSM_Ready_BPP7				<= '0';
					end case;
					FSM_Ready_BPP0						<= '0';
					FSM_Ready_BPP2						<= '0';
					FSM_Ready_BPP4						<= '0';
					FSM_Ready_BPP6						<= '0';
				else
					FSM_Ready_BPP0						<= '0';
					FSM_Ready_BPP2						<= '0';
					FSM_Ready_BPP4						<= '0';
					FSM_Ready_BPP6						<= '0';
					FSM_Ready_BPP1						<= '0';
					FSM_Ready_BPP3						<= '0';
					FSM_Ready_BPP5						<= '0';
					FSM_Ready_BPP7						<= '0';
				end if;
			end if;
		end if;
	End Process;


	-- pre-calculate context bits and register them
	Process( clk )
	Begin
		if rising_edge( clk ) then
			if( FSM_Reset = '1' OR Header_Valid = '1' ) then
				BPP_Bit_tuser								<= (others => '0');
			elsif( BPP_Bit_tvalid = '1' ) then
				case Cnt_BPP is
					-- BPP0
					when 0 =>
						-- in any mode, if last decoded bit was BPP0, next plane is BBP1
						BPP_Bit_tuser(9)					<= '1';
						BPP_Bit_tuser(8)					<= BPP1_Previous;
						BPP_Bit_tuser(7 downto 0)		<= BPP1_Byte;

					-- BPP1
					when 1 =>
						-- in 4BPP or 8BPP mode, next plane is BPP2 if a tile is about to start
						-- BPP0/BPP1..(x6)..BPP0/BPP1/BPP2/BPP3..(x6)..BPP2/BPP3
						-- BPP0/BPP1..(x6)..BPP0/BPP1/BPP2/BPP3..(x6)..BPP2/BPP3/BPP4/BPP5..(x6)..BPP4/BPP5/BPP6/BPP7..(x6)..BPP6/BPP7
						if( Max_BPP > 0 AND FSM_New_Tile = '1' ) then
							BPP_Bit_tuser(9)				<= '0';
							BPP_Bit_tuser(8)				<= BPP2_Previous;
							BPP_Bit_tuser(7 downto 0)	<= BPP2_Byte;
						-- in 2BPP mode, next plane is always BPP0; tile order is
						-- BPP0/BPP1..(x6)..BPP0/BPP1
						else
							BPP_Bit_tuser(9)				<= '0';
							BPP_Bit_tuser(8)				<= BPP0_Previous;
							BPP_Bit_tuser(7 downto 0)	<= BPP0_Byte;
						end if;


					-- BPP2
					when 2 =>
						-- in any mode, if last decoded bit was BPP2, next plane is BBP3
						BPP_Bit_tuser(9)					<= '1';
						BPP_Bit_tuser(8)					<= BPP3_Previous;
						BPP_Bit_tuser(7 downto 0)		<= BPP3_Byte;

					-- BPP3
					when 3 =>
						-- in 4BPP, next plane is BPP0 if a tile is about to start
						-- BPP0/BPP1..(x6)..BPP0/BPP1/BPP2/BPP3..(x6)..BPP2/BPP3
						if( Max_BPP = 1 AND FSM_New_Tile = '1' ) then
							BPP_Bit_tuser(9)				<= '0';
							BPP_Bit_tuser(8)				<= BPP0_Previous;
							BPP_Bit_tuser(7 downto 0)	<= BPP0_Byte;
						-- in 8BPP mode or MODE7, next plane is BPP4 if a tile is about to start
						-- BPP0/BPP1..(x6)..BPP0/BPP1/BPP2/BPP3..(x6)..BPP2/BPP3/BPP4/BPP5..(x6)..BPP4/BPP5/BPP6/BPP7..(x6)..BPP6/BPP7
						elsif( Max_BPP = 3 AND FSM_New_Tile = '1' ) then
							BPP_Bit_tuser(9)				<= '0';
							BPP_Bit_tuser(8)				<= BPP4_Previous;
							BPP_Bit_tuser(7 downto 0)	<= BPP4_Byte;
						-- in any other cases, next plane is BPP2
						else
							BPP_Bit_tuser(9)				<= '0';
							BPP_Bit_tuser(8)				<= BPP2_Previous;
							BPP_Bit_tuser(7 downto 0)	<= BPP2_Byte;
						end if;


					-- BPP4
					when 4 =>
						-- in 8BPP or MODE7 mode, if last decoded bit was BPP4, next plane is BBP5
						BPP_Bit_tuser(9)					<= '1';
						BPP_Bit_tuser(8)					<= BPP5_Previous;
						BPP_Bit_tuser(7 downto 0)		<= BPP5_Byte;

					-- BPP5
					when 5 =>
						-- in 8BPP mode or MODE7, next plane is BPP6 if a tile is about to start
						-- BPP0/BPP1..(x6)..BPP0/BPP1/BPP2/BPP3..(x6)..BPP2/BPP3/BPP4/BPP5..(x6)..BPP4/BPP5/BPP6/BPP7..(x6)..BPP6/BPP7
						if( Max_BPP = 3 AND FSM_New_Tile = '1' ) then
							BPP_Bit_tuser(9)				<= '0';
							BPP_Bit_tuser(8)				<= BPP6_Previous;
							BPP_Bit_tuser(7 downto 0)	<= BPP6_Byte;
						-- in any other cases, next plane is BPP4
						else
							BPP_Bit_tuser(9)				<= '0';
							BPP_Bit_tuser(8)				<= BPP4_Previous;
							BPP_Bit_tuser(7 downto 0)	<= BPP4_Byte;
						end if;


					-- BPP6
					when 6 =>
						-- in 8BPP or MODE7 mode, if last decoded bit was BPP6, next plane is BBP7
						BPP_Bit_tuser(9)					<= '1';
						BPP_Bit_tuser(8)					<= BPP7_Previous;
						BPP_Bit_tuser(7 downto 0)		<= BPP7_Byte;

					-- BPP7
					when 7 =>
						-- in 8BPP mode or MODE7, next plane is BPP0 if a tile is about to start
						-- BPP0/BPP1..(x6)..BPP0/BPP1/BPP2/BPP3..(x6)..BPP2/BPP3/BPP4/BPP5..(x6)..BPP4/BPP5/BPP6/BPP7..(x6)..BPP6/BPP7
						if( Max_BPP = 3 AND FSM_New_Tile = '1' ) then
							BPP_Bit_tuser(9)				<= '0';
							BPP_Bit_tuser(8)				<= BPP0_Previous;
							BPP_Bit_tuser(7 downto 0)	<= BPP0_Byte;
						-- in any other cases, next plane is BPP6
						else
							BPP_Bit_tuser(9)				<= '0';
							BPP_Bit_tuser(8)				<= BPP6_Previous;
							BPP_Bit_tuser(7 downto 0)	<= BPP6_Byte;
						end if;
				end case;
			end if;
		end if;
	End Process;


	-- output data process
	Process( FSM_Ready_BPP0, FSM_Ready_BPP1, FSM_Ready_BPP2, FSM_Ready_BPP3, FSM_Ready_BPP4,
				FSM_Ready_BPP5, FSM_Ready_BPP6, FSM_Ready_BPP7, BPP0_Byte, BPP1_Byte, BPP2_Byte,
				BPP3_Byte, BPP4_Byte, BPP5_Byte, BPP6_Byte, BPP7_Byte, FSM_Ready_MODE7 )
	Begin
		FIFO_Data_tdata							<= X"00";

		-- send data to output register
		if( FSM_Ready_MODE7 = '1' ) then
			FIFO_Data_tdata(0)					<= BPP0_Byte(0);
			FIFO_Data_tdata(1)					<= BPP1_Byte(0);
			FIFO_Data_tdata(2)					<= BPP2_Byte(0);
			FIFO_Data_tdata(3)					<= BPP3_Byte(0);
			FIFO_Data_tdata(4)					<= BPP4_Byte(0);
			FIFO_Data_tdata(5)					<= BPP5_Byte(0);
			FIFO_Data_tdata(6)					<= BPP6_Byte(0);
			FIFO_Data_tdata(7)					<= BPP7_Byte(0);
		end if;

		if( FSM_Ready_BPP0 = '1' ) then
			FIFO_Data_tdata						<= BPP0_Byte;
		end if;

		if( FSM_Ready_BPP1 = '1' ) then
			FIFO_Data_tdata						<= BPP1_Byte;
		end if;

		if( FSM_Ready_BPP2 = '1' ) then
			FIFO_Data_tdata						<= BPP2_Byte;
		end if;

		if( FSM_Ready_BPP3 = '1' ) then
			FIFO_Data_tdata						<= BPP3_Byte;
		end if;

		if( FSM_Ready_BPP4 = '1' ) then
			FIFO_Data_tdata						<= BPP4_Byte;
		end if;

		if( FSM_Ready_BPP5 = '1' ) then
			FIFO_Data_tdata						<= BPP5_Byte;
		end if;

		if( FSM_Ready_BPP6 = '1' ) then
			FIFO_Data_tdata						<= BPP6_Byte;
		end if;

		if( FSM_Ready_BPP7 = '1' ) then
			FIFO_Data_tdata						<= BPP7_Byte;
		end if;
	End Process;
	FIFO_Data_tvalid								<= FSM_Ready_MODE7 OR FSM_Ready_BPP0 OR FSM_Ready_BPP1 OR FSM_Ready_BPP2 OR FSM_Ready_BPP3 OR
															FSM_Ready_BPP4 OR FSM_Ready_BPP5 OR FSM_Ready_BPP6 OR FSM_Ready_BPP7;

	-- output FIFO
	Output_Data : FIFO_B2B
		Generic map(32, 30)
		Port map(clk								=> clk,
					srst 								=> FSM_Reset,
					din_tready						=> FIFO_Data_tready,
					din_tvalid						=> FIFO_Data_tvalid,
					din_tdata						=> FIFO_Data_tdata,
					dout_tready						=> DMA_Data_tready,
					dout_tvalid						=> DMA_Data_tvalid,
					dout_tdata						=> DMA_Data_tdata,
					prog_full						=> FIFO_Data_tready_n);

	-- output signalling
	BPP_Bit_tready									<= FSM_BPP_Bit_tready;
	DMA_In_Progress								<= FSM_DMA_In_Progress;



	-- finite state machine to ask for BPP bits to Probability Estimator module
	Process( clk )
	Begin
		if rising_edge( clk ) then
			if (DMA_Transfer_End = '1') then
				estado 								<= WAIT_HEADER;
			else
				case estado is
					-- wait until header is read from input
					when WAIT_HEADER =>
						if( Header_Valid = '1' ) then
							-- decode 2BPP tiles
							if( Header_BPP = "00" ) then
								estado					<= SET_2_BITPLANES;
							-- decode 8BPP tiles
							elsif( Header_BPP = "10" ) then
								estado					<= SET_4_BITPLANES;
							-- decode 4BPP tiles
							elsif( Header_BPP = "01" ) then
								estado					<= SET_8_BITPLANES;
							-- decode arbitrary data
							else
								estado					<= SET_MODE7_BITPLANE;
							end if;
						end if;

					-- initialize number of BPP0/BPP1 loops
					when SET_2_BITPLANES =>
						estado							<= BPP0_BIT_0;
					when SET_4_BITPLANES =>
						estado							<= BPP0_BIT_0;
					when SET_8_BITPLANES =>
						estado							<= BPP0_BIT_0;
					when SET_MODE7_BITPLANE =>
						estado							<= MODE7_BIT_0;

					-- states to create BPP0 and BPP1
					-- BPP0/BPP1 pixel 0
					when BPP0_BIT_0 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP0_BIT_0_WAIT;
						end if;
					when BPP0_BIT_0_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP1_BIT_0;
						end if;
					when BPP1_BIT_0 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP1_BIT_0_WAIT;
						end if;
					when BPP1_BIT_0_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP0_BIT_1;
						end if;

					-- BPP0/BPP1 pixel 1
					when BPP0_BIT_1 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP0_BIT_1_WAIT;
						end if;
					when BPP0_BIT_1_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP1_BIT_1;
						end if;
					when BPP1_BIT_1 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP1_BIT_1_WAIT;
						end if;
					when BPP1_BIT_1_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP0_BIT_2;
						end if;

					-- BPP0/BPP1 pixel 2
					when BPP0_BIT_2 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP0_BIT_2_WAIT;
						end if;
					when BPP0_BIT_2_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP1_BIT_2;
						end if;
					when BPP1_BIT_2 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP1_BIT_2_WAIT;
						end if;
					when BPP1_BIT_2_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP0_BIT_3;
						end if;

					-- BPP0/BPP1 pixel 3
					when BPP0_BIT_3 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP0_BIT_3_WAIT;
						end if;
					when BPP0_BIT_3_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP1_BIT_3;
						end if;
					when BPP1_BIT_3 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP1_BIT_3_WAIT;
						end if;
					when BPP1_BIT_3_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP0_BIT_4;
						end if;

					-- BPP0/BPP1 pixel 4
					when BPP0_BIT_4 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP0_BIT_4_WAIT;
						end if;
					when BPP0_BIT_4_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP1_BIT_4;
						end if;
					when BPP1_BIT_4 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP1_BIT_4_WAIT;
						end if;
					when BPP1_BIT_4_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP0_BIT_5;
						end if;

					-- BPP0/BPP1 pixel 5
					when BPP0_BIT_5 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP0_BIT_5_WAIT;
						end if;
					when BPP0_BIT_5_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP1_BIT_5;
						end if;
					when BPP1_BIT_5 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP1_BIT_5_WAIT;
						end if;
					when BPP1_BIT_5_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP0_BIT_6;
						end if;

					-- BPP0/BPP1 pixel 6
					when BPP0_BIT_6 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP0_BIT_6_WAIT;
						end if;
					when BPP0_BIT_6_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP1_BIT_6;
						end if;
					when BPP1_BIT_6 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP1_BIT_6_WAIT;
						end if;
					when BPP1_BIT_6_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP0_BIT_7;
						end if;

					-- BPP0/BPP1 pixel 7
					when BPP0_BIT_7 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP0_BIT_7_WAIT;
						end if;
					when BPP0_BIT_7_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= BPP1_BIT_7;
						end if;
					when BPP1_BIT_7 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= BPP1_BIT_7_WAIT;
						end if;
					when BPP1_BIT_7_WAIT =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						elsif( BPP_Bit_tvalid = '1' AND FIFO_Data_tready_n = '0' ) then
							estado						<= BPP0_BIT_0;
						elsif( BPP_Bit_tvalid = '1' AND FIFO_Data_tready_n = '1' ) then
							estado						<= BPP_BIT_STALL;
						end if;

					-- wait until FIFO is ready to accept data
					when BPP_BIT_STALL =>
						if( FIFO_Data_tready_n = '0' ) then
							estado						<= BPP0_BIT_0;
						end if;



					-- states to create 8 bitplanes in 1 byte
					when MODE7_BIT_0 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= MODE7_BIT_0_WAIT;
						end if;
					when MODE7_BIT_0_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= MODE7_BIT_1;
						end if;
					when MODE7_BIT_1 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= MODE7_BIT_1_WAIT;
						end if;
					when MODE7_BIT_1_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= MODE7_BIT_2;
						end if;
					when MODE7_BIT_2 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= MODE7_BIT_2_WAIT;
						end if;
					when MODE7_BIT_2_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= MODE7_BIT_3;
						end if;
					when MODE7_BIT_3 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= MODE7_BIT_3_WAIT;
						end if;
					when MODE7_BIT_3_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= MODE7_BIT_4;
						end if;
					when MODE7_BIT_4 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= MODE7_BIT_4_WAIT;
						end if;
					when MODE7_BIT_4_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= MODE7_BIT_5;
						end if;
					when MODE7_BIT_5 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= MODE7_BIT_5_WAIT;
						end if;
					when MODE7_BIT_5_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= MODE7_BIT_6;
						end if;
					when MODE7_BIT_6 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= MODE7_BIT_6_WAIT;
						end if;
					when MODE7_BIT_6_WAIT =>
						if( BPP_Bit_tvalid = '1') then
							estado						<= MODE7_BIT_7;
						end if;
					when MODE7_BIT_7 =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						else
							estado						<= MODE7_BIT_7_WAIT;
						end if;
					when MODE7_BIT_7_WAIT =>
						if( DMA_Transfer_End = '1' ) then
							estado						<= WAIT_HEADER;
						elsif( BPP_Bit_tvalid = '1' AND FIFO_Data_tready_n = '0' ) then
							estado						<= MODE7_BIT_0;
						elsif( BPP_Bit_tvalid = '1' AND FIFO_Data_tready_n = '1' ) then
							estado						<= MODE7_BIT_STALL;
						end if;

					when MODE7_BIT_STALL =>
						if( FIFO_Data_tready_n = '0' ) then
							estado						<= MODE7_BIT_0;
						end if;
				end case;
			end if;
		end if;
	End Process;

	-- reset output FIFO
	FSM_Reset										<= '1' 	when estado = WAIT_HEADER else '0';

	-- signals that DMA is running, so data is being outputted from S-DD1
	FSM_DMA_In_Progress							<= '0'	when estado = WAIT_HEADER else '1';

	-- strobe to signal a byte for an even bitplane has just completed
	with estado select
		FSM_Next_BPP0								<= BPP_Bit_tvalid when BPP0_BIT_7_WAIT,
															BPP_Bit_tvalid	when MODE7_BIT_7_WAIT,
															'0'				when others;

	-- strobe to signal a byte for an odd bitplane has just completed
	with estado select
		FSM_Next_BPP1								<= BPP_Bit_tvalid	when BPP1_BIT_7_WAIT,
															'0'				when others;

	-- strobe to signal a new BPP pixel for MODE7 byte
	with estado select
		FSM_New_MODE7								<= BPP_Bit_tvalid	when MODE7_BIT_1_WAIT,
															BPP_Bit_tvalid	when MODE7_BIT_3_WAIT,
															BPP_Bit_tvalid	when MODE7_BIT_5_WAIT,
															BPP_Bit_tvalid	when MODE7_BIT_7_WAIT,
															'0'	when others;

	-- 2BPP tile or one 8x8 mode7 tile is finished
	FSM_New_Tile									<= FSM_Next_BPP1 when Tile_Count = 7 else Flag_MODE7_Bitplane;

	-- indicates is an even or odd plane is being processed
	with estado select
		Cnt_Even										<= 1	when BPP1_BIT_0,
															1	when BPP1_BIT_0_WAIT,
															1	when BPP1_BIT_1,
															1	when BPP1_BIT_1_WAIT,
															1	when BPP1_BIT_2,
															1	when BPP1_BIT_2_WAIT,
															1	when BPP1_BIT_3,
															1	when BPP1_BIT_3_WAIT,
															1	when BPP1_BIT_4,
															1	when BPP1_BIT_4_WAIT,
															1	when BPP1_BIT_5,
															1	when BPP1_BIT_5_WAIT,
															1	when BPP1_BIT_6,
															1	when BPP1_BIT_6_WAIT,
															1	when BPP1_BIT_7,
															1	when BPP1_BIT_7_WAIT,
															1	when MODE7_BIT_1,
															1	when MODE7_BIT_1_WAIT,
															1	when MODE7_BIT_3,
															1	when MODE7_BIT_3_WAIT,
															1	when MODE7_BIT_5,
															1	when MODE7_BIT_5_WAIT,
															1	when MODE7_BIT_7,
															1	when MODE7_BIT_7_WAIT,
															0	when others;


	-- strobe for registering data from previous module
	with estado select
		FSM_BPP_Bit_tready						<= '1'	when BPP0_BIT_0,
															'1'	when BPP1_BIT_0,
															'1'	when BPP0_BIT_1,
															'1'	when BPP1_BIT_1,
															'1'	when BPP0_BIT_2,
															'1'	when BPP1_BIT_2,
															'1'	when BPP0_BIT_3,
															'1'	when BPP1_BIT_3,
															'1'	when BPP0_BIT_4,
															'1'	when BPP1_BIT_4,
															'1'	when BPP0_BIT_5,
															'1'	when BPP1_BIT_5,
															'1'	when BPP0_BIT_6,
															'1'	when BPP1_BIT_6,
															'1'	when BPP0_BIT_7,
															'1'	when BPP1_BIT_7,
															'1'	when MODE7_BIT_0,
															'1'	when MODE7_BIT_1,
															'1'	when MODE7_BIT_2,
															'1'	when MODE7_BIT_3,
															'1'	when MODE7_BIT_4,
															'1'	when MODE7_BIT_5,
															'1'	when MODE7_BIT_6,
															'1'	when MODE7_BIT_7,
															'0'	when others;

end Behavioral;
