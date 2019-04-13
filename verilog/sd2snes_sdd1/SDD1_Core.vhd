----------------------------------------------------------------------------------
-- Company: Traducciones Magno
-- Engineer: Magno
--
-- Create Date: 22.03.2018 20:46:09
-- Design Name:
-- Module Name: SDD1_Core - Behavioral
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

entity SDD1_Core is
		Port(	clk 									: in 	STD_LOGIC;
				-- configuration received from DMA
				DMA_Conf_Valid						: in	STD_LOGIC;
				DMA_Transfer_End					: in	STD_LOGIC;
				-- data input from ROM
				ROM_Data_tready 					: out STD_LOGIC;
				ROM_Data_tvalid					: in 	STD_LOGIC;
				ROM_Data_tdata						: in 	STD_LOGIC_VECTOR(15 downto 0);
				ROM_Data_tkeep						: in 	STD_LOGIC_VECTOR(1 downto 0);
				-- data output to DMA
				DMA_Data_tready					: in 	STD_LOGIC;
				DMA_Data_tvalid					: out STD_LOGIC;
				DMA_Data_tdata						: out STD_LOGIC_VECTOR(7 downto 0);
				-- DBG
				FSM_Avoid_Collision				: in 	STD_LOGIC;
				FSM_Start_Decompression			: in 	STD_LOGIC;
				FSM_End_Decompression			: in 	STD_LOGIC;
				ROM_CE								: in	STD_LOGIC;
				ROM_ADDR								: in	STD_LOGIC_VECTOR(21 downto 0);
				ROM_DATA								: in	STD_LOGIC_VECTOR(15 downto 0));
end SDD1_Core;


architecture Behavioral of SDD1_Core is

	COMPONENT Input_Manager
		Port(	clk 									: in 	STD_LOGIC;
				-- control data
				DMA_Conf_Valid						: in	STD_LOGIC;
				DMA_In_Progress					: in	STD_LOGIC;
				Header_Valid						: out	STD_LOGIC;
				Header_BPP							: out	STD_LOGIC_VECTOR(1 downto 0);
				Header_Context						: out	STD_LOGIC_VECTOR(1 downto 0);
				-- data input from ROM
				ROM_Data_tready 					: out STD_LOGIC;
				ROM_Data_tvalid					: in 	STD_LOGIC;
				ROM_Data_tdata						: in 	STD_LOGIC_VECTOR(15 downto 0);
				ROM_Data_tkeep						: in 	STD_LOGIC_VECTOR(1 downto 0);
				-- Golomb decoded value
				Decoded_Bit_tready				: in 	STD_LOGIC;
				Decoded_Bit_tuser					: in 	STD_LOGIC_VECTOR(7 downto 0);
				Decoded_Bit_tvalid				: out STD_LOGIC;
				Decoded_Bit_tdata					: out STD_LOGIC;
				Decoded_Bit_tlast					: out STD_LOGIC;
				--DEBUG
				ROM_CE								: in	STD_LOGIC;
				ROM_ADDR								: in	STD_LOGIC_VECTOR(21 downto 0);
				ROM_DATA								: in	STD_LOGIC_VECTOR(15 downto 0));
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
				Decoded_Bit_tvalid				: in 	STD_LOGIC;
				Decoded_Bit_tdata					: in 	STD_LOGIC;
				Decoded_Bit_tlast					: in 	STD_LOGIC;
				-- estimated bit value
				BPP_Bit_tready						: in 	STD_LOGIC;
				BPP_Bit_tuser						: in 	STD_LOGIC_VECTOR(9 downto 0);
				BPP_Bit_tvalid						: out	STD_LOGIC;
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

	signal DBG_Cnt									: STD_LOGIC_VECTOR(17 downto 0) := (others => '0');

begin
	-- get data from ROM and decode it into N-order Golomb runs
	IM : Input_Manager
		Port map(clk 								=> clk,
					-- control data
					DMA_Conf_Valid					=> DMA_Conf_Valid,
					DMA_In_Progress				=> DMA_In_Progress,
					Header_Valid					=> Header_Valid,
					Header_BPP						=> Header_BPP,
					Header_Context					=> Header_Context,
					-- data input from ROM
					ROM_Data_tready 				=> ROM_Data_tready,
					ROM_Data_tvalid				=> ROM_Data_tvalid,
					ROM_Data_tdata					=> ROM_Data_tdata,
					ROM_Data_tkeep					=> ROM_Data_tkeep,
					-- Golomb decoded value
					Decoded_Bit_tready			=> Decoded_Bit_tready,
					Decoded_Bit_tuser				=> Decoded_Bit_tuser,
					Decoded_Bit_tvalid			=> Decoded_Bit_tvalid,
					Decoded_Bit_tdata				=> Decoded_Bit_tdata,
					Decoded_Bit_tlast				=> Decoded_Bit_tlast,
					ROM_CE							=> ROM_CE,
					ROM_ADDR							=> ROM_ADDR,
					ROM_DATA							=> ROM_DATA  );


	-- get Golomb data and context to decode pixel
	PE : Probability_Estimator
		Port map(clk 								=> clk,
					-- control data
					DMA_In_Progress				=> DMA_In_Progress,
					Header_Valid					=> Header_Valid,
					Header_Context					=> Header_Context,
					-- run data from input manager
					Decoded_Bit_tready 			=> Decoded_Bit_tready,
					Decoded_Bit_tuser				=> Decoded_Bit_tuser,
					Decoded_Bit_tvalid			=> Decoded_Bit_tvalid,
					Decoded_Bit_tdata				=> Decoded_Bit_tdata,
					Decoded_Bit_tlast				=> Decoded_Bit_tlast,
					-- estimated bit value
					BPP_Bit_tready					=> BPP_Bit_tready,
					BPP_Bit_tuser					=> BPP_Bit_tuser,
					BPP_Bit_tvalid					=> BPP_Bit_tvalid,
					BPP_Bit_tdata					=> BPP_Bit_tdata );


	OM : Output_Manager
		Port map(clk 								=> clk,
					-- configuration received from DMA
					DMA_In_Progress				=> DMA_In_Progress,
					DMA_Transfer_End				=> DMA_Transfer_End,
					Header_Valid					=> Header_Valid,
					Header_BPP						=> Header_BPP,
					-- data input from Probability Estimator
					BPP_Bit_tready					=> BPP_Bit_tready,
					BPP_Bit_tuser					=> BPP_Bit_tuser,
					BPP_Bit_tvalid					=> BPP_Bit_tvalid,
					BPP_Bit_tdata					=> BPP_Bit_tdata,
					-- data output to DMA
					DMA_Data_tready				=> DMA_Data_tready,
					DMA_Data_tvalid				=> DMA_Data_tvalid,
					DMA_Data_tdata					=> DMA_Data_tdata );
end Behavioral;
