----------------------------------------------------------------------------------
-- Company: Traducciones Magno
-- Engineer: Magno
-- 
-- Create Date: 18.03.2018 20:49:09
-- Design Name: 
-- Module Name: FIFO_Input - Behavioral
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

entity FIFO_B2B is
	Generic( FIFO_DEPTH						: integer := 32;
				PROG_FULL_TH					: integer := 16);
	Port(	clk									: IN 	STD_LOGIC;
   		srst 									: IN 	STD_LOGIC;
			din_tready							: OUT	STD_LOGIC;
   		din_tvalid							: IN 	STD_LOGIC;
   		din_tdata 							: IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);
    		dout_tready							: IN 	STD_LOGIC;
    		dout_tvalid							: OUT STD_LOGIC;
    		dout_tdata							: OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    		full									: OUT STD_LOGIC;
    		empty									: OUT STD_LOGIC;
			prog_full							: OUT	STD_LOGIC );
end FIFO_B2B;


architecture Behavioral of FIFO_B2B is

	type FIFO_Array_t							is array(FIFO_DEPTH-1 downto 0) of STD_LOGIC_VECTOR(7 downto 0);
	signal FIFO_Array							: FIFO_Array_t := (others => (others => '0'));
	signal wr_ptr								: integer range 0 to FIFO_DEPTH-1 := 0;
	signal rd_ptr								: integer range 0 to FIFO_DEPTH-1 := 0;
	signal data_cnt							: integer range 0 to FIFO_DEPTH := 0;
	
	signal din_tready_i						: STD_LOGIC := '0';
	signal dout_tvalid_i						: STD_LOGIC := '0';
	
begin

	Process( clk )
	Begin
		if rising_edge( clk ) then
			if( srst = '1' ) then
				FIFO_Array						<= (others => (others => '0'));
				wr_ptr							<= 0;
				rd_ptr							<= 0;
				data_cnt							<= 0;
			else
				-- write command
				if( din_tready_i = '1' AND din_tvalid = '1' ) then
					-- write data to array
					FIFO_Array(wr_ptr)			<= din_tdata;
						
					-- check write pointer limits
					if( wr_ptr = (FIFO_DEPTH-1) ) then
						wr_ptr					<= 0;
					else
						wr_ptr					<= wr_ptr + 1;
					end if;
				end if;
	
				-- read command
				if( dout_tready = '1' AND dout_tvalid_i = '1' ) then			
					-- check read pointer limits
					if( rd_ptr = (FIFO_DEPTH-1) ) then
						rd_ptr					<= 0;
					else
						rd_ptr					<= rd_ptr + 1;
					end if;
				end if;
				
				-- occupancy control
				-- write only
				if((din_tready_i = '1' AND din_tvalid = '1') AND
					(dout_tready = '0' OR dout_tvalid_i = '0')) then
					data_cnt						<= data_cnt + 1;
				-- read only
				elsif((din_tready_i = '0' OR din_tvalid = '0') AND
						(dout_tready = '1' AND dout_tvalid_i = '1')) then
					data_cnt						<= data_cnt - 1;
				end if;
			end if;
		end if;
	End Process;
	
	-- first word fall-through
	dout_tdata									<= FIFO_Array(rd_ptr);
	dout_tvalid_i								<= '0' when (data_cnt = 0 OR srst = '1') else '1';
	dout_tvalid									<= dout_tvalid_i;

	-- flow control signals
	empty											<= '1' when data_cnt = 0 else '0';
	full											<= NOT din_tready_i;
	prog_full									<= '1' when (data_cnt >= PROG_FULL_TH OR srst = '1') 	else '0';
	
	din_tready_i								<= '0' when (data_cnt > (FIFO_DEPTH-1) OR srst = '1') else '1';
	din_tready									<= din_tready_i;
	
end Behavioral;
