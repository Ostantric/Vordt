--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:41:23 04/07/2018
-- Design Name:   
-- Module Name:   /home/murat/Vordt/Control/FPGA/Vordt_Digital_Design/Test_bench/Decoder_Test_Bench.vhd
-- Project Name:  Vordt_Digital_Design
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
 
ENTITY Decoder_Test_Bench IS
END Decoder_Test_Bench;
 
ARCHITECTURE behavior OF Decoder_Test_Bench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Decoder
    PORT(
         CLK : IN  std_logic;
         Encoder1_A : IN  std_logic;
         Encoder1_B : IN  std_logic;
         Position : OUT  std_logic_vector(15 downto 0);
         Turn_Count : OUT  std_logic_vector(31 downto 0);
         Velocity : OUT  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal Encoder1_A : std_logic := '0';
   signal Encoder1_B : std_logic := '0';

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
          Encoder1_A => Encoder1_A,
          Encoder1_B => Encoder1_B,
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
		Encoder1_B <= '1';
		wait for Encoder_Period/2;
		Encoder1_B <= '0';
		wait for Encoder_Period/2;
		end loop;
   end process;
 
	Signal_B :process
   begin
	wait for Encoder_Period/4;
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
			--wait for 100 ns;	
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for 10000 ns;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--      	Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--      	Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--      	Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--      	Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			
--			
--						wait for 10000 ns;
--
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '0';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_B <= '1';
--			wait for Encoder_Period/4;
--			Encoder1_A <= '0';
--			wait for Encoder_Period/4;


      -- insert stimulus here 

      wait;
   end process;

END;
