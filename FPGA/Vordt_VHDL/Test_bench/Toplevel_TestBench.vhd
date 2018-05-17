--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:24:58 04/29/2018
-- Design Name:   
-- Module Name:   /home/murat/Project_Vordt/Digital_Design/FPGA/Vordt_VHDL/Test_bench/Toplevel_TestBench.vhd
-- Project Name:  Vordt_VHDL
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Top_level
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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY Toplevel_TestBench IS
END Toplevel_TestBench;
 
ARCHITECTURE behavior OF Toplevel_TestBench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Top_level
    PORT(
         CLK : IN  std_logic;
         Encoder1_A : IN  std_logic;
         Encoder1_B : IN  std_logic;
         Encoder2_A : IN  std_logic;
         Encoder2_B : IN  std_logic;
         reset : IN  std_logic;
         Sabertooth_Serial_TX : OUT  std_logic;
         MCU_Serial_TX : OUT  std_logic;
         MCU_Serial_RX : IN  std_logic;
         MCU_Ready_For_UART_TX : IN  std_logic;
         I2C_Master_SDA : INOUT  std_logic;
         I2C_Master_SCL : INOUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal Encoder1_A : std_logic := '1';
   signal Encoder1_B : std_logic := '0';
   signal Encoder2_A : std_logic := '0';
   signal Encoder2_B : std_logic := '0';
   signal reset : std_logic := '1';
   signal MCU_Serial_RX : std_logic := '0';
   signal MCU_Ready_For_UART_TX : std_logic := '0';

	--BiDirs
   signal I2C_Master_SDA : std_logic;
   signal I2C_Master_SCL : std_logic;

 	--Outputs
   signal Sabertooth_Serial_TX : std_logic;
   signal MCU_Serial_TX : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 20 ns;
 	constant Encoder_Period : time := 1000 ns;

BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Top_level PORT MAP (
          CLK => CLK,
          Encoder1_A => Encoder1_A,
          Encoder1_B => Encoder1_B,
          Encoder2_A => Encoder2_A,
          Encoder2_B => Encoder2_B,
          reset => reset,
          Sabertooth_Serial_TX => Sabertooth_Serial_TX,
          MCU_Serial_TX => MCU_Serial_TX,
          MCU_Serial_RX => MCU_Serial_RX,
          MCU_Ready_For_UART_TX => MCU_Ready_For_UART_TX,
          I2C_Master_SDA => I2C_Master_SDA,
          I2C_Master_SCL => I2C_Master_SCL
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
	
	Signal_A :process
   begin
	   wait for Encoder_Period/4;

		while (true) loop
		Encoder1_B <= '1';
		wait for Encoder_Period/2;
		Encoder1_B <= '0';
		wait for Encoder_Period/2;
		end loop;
   end process;
 
	Signal_B :process
   begin
		while (true) loop
		Encoder1_A <= '1';
		wait for Encoder_Period/2;
		Encoder1_A <= '0';
		wait for Encoder_Period/2;
		end loop;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for CLK_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
