----------------------------------------------------------------------------------
-- Company: Traducciones Magno
-- Engineer: Magno
--
-- Create Date: 20.03.2018 18:42:09
-- Design Name:
-- Module Name: Golomb_Decoder - Behavioral
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

entity Serializer is
	Port(	clk									: IN	STD_LOGIC;
			Rst									: IN	STD_LOGIC;
			FIFO_tready							: OUT STD_LOGIC;
			FIFO_tvalid							: IN	STD_LOGIC;
			FIFO_tdata							: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
			Shift									: IN	STD_LOGIC;
			Shift_cnt							: IN	STD_LOGIC_VECTOR(2 downto 0);
			Serial_tvalid						: OUT STD_LOGIC;
			Serial_tdata						: OUT STD_LOGIC_VECTOR(7 downto 0) );
end Serializer;


architecture Behavioral of Serializer is

	type TipoEstado									is(WAIT_START, FILL_SERIALIZER, FILL_PIPELINE_0, FILL_PIPELINE_1, CHECK_PIPELINE, SHIFT_PIPELINE);
	signal estado										: TipoEstado := WAIT_START;

	signal FSM_Fill_Serializer						: STD_LOGIC := '0';
	signal FSM_Fill_Pipeline_0						: STD_LOGIC := '0';
	signal FSM_Fill_Pipeline_1						: STD_LOGIC := '0';
	signal FSM_Shift_Pipeline						: STD_LOGIC := '0';
	signal FSM_Shift_Needed							: STD_LOGIC := '0';
	signal Pipe_Serializer							: STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
	signal Bit_Serializer							: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal Shift_Temp									: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal Bit_Ptr										: integer range 0 to 15 := 0;
	signal Bit_Ptr_Temp								: integer range 0 to 15 := 0;

