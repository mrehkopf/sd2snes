----------------------------------------------------------------------------------
-- Company: Traducciones Magno
-- Engineer: Magno
--
-- Create Date: 22.03.2018 18:59:09
-- Design Name:
-- Module Name: Probability_Estimator - Behavioral
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

entity Probability_Estimator is
	Port(	clk 									: in 	STD_LOGIC;
			-- control data
			DMA_In_Progress					: in	STD_LOGIC;
			Header_Valid						: in	STD_LOGIC;
			Header_Context						: in	STD_LOGIC_VECTOR(1 downto 0);
			-- run data from input manager
			Decoded_Bit_tready 				: out STD_LOGIC;
			Decoded_Bit_tuser					: out STD_LOGIC_VECTOR(7 downto 0);
			Decoded_Bit_tvalid				: in 	STD_LOGIC;
			Decoded_Bit_tdata					: in 	STD_LOGIC;
			Decoded_Bit_tlast					: in 	STD_LOGIC;
			-- estimated bit value
			BPP_Bit_tready						: in 	STD_LOGIC;
			BPP_Bit_tuser						: in 	STD_LOGIC_VECTOR(9 downto 0);
			BPP_Bit_tvalid						: out	STD_LOGIC;
			BPP_Bit_tdata						: out STD_LOGIC);
end Probability_Estimator;


architecture Behavioral of Probability_Estimator is

	type TipoEstado							is( WAIT_START, WAIT_END);
	signal estado								: TipoEstado := WAIT_START;

	type RAM_Reg_Status						is array(0 to 31) of integer range 0 to 32;
	signal RAM_STAT							: RAM_Reg_Status := (others => 0);
	type RAM_Reg_MPS							is array(0 to 31) of STD_LOGIC;
	signal RAM_MPS								: RAM_Reg_MPS := (others => '0');

	signal Context_Type						: STD_LOGIC_VECTOR(1 downto 0) := "00";
	signal Context								: STD_LOGIC_VECTOR(4 downto 0) := "00000";
	signal Context_tuser						: STD_LOGIC_VECTOR(4 downto 0) := "00000";
	signal Curr_MPS							: STD_LOGIC := '0';
	signal Next_MPS							: STD_LOGIC := '0';
	signal Curr_State							: integer range 0 to 32 := 0;
	signal Next_State							: integer range 0 to 32 := 0;
	signal Decoded_Bit_tready_i			: STD_LOGIC := '0';
	signal Decoded_Bit_tready_reg			: STD_LOGIC := '0';
	signal Decoded_Bit_tdata_reg			: STD_LOGIC := '0';
	signal Decoded_Bit_tlast_reg			: STD_LOGIC := '0';

	signal FSM_Reset							: STD_LOGIC := '1';

