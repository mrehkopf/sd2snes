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
--use IEEE.NUMERIC_STD.ALL;



-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Golomb_N_Decoder is
	Generic( N									: integer);
	Port(	clk									: IN 	STD_LOGIC;
			rst									: IN	STD_LOGIC;
			din_tready							: OUT	STD_LOGIC;
			din_tdata							: IN 	STD_LOGIC_VECTOR(N DOWNTO 0);
			din_tuser							: OUT	STD_LOGIC_VECTOR(2 downto 0);
			dout_tready							: IN 	STD_LOGIC;
			dout_tdata							: OUT STD_LOGIC;
			dout_tlast							: OUT STD_LOGIC);
end Golomb_N_Decoder;


architecture Behavioral of Golomb_N_Decoder is

	signal zero_count							: integer range 0 to 2**N-1 := 0;
	signal max_count							: integer range 0 to 2**N-1 := 0;
	signal LPS_Flag							: STD_LOGIC := '0';
	signal end_bit								: STD_LOGIC := '0';
	
begin
	-- number of zero bits and tail bit
	max_count									<= 2**N - conv_integer(din_tdata(N downto 1)) - 1 when din_tdata(0) = '1' else
														2**N - 1;
	LPS_Flag										<= '0' when din_tdata(0) = '0' else '1';
	
	Process( clk )
	Begin
		if rising_edge( clk ) then
			if( rst = '1' ) then
				zero_count						<= 0;
				end_bit							<= '0';
			else
				-- each new output bit run, counter is loaded with number of consecutive zeros
				-- and input code is registered
				if( dout_tready = '1' ) then
					if( zero_count = 0 ) then
						end_bit					<= LPS_Flag;
						zero_count				<= max_count;
					else
						zero_count				<= zero_count-1;
					end if;
				end if;
			end if;
		end if;
	End Process;
	
	-- select how many input bits to shift
	Process( zero_count, dout_tready, LPS_Flag )
	Begin
		if( zero_count = 0 ) then
			din_tready							<= dout_tready;
			-- if input bit is '0', shift 1 bit, else shift N bits
			if( LPS_Flag = '0' ) then
				din_tuser						<= "000";
			else
				din_tuser						<= conv_std_logic_vector(N, 3);
			end if;
		else 
			din_tready							<= '0';
			din_tuser							<= "000";
		end if;
	End Process;
	
	
	-- select output data depending on run counter
	Process( zero_count, max_count, end_bit )
	Begin
		-- new input code must be read to generate run
		if( zero_count = 0 ) then
			if( max_count = 0 ) then
				dout_tdata						<= '1';
				dout_tlast						<= '1';
			else
				dout_tdata						<= '0';
				dout_tlast						<= '0';
			end if;
		elsif( zero_count = 1 ) then
			dout_tdata							<= end_bit;
			dout_tlast							<= '1';
		else
			dout_tdata							<= '0';
			dout_tlast							<= '0';						
		end if; 
	End Process;
	
end Behavioral;
