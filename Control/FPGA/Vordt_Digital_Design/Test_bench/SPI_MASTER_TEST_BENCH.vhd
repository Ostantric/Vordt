--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:14:40 03/19/2018
-- Design Name:   
-- Module Name:   /home/murat/ISE/Vordt_Mojo_FPGA/src/SPI_MASTER_TEST_BENCH.vhd
-- Project Name:  Vordt_Mojo_FPGA
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: SPI_Master
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
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY SPI_MASTER_TEST_BENCH IS
END SPI_MASTER_TEST_BENCH;
 
ARCHITECTURE behavior OF SPI_MASTER_TEST_BENCH IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT SPI_Master
    PORT(
         clock : IN  std_logic;
         reset_n : IN  std_logic;
         enable : IN  std_logic;
         cpol : IN  std_logic;
         cpha : IN  std_logic;
         cont : IN  std_logic;
         clk_div : IN  integer;
         addr : IN  integer;
         tx_data : IN  std_logic_vector(7 downto 0);
         miso : IN  std_logic;
         sclk : BUFFER  std_logic;
         ss_n : BUFFER  std_logic_vector(3 downto 0);
         mosi : OUT  std_logic;
         busy : OUT  std_logic;
         rx_data : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clock : std_logic := '0';
   signal reset_n : std_logic := '0';
   signal enable : std_logic := '1';
   signal cpol : std_logic := '0';
   signal cpha : std_logic := '0';
   signal cont : std_logic := '0';
   signal clk_div : integer := 10;
   signal addr : integer := 0;
   signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
   signal miso : std_logic := '0';

 	--Outputs
   signal sclk : std_logic;
   signal ss_n : std_logic_vector(3 downto 0);
   signal mosi : std_logic;
   signal busy : std_logic;
   signal rx_data : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clock_period : time := 20 ns;
--   constant clk_div_period : time := 10 ns;
--   constant sclk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: SPI_Master PORT MAP (
          clock => clock,
          reset_n => reset_n,
          enable => enable,
          cpol => cpol,
          cpha => cpha,
          cont => cont,
          clk_div => clk_div,
          addr => addr,
          tx_data => tx_data,
          miso => miso,
          sclk => sclk,
          ss_n => ss_n,
          mosi => mosi,
          busy => busy,
          rx_data => rx_data
        );

   -- Clock process definitions
   clock_process :process
   begin
		clock <= '0';
		wait for clock_period/2;
		clock <= '1';
		wait for clock_period/2;
   end process;
 
--   clk_div_process :process
--   begin
--		clk_div <= '0';
--		wait for clk_div_period/2;
--		clk_div <= '1';
--		wait for clk_div_period/2;
--   end process;
-- 
--   sclk_process :process
--   begin
--		sclk <= '0';
--		wait for sclk_period/2;
--		sclk <= '1';
--		wait for sclk_period/2;
--   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	
		reset_n<='1';
		tx_data<=x"AB";
		wait for 50 ns;
		cont<='1';
		tx_data<=x"CD";
		wait for 50 ns;
		--enable<='0';
		--tx_data<=x"EF";
      wait for clock_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
