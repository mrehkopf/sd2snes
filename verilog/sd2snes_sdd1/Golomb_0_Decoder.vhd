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

entity Golomb_0_Decoder is
	Port(	clk									: IN	STD_LOGIC;
			rst									: IN	STD_LOGIC;
			din_tready							: OUT	STD_LOGIC;
			din_tdata							: IN	STD_LOGIC_VECTOR(0 DOWNTO 0);
			din_tuser							: OUT	STD_LOGIC_VECTOR(2 DOWNTO 0);
			dout_tready							: IN	STD_LOGIC;
			dout_tdata							: OUT STD_LOGIC;
			dout_tlast							: OUT STD_LOGIC);
end Golomb_0_Decoder;


architecture Behavioral of Golomb_0_Decoder is

begin
	-- shift by 1 input bitstream each output bit
	din_tready									<= dout_tready;
	din_tuser									<= "000";
	-- decoded bit is input bit
	dout_tdata									<= din_tdata(0);
	-- run length is always one bit
	dout_tlast									<= '1';
end Behavioral;
