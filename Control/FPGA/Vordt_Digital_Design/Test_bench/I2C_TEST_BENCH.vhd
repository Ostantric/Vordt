--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   01:15:50 03/07/2018
-- Design Name:   
-- Module Name:   /home/murat/ISE/Vordt_Mojo_FPGA/src/I2C_TEST_BENCH.vhd
-- Project Name:  Vordt_Mojo_FPGA
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: I2C_Module
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
 
ENTITY I2C_TEST_BENCH IS
END I2C_TEST_BENCH;
 
ARCHITECTURE behavior OF I2C_TEST_BENCH IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT I2C_Module
    PORT(
         clk : IN  std_logic;
         reset_n : IN  std_logic;
         ena : IN  std_logic;
         addr : IN  std_logic_vector(6 downto 0);
         rw : IN  std_logic;
         data_wr : IN  std_logic_vector(7 downto 0);
         busy : OUT  std_logic;
         data_rd : OUT  std_logic_vector(7 downto 0);
         ack_error : BUFFER  std_logic;
         sda : INOUT  std_logic;
         scl : INOUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset_n : std_logic := '1';
   signal ena : std_logic := '0';
   signal addr : std_logic_vector(6 downto 0) := (others => '0');
   signal rw : std_logic := '0';
   signal data_wr : std_logic_vector(7 downto 0) := (others => '0');
   SIGNAL bit_cnt : INTEGER RANGE 0 TO 7 := 7;      --tracks bit number in transaction

	--BiDirs
   signal sda : std_logic;
   signal scl : std_logic;

 	--Outputs
   signal busy : std_logic;
   signal data_rd : std_logic_vector(7 downto 0);
   signal ack_error : std_logic;

   -- Clock period definitions
   constant clk_period : time := 20 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: I2C_Module PORT MAP (
          clk => clk,
          reset_n => reset_n,
          ena => ena,
          addr => addr,
          rw => rw,
          data_wr => data_wr,
          busy => busy,
          data_rd => data_rd,
          ack_error => ack_error,
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
	
		addr<="0001000";
		rw <= '0';
		data_wr <= "00010010";
      ena<='1';
		wait until rising_edge(busy);
		ena<='0';
		wait for 100 ns;
		wait until falling_Edge(busy);
		ena<='1';
		data_wr <= "01111110";
		wait until rising_edge(busy);
      ena<='0';

      -- insert stimulus here 

      wait;
   end process;

END;
