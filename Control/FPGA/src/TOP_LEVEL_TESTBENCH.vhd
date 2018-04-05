--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   23:51:10 03/31/2018
-- Design Name:   
-- Module Name:   /home/murat/ISE/Vordt_Mojo_FPGA/src/TOP_LEVEL_TESTBENCH.vhd
-- Project Name:  Vordt_Mojo_FPGA
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
 
ENTITY TOP_LEVEL_TESTBENCH IS
END TOP_LEVEL_TESTBENCH;
 
ARCHITECTURE behavior OF TOP_LEVEL_TESTBENCH IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Top_level
    PORT(
         CLK : IN  std_logic;
         Encoder1_A : IN  std_logic;
         Encoder1_B : IN  std_logic;
         reset : IN  std_logic;
         Serial_TX : OUT  std_logic;
         I2C_Slave_SDA : INOUT  std_logic;
         I2C_Slave_SCL : INOUT  std_logic;
         I2C_Master_SDA : INOUT  std_logic;
         I2C_Master_SCL : INOUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal CLK : std_logic := '0';
   signal Encoder1_A : std_logic := '1';
   signal Encoder1_B : std_logic := '0';
   signal reset : std_logic := '1';

	--BiDirs
   signal sda : std_logic:='1';
   signal scl : std_logic:='1';
   signal I2C_Master_SDA : std_logic;
   signal I2C_Master_SCL : std_logic;

 	--Outputs
   signal Serial_TX : std_logic;

   -- Clock period definitions
   constant CLK_period : time := 20 ns;
	constant Encoder_Period : time := 1000 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Top_level PORT MAP (
          CLK => CLK,
          Encoder1_A => Encoder1_A,
          Encoder1_B => Encoder1_B,
          reset => reset,
          Serial_TX => Serial_TX,
          I2C_Slave_SDA => SDA,
          I2C_Slave_SCL => scl,
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
	 
		while (true) loop
		Encoder1_A <= '1';
		wait for Encoder_Period/2;
		Encoder1_A <= '0';
		wait for Encoder_Period/2;
		end loop;
   end process;
 
	Signal_B :process
   begin
	wait for Encoder_Period/4;
		while (true) loop
		Encoder1_B <= '1';
		wait for Encoder_Period/2;
		Encoder1_B <= '0';
		wait for Encoder_Period/2;
		end loop;
   end process;

   -- Stimulus process
   stim_proc: process
   begin		
		while (true) loop
      -- hold reset state for 100 ns.	
		wait for 100 ns;
		sda<='0';		
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1';  --address bit 1
		sda<='1';
		wait for 250 ns;
		scl<='0';
		sda<='0';
		wait for 250 ns;
		scl<='1'; --address bit 2
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --address bit 3
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --address bit 4
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --address bit 5
		wait for 250 ns;
		scl<='0'; 
		wait for 250 ns;
		scl<='1'; --address bit 6
		wait for 250 ns;
		scl<='0'; 
		wait for 250 ns;
		scl<='1'; --address bit 7
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --address bit 8
		sda<='0';--RW
		wait for 250 ns;
		scl<='0';
		sda<='Z';
		wait for 250 ns;
		scl<='1'; -- ack bit 9
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		sda<='1';
		scl<='1'; --memory_address bit 1
		wait for 250 ns;
		scl<='0'; 
		wait for 250 ns;
		scl<='1'; --memory_address bit 2
		wait for 250 ns;
		scl<='0';
		sda<='0';
		wait for 250 ns;
		scl<='1'; --memory_address bit 3
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --memory_address bit 4
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --memory_address bit 5
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --memory_address bit 6
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --memory_address bit 7
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --memory_address bit 8
		wait for 250 ns;
		scl<='0';
		sda<='Z';
		wait for 250 ns;
		scl<='1'; --ack bit 9
		wait for 250 ns;
		scl<='0';
		sda<='1';
		wait for 250 ns;
		scl<='1'; --data bit 1
		wait for 250 ns;
		scl<='0'; 
		sda<='0';
		wait for 250 ns;
		scl<='1'; --data bit 2
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --data bit 3
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --data bit 4
		sda<='1';
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --data bit 5
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --data bit 6
		wait for 250 ns;
		scl<='0';
		sda<='0';
		wait for 250 ns;
		scl<='1'; --data bit 7
		wait for 250 ns;
		scl<='0';
		wait for 250 ns;
		scl<='1'; --data bit 8
		wait for 250 ns;
		scl<='0';
		sda<='Z';
		wait for 250 ns;
		scl<='1'; --ack bit 9
		wait for 250 ns;
		scl<='0'; -- stop condition
		sda<='0';
		wait for 100 ns;
		sda<='0';
		wait for 250 ns;
		sda<='0';
		wait for 100 ns;
		scl<='1';
		wait for 250 ns;
		sda<='1';
     

      -- insert stimulus here 

      wait for 500ns;
		end loop;
   end process;

END;
