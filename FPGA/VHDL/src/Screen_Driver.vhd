----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:33:22 03/20/2018 
-- Design Name: 
-- Module Name:    Screen_Driver - Behavioral 
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
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Screen_Driver is
PORT (
		--in
		CLK : IN STD_LOGIC;
		SPI_Busy : IN STD_LOGIC;
		Velocity_Input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		Turn_Count_Input : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		Position_Input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		--out
		enable  : OUT STD_LOGIC;
		cpol    : OUT STD_LOGIC;  
      cpha    : OUT STD_LOGIC;
		Continuous_Operation : OUT STD_LOGIC;
		Slave_Select : OUT INTEGER;
		Clock_Divide : OUT INTEGER;
		Command_Or_Data : OUT STD_LOGIC;
		Data_to_Write : STD_LOGIC_VECTOR(7 DOWNTO 0)
	
		);
end Screen_Driver;

architecture Behavioral of Screen_Driver is
	type States is (Idle, Start_Display, Set_Rotation, draw_names, update_Position, update_Count, update_Velocity );
	signal State_Machine : States := Idle;
	signal busy_old : STD_logic;
	signal busy_count : integer range 0 to 21 := 0 ;
begin

process (CLK)
begin
	if rising_edge(CLK) then
		busy_old<=spi_busy;
			if (busy_old = '1' AND spi_busy = '0') then
				 busy_count<=busy_count+1;
			end if;
		case State_Machine is
			When idle =>
					cpha <= '0';
					cpol <= '0';
					Continuous_Operation <= '0';
					Slave_Select <= 0;
					Clock_Divide <= 2;
					State_Machine<=Start_Display;
			When Start_Display =>
					Command_Or_Data<='0';
					
			When Set_Rotation =>
			
			When Draw_Names =>
end case;
end if;
end process;
end Behavioral;