begin
	-- capture header data and IM data
	Process( clk )
	Begin
		if rising_edge( clk ) then
			if( Header_Valid = '1' ) then
				Context_Type							<= Header_Context;
			end if;

			if( FSM_Reset = '1' ) then
				Decoded_Bit_tready_i					<= '0';
				Decoded_Bit_tdata_reg				<= '0';
				Decoded_Bit_tlast_reg				<= '0';
				Decoded_Bit_tready_reg				<= '0';
			else
				-- when context is registered, we ask a new bit to IM
				Decoded_Bit_tready_i					<= BPP_Bit_tready;

				-- IM pre-fecthes each bit, so the data is available in the next cycle
				if( Decoded_Bit_tvalid = '1' ) then
					Decoded_Bit_tdata_reg			<= Decoded_Bit_tdata;
					Decoded_Bit_tlast_reg			<= Decoded_Bit_tlast;
				end if;
				Decoded_Bit_tready_reg				<= Decoded_Bit_tvalid;
			end if;
		end if;
	End Process;


	-- output bit is ready 1 cycle after IM returns a Golomb decoded bit
	BPP_Bit_tvalid										<= Decoded_Bit_tready_reg;


	-- decode previous bits into context depending on header config
	--  BPP_Bit_tuser(9)		-> BPP0 / BPP1
	--  BPP_Bit_tuser(8)		-> upper-left pixel
	--  BPP_Bit_tuser(7)		-> upper pixel
	--  BPP_Bit_tuser(6)		-> upper-right pixel
	--  BPP_Bit_tuser(1)		-> before-last decoded pixel
	--  BPP_Bit_tuser(0)		-> last decoded pixel
	Process( BPP_Bit_tuser, Context_Type )
	Begin
		case Context_Type is
			-- use previous, upper-left, upper and upper-rigtht pixels
			when "00" =>
				Context_tuser							<= BPP_Bit_tuser(9) & BPP_Bit_tuser(8) & BPP_Bit_tuser(7) & BPP_Bit_tuser(6) & BPP_Bit_tuser(0);

			-- use previous, upper-left and upper pixels
			when "01" =>
				Context_tuser							<= BPP_Bit_tuser(9) & '0' & BPP_Bit_tuser(8) & BPP_Bit_tuser(7) & BPP_Bit_tuser(0);

			-- use previous, upper-right and upper pixels
			when "10" =>
				Context_tuser							<= BPP_Bit_tuser(9) & '0' & BPP_Bit_tuser(7) & BPP_Bit_tuser(6) & BPP_Bit_tuser(0);

			-- use previous, before-previous, upper-left and upper pixels
			when others =>
				Context_tuser							<= BPP_Bit_tuser(9) & BPP_Bit_tuser(8) & BPP_Bit_tuser(7) &  BPP_Bit_tuser(1) & BPP_Bit_tuser(0);
		end case;
	End Process;

	-- register "Context_tuser" decoded from "BPP_Bit_tuser" for internal use; "Context" is aligned to "Decoded_Bit_tready_i"
	Process( clk )
	Begin
		if rising_edge( clk ) then
			if( FSM_Reset = '1' ) then
				Context									<= "00000";
			elsif( BPP_Bit_tready = '1' ) then
				Context									<= Context_tuser;
			end if;
		end if;
	End Process;


	-- MPS is updated in state 0 or 1
	Next_MPS												<= NOT Curr_MPS	when (Curr_State = 0 OR Curr_State = 1) AND Decoded_Bit_tdata_reg = '1' else Curr_MPS;

	-- RAM for storing Most-Probable-Symbol for each context when Golomb run ends
	Process( clk )
	Begin
		if rising_edge( clk ) then
			if( FSM_Reset = '1' ) then
				RAM_MPS									<= (others => '0');
			elsif( Decoded_Bit_tready_reg = '1' AND Decoded_Bit_tlast_reg = '1' ) then
				RAM_MPS(conv_integer(Context))	<= Next_MPS;
			end if;
		end if;
	End Process;

	-- read from MPS RAM
	Curr_MPS												<= RAM_MPS(conv_integer(Context));


	-- next state in evolution table depending on current state and last bit in run
	Process( Curr_State, Decoded_Bit_tdata_reg )
	Begin
		case Curr_State is
			when 0 =>
				Next_State								<= 25;

			when 1 =>
				if( Decoded_Bit_tdata_reg = '0' ) then
					Next_State							<= 2;
				else
					Next_State							<= 1;
				end if;

			when 24 =>
				if( Decoded_Bit_tdata_reg = '0' ) then
					Next_State							<= 24;
				else
					Next_State							<= 23;
				end if;

			when 25 =>
				if( Decoded_Bit_tdata_reg = '0' ) then
					Next_State							<= 26;
				else
					Next_State							<= 1;
				end if;

			when 26 =>
				if( Decoded_Bit_tdata_reg = '0' ) then
					Next_State							<= 27;
				else
					Next_State							<= 2;
				end if;

			when 27 =>
				if( Decoded_Bit_tdata_reg = '0' ) then
					Next_State							<= 28;
				else
					Next_State							<= 4;
				end if;

			when 28 =>
				if( Decoded_Bit_tdata_reg = '0' ) then
					Next_State							<= 29;
				else
					Next_State							<= 8;
				end if;

			when 29 =>
				if( Decoded_Bit_tdata_reg = '0' ) then
					Next_State							<= 30;
				else
					Next_State							<= 12;
				end if;

			when 30 =>
				if( Decoded_Bit_tdata_reg = '0' ) then
					Next_State							<= 31;
				else
					Next_State							<= 16;
				end if;

			when 31 =>
				if( Decoded_Bit_tdata_reg = '0' ) then
					Next_State							<= 32;
				else
					Next_State							<= 18;
				end if;

			when 32 =>
				if( Decoded_Bit_tdata_reg = '0' ) then
					Next_State							<= 24;
				else
					Next_State							<= 22;
				end if;

			when others =>
				if( Decoded_Bit_tdata_reg = '0' ) then
					Next_State							<= Curr_State+1;
				else
					Next_State							<= Curr_State-1;
				end if;
		end case;
	End Process;


	-- RAM for storing next evolution state for each context when Golomb run ends
	Process( clk )
	Begin
		if rising_edge( clk ) then
			if( FSM_Reset = '1' ) then
				RAM_STAT									<= (others => 0);
			elsif( Decoded_Bit_tready_reg = '1' AND Decoded_Bit_tlast_reg = '1' ) then
				RAM_STAT(conv_integer(Context))	<= Next_State;
			end if;
		end if;
	End Process;

	-- output request to IM is done when context is registered from OM
	Decoded_Bit_tready								<= Decoded_Bit_tready_i;

	Process( clk )
	Begin
		if rising_edge( clk ) then
			-- read state from RAM; Curr_State is valid 1 cycle after OM asks for a new bit
			Curr_State									<= RAM_STAT(conv_integer(Context_tuser));

			-- get Colomb decoder order from precalculated current state
			case RAM_STAT(conv_integer(Context_tuser)) is
				when 5 		=> Decoded_Bit_tuser			<= "00000010";
				when 6 		=> Decoded_Bit_tuser			<= "00000010";
				when 7 		=> Decoded_Bit_tuser			<= "00000010";
				when 8 		=> Decoded_Bit_tuser			<= "00000010";
				when 9 		=> Decoded_Bit_tuser			<= "00000100";
				when 10		=> Decoded_Bit_tuser			<= "00000100";
				when 11 		=> Decoded_Bit_tuser			<= "00000100";
				when 12 		=> Decoded_Bit_tuser			<= "00000100";
				when 13 		=> Decoded_Bit_tuser			<= "00001000";
				when 14 		=> Decoded_Bit_tuser			<= "00001000";
				when 15 		=> Decoded_Bit_tuser			<= "00001000";
				when 16 		=> Decoded_Bit_tuser			<= "00001000";
				when 17 		=> Decoded_Bit_tuser			<= "00010000";
				when 18 		=> Decoded_Bit_tuser			<= "00010000";
				when 19 		=> Decoded_Bit_tuser			<= "00100000";
				when 20 		=> Decoded_Bit_tuser			<= "00100000";
				when 21 		=> Decoded_Bit_tuser			<= "01000000";
				when 22 		=> Decoded_Bit_tuser			<= "01000000";
				when 23 		=> Decoded_Bit_tuser			<= "10000000";
				when 24 		=> Decoded_Bit_tuser			<= "10000000";
				when 26 		=> Decoded_Bit_tuser			<= "00000010";
				when 27 		=> Decoded_Bit_tuser			<= "00000100";
				when 28 		=> Decoded_Bit_tuser			<= "00001000";
				when 29		=> Decoded_Bit_tuser			<= "00010000";
				when 30		=> Decoded_Bit_tuser			<= "00100000";
				when 31		=> Decoded_Bit_tuser			<= "01000000";
				when 32		=> Decoded_Bit_tuser			<= "10000000";
				when others =>	Decoded_Bit_tuser			<= "00000001";
			end case;

		end if;
	End Process;


	-- output pixel is XOR from current MPS and decoded golomb bit
	BPP_Bit_tdata										<= Decoded_Bit_tdata_reg XOR Curr_MPS;


	-- FSM for controlling input data into the FIFO and serialized data to
	-- Golomb decoders
	Process( clk )
	Begin
		if rising_edge( clk ) then
			case estado is
				-- reset RAM register until there is a valid header
				when WAIT_START =>
					if( Header_Valid = '1' ) then
						estado							<= WAIT_END;
					end if;

				-- monitor serializer's bit pointer to ask for new data; if DMA transfer
				-- ends, go to reset state
				when WAIT_END =>
					if( DMA_In_Progress = '0' ) then
						estado							<= WAIT_START;
					end if;
			end case;
		end if;
	end Process;

	-- reset FIFO while decompression is stopped
	FSM_Reset											<= '1' when estado = WAIT_START else '0';


end Behavioral;
