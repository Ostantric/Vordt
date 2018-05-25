--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:14:24 05/17/2018
-- Design Name:   
-- Module Name:   /home/murat/Project_Vordt/Digital_Design/FPGA/Vordt_VHDL/Test_bench/Decoder_Test_Bench_updated.vhd
-- Project Name:  Vordt_VHDL
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Decoder
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
 
ENTITY Decoder_Test_Bench_updated IS
END Decoder_Test_Bench_updated;
 
ARCHITECTURE behavior OF Decoder_Test_Bench_updated IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Decoder
    PORT(
         CLK : IN  std_logic;
         Reset : IN  std_logic;
         Encoder_A : IN  std_logic;
         Encoder_B : IN  std_logic;
         Position : OUT  std_logic_vector(15 downto 0);
         Turn_Count : OUT  std_logic_vector(31 downto 0);
         Velocity : OUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal Reset : std_logic := '1';
   signal Encoder_A : std_logic := '1';
   signal Encoder_B : std_logic := '0';

 	--Outputs
   signal Position : std_logic_vector(15 downto 0);
   signal Turn_Count : std_logic_vector(31 downto 0);
   signal Velocity : std_logic_vector(15 downto 0);

   -- Clock period definitions
   constant CLK_period : time := 20 ns;
	constant Encoder_Period : time := 1000 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Decoder PORT MAP (
          CLK => CLK,
          Reset => Reset,
          Encoder_A => Encoder_A,
          Encoder_B => Encoder_B,
          Position => Position,
          Turn_Count => Turn_Count,
          Velocity => Velocity
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
	 
		while (true) loop
		Encoder_B <= '1';
		wait for Encoder_Period/2;
		Encoder_B <= '0';
		wait for Encoder_Period/2;
		end loop;
   end process;
 
	Signal_B :process
   begin
	wait for Encoder_Period/4;
		while (true) loop
		Encoder_A <= '1';
		wait for Encoder_Period/2;
		Encoder_A <= '0';
		wait for Encoder_Period/2;
		end loop;
   end process;

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 1000 ns;	
		reset<='0';
      wait for CLK_period*1000;
		reset<='1';
      -- insert stimulus here 

      wait;
   end process;

END;
