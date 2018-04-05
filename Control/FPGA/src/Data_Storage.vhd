----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:26:59 03/31/2018 
-- Design Name: 
-- Module Name:    Data_Storage - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Data_Storage is
PORT(
    clk       : IN STD_LOGIC;                    --system clock
	 enable    : IN STD_LOGIC;
	 RW		  : IN STD_LOGIC;
	 input 	  : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	 address   : IN STD_LOGIC_VECTOR(7 DOWNTO 0);                  
	 output : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	 );                   
	 
end Data_Storage;


architecture Behavioral of Data_Storage is
type array_16 is array (0 to 255) of std_logic_vector (7 DOWNTO 0);
signal storage_array_signal : array_16 := ((others=> x"00"));
signal input_signal :STD_LOGIC_VECTOR(7 DOWNTO 0);
signal output_signal :STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
signal address_signal :STD_LOGIC_VECTOR(7 DOWNTO 0);

begin
process(clk,enable,RW)
begin
		if rising_edge(clk) AND RW = '1' AND enable = '1' then
			input_signal<=input;
			address_signal<=address;
				output_signal<=storage_array_signal(to_integer(unsigned(address_signal)));
			else
				 storage_array_signal(to_integer(unsigned(address)))<=input_signal;
			end if;
end process;
output<=output_signal;
end Behavioral;

