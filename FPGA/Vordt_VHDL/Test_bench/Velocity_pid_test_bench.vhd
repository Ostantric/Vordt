--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   00:34:54 05/18/2018
-- Design Name:   
-- Module Name:   /home/murat/Project_Vordt/Digital_Design/FPGA/Vordt_VHDL/Test_bench/Velocity_pid_test_bench.vhd
-- Project Name:  Vordt_VHDL
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Velocity_PID_Controller
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
 
ENTITY Velocity_pid_test_bench IS
END Velocity_pid_test_bench;
 
ARCHITECTURE behavior OF Velocity_pid_test_bench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Velocity_PID_Controller
    PORT(
         CLK : IN  std_logic;
         reset_n : IN  std_logic;
         Set_point : IN  std_logic_vector(15 downto 0);
         Feedback : IN  std_logic_vector(15 downto 0);
         Output_Command : BUFFER  std_logic_vector(7 downto 0);
         Motor_Number : IN  std_logic;
         Direction_Command : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal reset_n : std_logic := '1';
   signal Set_point : std_logic_vector(15 downto 0) := (others => '0');
   signal Feedback : std_logic_vector(15 downto 0) := (others => '0');
   signal Motor_Number : std_logic := '0';

 	--Outputs
   signal Output_Command : std_logic_vector(7 downto 0);
   signal Direction_Command : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant CLK_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Velocity_PID_Controller PORT MAP (
          CLK => CLK,
          reset_n => reset_n,
          Set_point => Set_point,
          Feedback => Feedback,
          Output_Command => Output_Command,
          Motor_Number => Motor_Number,
          Direction_Command => Direction_Command
        );

   -- Clock process definitions
   CLK_process :process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		Set_point<=x"FFA0";
		--Feedback<=x"00";
      wait for 100 ns;	
		
      wait for CLK_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
