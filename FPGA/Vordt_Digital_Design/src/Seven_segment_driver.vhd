----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    00:25:12 03/02/2018 
-- Design Name: 
-- Module Name:    Seven_segment_driver - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Seven_segment_driver is
 Port (clk:  in  std_logic;
		 input : in std_logic_vector(15 downto 0);
       seg: out std_logic_vector(6 downto 0);
		 led: out std_logic_Vector(7 downto 0);
       an:  out std_logic_vector(3 downto 0)
		 );

end Seven_segment_driver;

architecture Behavioral of Seven_segment_driver is

signal one_second_counter: STD_LOGIC_VECTOR (27 downto 0) :=(others => '0');
signal displayed_number: STD_LOGIC_VECTOR (15 downto 0);
signal LED_BCD: STD_LOGIC_VECTOR (3 downto 0);
signal refresh_counter: STD_LOGIC_VECTOR (19 downto 0) :=(others => '0');
signal LED_activating_counter: std_logic_vector(1 downto 0) :=(others => '0');
begin
led <= input (7 downto 0);
displayed_number<=input;
process(LED_BCD)
begin
    case LED_BCD is
    when "0000" => seg <= "1000000"; -- "0"     
    when "0001" => seg <= "1111001"; -- "1" 
    when "0010" => seg <= "0100100"; -- "2" 
    when "0011" => seg <= "0110000"; -- "3" 
    when "0100" => seg <= "0011001"; -- "4" 
    when "0101" => seg <= "0010010"; -- "5" 
    when "0110" => seg <= "0000010"; -- "6" 
    when "0111" => seg <= "1111000"; -- "7" 
    when "1000" => seg <= "0000000"; -- "8"     
    when "1001" => seg <= "0010000"; -- "9" 
    when "1010" => seg <= "0001000"; -- a
    when "1011" => seg <= "0000011"; -- b
    when "1100" => seg <= "1000110"; -- C
    when "1101" => seg <= "0100001"; -- d
    when "1110" => seg <= "0000110"; -- E
    when "1111" => seg <= "0001110"; -- F
	 when others => seg <= "XXXXXXX";
    end case;
end process;

process(clk)
begin 
    if rising_edge(clk) then
        refresh_counter <= refresh_counter + 1;
    end if;
end process;
LED_activating_counter <= refresh_counter(19 downto 18);

process(LED_activating_counter,displayed_number)
begin
    case LED_activating_counter is
    when "00" =>
        an <= "0111"; 
        -- activate LED1 and Deactivate LED2, LED3, LED4
        LED_BCD <= displayed_number(15 downto 12);
        -- the first hex digit of the 16-bit number
    when "01" =>
        an <= "1011"; 
        -- activate LED2 and Deactivate LED1, LED3, LED4
        LED_BCD <= displayed_number(11 downto 8);
        -- the second hex digit of the 16-bit number
    when "10" =>
        an <= "1101"; 
        -- activate LED3 and Deactivate LED2, LED1, LED4
        LED_BCD <= displayed_number(7 downto 4);
        -- the third hex digit of the 16-bit number
    when "11" =>
        an <= "1110"; 
        -- activate LED4 and Deactivate LED2, LED3, LED1
        LED_BCD <= displayed_number(3 downto 0);
        -- the fourth hex digit of the 16-bit number   
	 when others => an <= "XXXX";
    end case;
end process;

process(clk)
begin
        if rising_edge(clk) then
            if(one_second_counter>=x"5F5E0FF") then --99,999,999 in hex
                one_second_counter <= (others => '0');
            else
                one_second_counter <= one_second_counter + "0000001";
            end if;
        end if;
end process;


end Behavioral;







--signal cntDiv: std_logic_vector(28 downto 0); -- general clock div/cnt
--alias cntDisp: std_logic_vector(3 downto 0) is cntDiv(28 downto 25);
--begin
--ckDivider: process(clk)
--  begin
--    if clk'event and clk='1' then
--      cntDiv <= cntDiv + '1';
--    end if;
--  end process;
--  
----with cntDisp SELect
----   seg<= "1111001" when "0001",   --1
----         "0100100" when "0010",   --2
----         "0110000" when "0011",   --3
----         "0011001" when "0100",   --4
----         "0010010" when "0101",   --5
----         "0000010" when "0110",   --6
----         "1111000" when "0111",   --7
----         "0000000" when "1000",   --8
----         "0010000" when "1001",   --9
----         "0001000" when "1010",   --A
----         "0000011" when "1011",   --b
----         "1000110" when "1100",   --C
----         "0100001" when "1101",   --d
----         "0000110" when "1110",   --E
----         "0001110" when "1111",   --F
----         "1000000" when others;   --0
--seg<= position(6 downto 0);
--
-- an <= "1110";  -- released buttons turn coresponding digits ON			
--end Behavioral;

