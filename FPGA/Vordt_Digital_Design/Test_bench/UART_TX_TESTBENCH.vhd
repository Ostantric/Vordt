--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:33:09 03/05/2018
-- Design Name:   
-- Module Name:   /home/murat/ISE/Vordt_Mojo_FPGA/src/UART_TX_TESTBENCH.vhd
-- Project Name:  Vordt_Mojo_FPGA
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: UART_TX
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY UART_TX_TESTBENCH IS
END UART_TX_TESTBENCH;
 
ARCHITECTURE behavior OF UART_TX_TESTBENCH IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT UART_TX
    PORT(
         i_Clk : IN  std_logic;
         i_TX_DV : IN  std_logic;
         i_TX_Byte : IN  std_logic_vector(7 downto 0);
         o_TX_Active : OUT  std_logic;
         o_TX_Serial : OUT  std_logic;
         o_TX_Done : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal i_Clk : std_logic := '0';
   signal i_TX_DV : std_logic := '0';
   signal i_TX_Byte : std_logic_vector(7 downto 0) := (others => '0');

 	--Outputs
   signal o_TX_Active : std_logic;
   signal o_TX_Serial : std_logic;
   signal o_TX_Done : std_logic;

   -- Clock period definitions
   constant i_Clk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: UART_TX PORT MAP (
          i_Clk => i_Clk,
          i_TX_DV => i_TX_DV,
          i_TX_Byte => i_TX_Byte,
          o_TX_Active => o_TX_Active,
          o_TX_Serial => o_TX_Serial,
          o_TX_Done => o_TX_Done
        );

   -- Clock process definitions
   i_Clk_process :process
   begin
		i_Clk <= '0';
		wait for i_Clk_period/2;
		i_Clk <= '1';
		wait for i_Clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		
		i_TX_Byte<= "10000000";
		
		wait for 100 ns;
		
		i_TX_DV <= '1';
		wait for 20 ns;
		i_tx_dv <='0';

      --wait for i_Clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