begin
	-- barrel shifter
	with Shift_Cnt select
		Shift_Temp										<= Pipe_Serializer(Bit_Ptr+7 downto Bit_Ptr)											when "111",
																Pipe_Serializer(Bit_Ptr+6 downto Bit_Ptr) & Bit_Serializer(7)				when "110",
																Pipe_Serializer(Bit_Ptr+5 downto Bit_Ptr) & Bit_Serializer(7 downto 6)	when "101",
																Pipe_Serializer(Bit_Ptr+4 downto Bit_Ptr) & Bit_Serializer(7 downto 5)	when "100",
																Pipe_Serializer(Bit_Ptr+3 downto Bit_Ptr) & Bit_Serializer(7 downto 4)	when "011",
																Pipe_Serializer(Bit_Ptr+2 downto Bit_Ptr) & Bit_Serializer(7 downto 3)	when "010",
																Pipe_Serializer(Bit_Ptr+1 downto Bit_Ptr) & Bit_Serializer(7 downto 2)	when "001",
																Pipe_Serializer(Bit_Ptr) & Bit_Serializer(7 downto 1) 						when others;

	-- "Bit_Ptr" points to first pipeline bit to shift into output register
	with Shift_Cnt select
		Bit_Ptr_Temp									<= Bit_Ptr+8	when "111",
																Bit_Ptr+7	when "110",
																Bit_Ptr+6	when "101",
																Bit_Ptr+5	when "100",
																Bit_Ptr+4	when "011",
																Bit_Ptr+3	when "010",
																Bit_Ptr+2	when "001",
																Bit_Ptr+1	when others;

	-- process for pipelining data
	Process( clk )
	Begin
		if rising_edge( clk ) then
			-- initialize output register data from FIFO
			if( FSM_Fill_Serializer = '1' ) then
				Bit_Serializer(0)						<= FIFO_tdata(7);
				Bit_Serializer(1)						<= FIFO_tdata(6);
				Bit_Serializer(2)						<= FIFO_tdata(5);
				Bit_Serializer(3)						<= FIFO_tdata(4);
				Bit_Serializer(4)						<= FIFO_tdata(3);
				Bit_Serializer(5)						<= FIFO_tdata(2);
				Bit_Serializer(6)						<= FIFO_tdata(1);
				Bit_Serializer(7)						<= FIFO_tdata(0);
			-- update output register with shifted data
			elsif( Shift = '1' ) then
				Bit_Serializer							<= Shift_Temp;
			end if;

			-- initialize pipeline register
			if( FSM_Fill_Pipeline_0 = '1' ) then
				Pipe_Serializer(0)					<= FIFO_tdata(7);
				Pipe_Serializer(1)					<= FIFO_tdata(6);
				Pipe_Serializer(2)					<= FIFO_tdata(5);
				Pipe_Serializer(3)					<= FIFO_tdata(4);
				Pipe_Serializer(4)					<= FIFO_tdata(3);
				Pipe_Serializer(5)					<= FIFO_tdata(2);
				Pipe_Serializer(6)					<= FIFO_tdata(1);
				Pipe_Serializer(7)					<= FIFO_tdata(0);
				Bit_Ptr									<= 0;
			elsif( FSM_Fill_Pipeline_1 = '1' ) then
				Pipe_Serializer(8)					<= FIFO_tdata(7);
				Pipe_Serializer(9)					<= FIFO_tdata(6);
				Pipe_Serializer(10)					<= FIFO_tdata(5);
				Pipe_Serializer(11)					<= FIFO_tdata(4);
				Pipe_Serializer(12)					<= FIFO_tdata(3);
				Pipe_Serializer(13)					<= FIFO_tdata(2);
				Pipe_Serializer(14)					<= FIFO_tdata(1);
				Pipe_Serializer(15)					<= FIFO_tdata(0);
			end if;

			-- update pipeline with shifted data
			if( Shift = '1' ) then
				-- if bit pointer falls beyond first byte
				if( Bit_Ptr_Temp >= 8 ) then
					Pipe_Serializer(7 downto 0)	<= Pipe_Serializer(15 downto 8);
					Bit_Ptr								<= Bit_Ptr_Temp - 8;
				else
					Bit_Ptr								<= Bit_Ptr_Temp;
				end if;
			end if;

			-- new byte to fill shifted pipeline
			if( FSM_Shift_Pipeline = '1' ) then
				Pipe_Serializer(8)					<= FIFO_tdata(7);
				Pipe_Serializer(9)					<= FIFO_tdata(6);
				Pipe_Serializer(10)					<= FIFO_tdata(5);
				Pipe_Serializer(11)					<= FIFO_tdata(4);
				Pipe_Serializer(12)					<= FIFO_tdata(3);
				Pipe_Serializer(13)					<= FIFO_tdata(2);
				Pipe_Serializer(14)					<= FIFO_tdata(1);
				Pipe_Serializer(15)					<= FIFO_tdata(0);
			end if;
		end if;
	End Process;

	-- control FSM
	Process( clk )
	Begin
		if rising_edge( clk ) then
			if( Rst = '1' ) then
				estado									<= WAIT_START;
			else
				case estado is
					-- wait for reset to end
					when WAIT_START =>
						estado							<= FILL_SERIALIZER;

					-- begin read FIFO to fill output register
					when FILL_SERIALIZER =>
						if( FIFO_tvalid = '1' ) then
							estado						<= FILL_PIPELINE_0;
						end if;

					-- read ahead next 2 bytes
					when FILL_PIPELINE_0 =>
						if( FIFO_tvalid = '1' ) then
							estado						<= FILL_PIPELINE_1;
						end if;

					when FILL_PIPELINE_1 =>
						if( FIFO_tvalid = '1' ) then
							estado						<= CHECK_PIPELINE;
						end if;

					-- when data must be shited, read byte from FIFO
					when CHECK_PIPELINE =>
						if( FSM_Shift_Needed = '1' AND FIFO_tvalid = '0' ) then
							estado						<= SHIFT_PIPELINE;
						end if;

					-- if FIFO was empty when asked, wait until it has a byte inside
					when SHIFT_PIPELINE =>
						if( FIFO_tvalid = '1' ) then
							estado						<= CHECK_PIPELINE;
						end if;

				end case;
			end if;
		end if;
	End Process;

	-- when a shift is requested and bit pointer is going to fall beyond output register, pipelined
	-- must be shifted too
	FSM_Shift_Needed									<= '1' when Shift = '1' AND Bit_Ptr_Temp >= 8 else '0';

	-- read FIFO data
	with estado select
		FIFO_tready										<= '1'					when FILL_SERIALIZER,
																'1'					when FILL_PIPELINE_0,
																'1'					when FILL_PIPELINE_1,
																FSM_Shift_Needed	when CHECK_PIPELINE,
																'1'					when SHIFT_PIPELINE,
																'0'					when others;

	-- initialize output data
	FSM_Fill_Serializer								<= FIFO_tvalid when estado = FILL_SERIALIZER else '0';

	-- initialize pipeline data
	FSM_Fill_Pipeline_0								<= FIFO_tvalid when estado = FILL_PIPELINE_0 else '0';
	FSM_Fill_Pipeline_1								<= FIFO_tvalid when estado = FILL_PIPELINE_1 else '0';

	-- update pipeline data
	with estado select
		FSM_Shift_Pipeline							<= FIFO_tvalid AND FSM_Shift_Needed	when CHECK_PIPELINE,
																FIFO_tvalid								when SHIFT_PIPELINE,
																'0'										when others;

	-- output data ready
	with estado select
		Serial_tvalid									<= '0'	when WAIT_START,
																'0'	when FILL_SERIALIZER,
																'0'	when FILL_PIPELINE_0,
																'0'	when FILL_PIPELINE_1,
																'1'	when others;

	Serial_tdata										<= Bit_Serializer;
end Behavioral;
