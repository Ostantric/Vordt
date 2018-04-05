--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:53:40 03/31/2018
-- Design Name:   
-- Module Name:   /home/murat/ISE/Vordt_Mojo_FPGA/src/I2C_Slave_TESTBENCH.vhd
-- Project Name:  Vordt_Mojo_FPGA
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: I2C_Slave_Module
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
 
ENTITY I2C_Slave_TESTBENCH IS
END I2C_Slave_TESTBENCH;
 
ARCHITECTURE behavior OF I2C_Slave_TESTBENCH IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT I2C_Slave_Module
    PORT(
         clk : IN  std_logic;
         busy : OUT  std_logic;
         send_done : OUT  std_logic;
         save_done : OUT  std_logic;
         listen_address_received : OUT  std_logic;
         talk_address_received : OUT  std_logic;
         data_to_send : IN  std_logic_vector(7 downto 0);
         data_to_save : OUT  std_logic_vector(7 downto 0);
         listen_address : OUT  std_logic_vector(7 downto 0);
         talk_address : OUT  std_logic_vector(7 downto 0);
         sda : INOUT  std_logic;
         scl : INOUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal data_to_send : std_logic_vector(7 downto 0) := (others => '0');

	--BiDirs
   signal sda : std_logic := '1';
   signal scl : std_logic := '1';

 	--Outputs
   signal busy : std_logic;
   signal send_done : std_logic;
   signal save_done : std_logic;
   signal listen_address_received : std_logic;
   signal talk_address_received : std_logic;
   signal data_to_save : std_logic_vector(7 downto 0);
   signal listen_address : std_logic_vector(7 downto 0);
   signal talk_address : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: I2C_Slave_Module PORT MAP (
          clk => clk,
          busy => busy,
          send_done => send_done,
          save_done => save_done,
          listen_address_received => listen_address_received,
          talk_address_received => talk_address_received,
          data_to_send => data_to_send,
          data_to_save => data_to_save,
          listen_address => listen_address,
          talk_address => talk_address,
          sda => sda,
          scl => scl
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
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
		wait for 100 ns;
		sda<='1';
		wait for 250 ns;
		sda<='0';
		wait for 250 ns;
		sda<='1';
		wait for 250 ns;
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
		wait for 100 ns;
		sda<='1';
		wait for 250 ns;
		sda<='0';
		wait for 250 ns;
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
      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
