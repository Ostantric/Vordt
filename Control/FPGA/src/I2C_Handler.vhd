----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:13:19 03/07/2018 
-- Design Name: 
-- Module Name:    I2C_Handler - Behavioral 
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
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity I2C_Handler is
	PORT(
    clk       : IN STD_LOGIC;                    --system clock
	 reset 	  : IN STD_LOGIC;
	 --FOR BOTH MODULES
	 velocity_input  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);		
	 position_input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	 turn_input : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	 PID_Velocity_Input : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 PID_Position_Input  : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 storage_input : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 ----MASTER Module
	 busy : IN STD_LOGIC;
	 slave_address : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	 Data_for_write : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	 enable_I2C_Module : OUT STD_LOGIC :='0';
	 read_write_signal : OUT STD_LOGIC
	 ----SLAVE Module
		--DATA_STORAGE stuff
	 --address_for_storage : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	 --data_for_storage : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	 --data_from_storage : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	 --enable_storage : OUT STD_LOGIC;
	 --RW_storage : OUT STD_LOGIC; 
		--I2C stuff
	 --slave_module_busy : IN STD_LOGIC;
	 --send_done : IN STD_LOGIC;
	 --save_done : IN STD_LOGIC;
	 --listen_address_came : IN STD_LOGIC;
	 --talk_address_came : IN STD_LOGIC;
	 --listen_address : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	 --talk_address : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	 --data_for_sending : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	 --data_for_saving : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
	 );
	 
end I2C_Handler;

architecture Behavioral of I2C_Handler is
	type States is (Idle, Start_7Display1, Start_7Display2, Start_7Display3, 
	Start_7Display4, Start_7Display5, Start_7Display6, Velocity, Position, Turn, 
	PID_Velocity_OUTPUT, PID_Position_OUTPUT, Storage );
	signal State_Machine : States := Idle;
	signal Command_count : integer range 0 to 4 := 0;
	signal busy_count : integer range 0 to 21 := 0 ;
	signal busy_old : std_logic;
	signal Convert_Digit : STD_LOGIC_VECTOR(7 Downto 0);
	signal divide_4bits : STD_LOGIC_Vector(3 downto 0);
	signal count : integer range 0 to 1000000 :=0;
	signal listen_address_signal :STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal data_for_saving_signal :STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal save : std_logic := '0';
	signal enable_storage_signal : std_logic := '0';
	signal rw_storage_signal : std_logic := '0';
	
begin

process(divide_4bits)
begin
    case divide_4bits is
    when "0000" => Convert_Digit <= x"3F"; -- "0"     
    when "0001" => Convert_Digit <= x"06"; -- "1" 
    when "0010" => Convert_Digit <= x"5B"; -- "2" 
    when "0011" => Convert_Digit <= x"4F"; -- "3" 
    when "0100" => Convert_Digit <= x"66"; -- "4" 
    when "0101" => Convert_Digit <= x"6D"; -- "5" 
    when "0110" => Convert_Digit <= x"7D"; -- "6" 
    when "0111" => Convert_Digit <= x"07"; -- "7" 
    when "1000" => Convert_Digit <= x"7F"; -- "8"     
    when "1001" => Convert_Digit <= x"6F"; -- "9" 
    when "1010" => Convert_Digit <= x"77"; -- a
    when "1011" => Convert_Digit <= x"7C"; -- b
    when "1100" => Convert_Digit <= x"39"; -- C
    when "1101" => Convert_Digit <= x"5E"; -- d
    when "1110" => Convert_Digit <= x"79"; -- E
    when "1111" => Convert_Digit <= x"71"; -- F
	 when others => Convert_Digit <= x"3F";
    end case;
end process;

--process(clk)
--begin
--	if rising_edge(clk) then
--    case divide_4bits is
--    when "0000" => Convert_Digit <= x"3F"; -- "0"     
--    when "0001" => Convert_Digit <= x"06"; -- "1" 
--    when "0010" => Convert_Digit <= x"5B"; -- "2" 
--    when "0011" => Convert_Digit <= x"4F"; -- "3" 
--    when "0100" => Convert_Digit <= x"66"; -- "4" 
--    when "0101" => Convert_Digit <= x"6D"; -- "5" 
--    when "0110" => Convert_Digit <= x"7D"; -- "6" 
--    when "0111" => Convert_Digit <= x"07"; -- "7" 
--    when "1000" => Convert_Digit <= x"7F"; -- "8"     
--    when "1001" => Convert_Digit <= x"6F"; -- "9" 
--    when "1010" => Convert_Digit <= x"77"; -- a
--    when "1011" => Convert_Digit <= x"7C"; -- b
--    when "1100" => Convert_Digit <= x"39"; -- C
--    when "1101" => Convert_Digit <= x"5E"; -- d
--    when "1110" => Convert_Digit <= x"79"; -- E
--    when "1111" => Convert_Digit <= x"71"; -- F
--	 when others => Convert_Digit <= x"3F";
--    end case;
--	end if;
--end process;


read_write_signal<='0';
--PROCESS FOR MASTER MODULE
process (CLK)
begin
	if rising_edge(CLK) then
		busy_old<=busy;
		count<=count+1;
			if (busy_old = '1' AND busy = '0') THEN  --i2c busy just went high
				busy_count<=busy_count+1;
			end if;
			
		case State_Machine is
			when idle =>
					State_Machine<=Start_7Display1;
			when Start_7Display1 =>
					slave_address<= "1110000"; --70
					case busy_count is
						when 0 TO 1=> -- turn on osscilator
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"21";
						when 2 TO 3=> -- display on and blinkrate
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"E1"; --Brightness level = 1
							if (busy_old = '1' AND busy = '0') then
								if(busy_count>4) then
								busy_count<=0;
								State_Machine<=Start_7Display2;
								end if;
							end if;
						when others => NULL;
					end case;
					
			when Start_7Display2 =>
					slave_address<= "1110001"; --71	
					case busy_count is
						when 0 To 1=> -- turn on osscilator
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"E1"; --Brightness level = 1
							if (busy_old = '1' AND busy = '0') then
								busy_count<=0;
								State_Machine<=Start_7Display3;
							end if;
						when others => NULL;
					end case;
					
			when Start_7Display3 =>
					slave_address<= "1110010"; --72	
					case busy_count is
						when 0 To 1=> -- turn on osscilator
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"E1"; --Brightness level = 1
							if (busy_old = '1' AND busy = '0') then
								busy_count<=0;
								State_Machine<=Start_7Display4;
							end if;
						when others => NULL;
					end case;
					
				when Start_7Display4 =>
					slave_address<= "1110011"; --73	
					case busy_count is
						when 0 To 1=> -- turn on osscilator
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"E1"; --Brightness level = 1
							if (busy_old = '1' AND busy = '0') then
								busy_count<=0;
								State_Machine<=Start_7Display5;
							end if;
						when others => NULL;
					end case;
					
				when Start_7Display5 =>
					slave_address<= "1110100"; --74	
					case busy_count is
						when 0 To 1=> -- turn on osscilator
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"E1"; --Brightness level = 1
							if (busy_old = '1' AND busy = '0') then
								busy_count<=0;
								State_Machine<=Start_7Display6;
							end if;
						when others => NULL;
					end case;
					
				when Start_7Display6 =>
					slave_address<= "1110101"; --75	
					case busy_count is
						when 0 To 1=> -- turn on osscilator
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"E1"; --Brightness level = 1
							if (busy_old = '1' AND busy = '0') then
								busy_count<=0;
								State_Machine<=Velocity;
							end if;
						when others => NULL;
					end case;
					
					
			when Velocity =>
				  slave_address<= "1110000"; --70
				  case busy_count is
						when 0 =>
							Data_for_write<= x"00";
						when 1=>
							divide_4bits<=velocity_input(15 Downto 12);
							Data_for_write<= Convert_Digit;
													
						when 2 =>
							Data_for_write<= x"00";
						when 3=>
							divide_4bits<=velocity_input(11 Downto 8);
							Data_for_write<= Convert_Digit;
							
						when 4 =>
							Data_for_write<= x"00";
						when 5=>
						   Data_for_write<= x"00";
						when 6=>
							Data_for_write<= x"00";
						when 7=>
							divide_4bits<=velocity_input(7 Downto 4);
							Data_for_write<= Convert_Digit;
							
						when 8=>
							Data_for_write<= x"00";
						when 9=>
							divide_4bits<=velocity_input(3 Downto 0);
							Data_for_write<= Convert_Digit;
							
						when 10=>
							
							Data_for_write<= x"00";
						when 11=>
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"00";
							if (busy_old = '1' AND busy = '0') then
								
								busy_count<=0;
								State_Machine<=position;
								
							end if;
						when others => NULL;
					end case;
						
			when Position => 
				  slave_address<= "1110100"; --74
				  case busy_count is
						when 0 =>
							
							Data_for_write<= x"00";
						when 1=>
							divide_4bits<=position_input(15 Downto 12);
							Data_for_write<= Convert_Digit;
													
						when 2 =>
							Data_for_write<= x"00";
						when 3=>
							divide_4bits<=position_input(11 Downto 8);
							Data_for_write<= Convert_Digit;
							
						when 4 =>
							Data_for_write<= x"00";
						when 5=>
						   Data_for_write<= x"00";
						when 6=>
							Data_for_write<= x"00";
						when 7=>
							divide_4bits<=position_input(7 Downto 4);
							Data_for_write<= Convert_Digit;
							
						when 8=>
							Data_for_write<= x"00";
						when 9=>
							divide_4bits<=position_input(3 Downto 0);
							Data_for_write<= Convert_Digit;
							
						when 10=>
							
							Data_for_write<= x"00";
						when 11=>
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"00";
							if (busy_old = '1' AND busy = '0') then
								
								busy_count<=0;
								State_Machine<=Turn;
								
							end if;
						when others => NULL;
					end case;

			when Turn => 
				  slave_address<= "1110011"; --73
				  case busy_count is
						when 0 =>
							
							Data_for_write<= x"00";
						when 1=>
							divide_4bits<=turn_input(15 Downto 12);
							Data_for_write<= Convert_Digit;
													
						when 2 =>
							Data_for_write<= x"00";
						when 3=>
							divide_4bits<=turn_input(11 Downto 8);
							Data_for_write<= Convert_Digit;
							
						when 4 =>
							Data_for_write<= x"00";
						when 5=>
						   Data_for_write<= x"00";
						when 6=>
							Data_for_write<= x"00";
						when 7=>
							divide_4bits<=turn_input(7 Downto 4);
							Data_for_write<= Convert_Digit;
							
						when 8=>
							Data_for_write<= x"00";
						when 9=>
							divide_4bits<=turn_input(3 Downto 0);
							Data_for_write<= Convert_Digit;
							
						when 10=>
							
							Data_for_write<= x"00";
						when 11=>
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"00";
							if (busy_old = '1' AND busy = '0') then
								
								busy_count<=0;
								State_Machine<=PID_Velocity_Output;
							end if;
						when others => NULL;
					end case;

			when PID_Velocity_Output => 
				  slave_address<= "1110010"; --72
				  case busy_count is
						when 0 =>
							
							Data_for_write<= x"00";
						when 1=>
							divide_4bits<=pid_velocity_input(15 Downto 12);
							Data_for_write<= Convert_Digit;
													
						when 2 =>
							Data_for_write<= x"00";
						when 3=>
							divide_4bits<=pid_velocity_input(11 Downto 8);
							Data_for_write<= Convert_Digit;
							
						when 4 =>
							Data_for_write<= x"00";
						when 5=>
						   Data_for_write<= x"00";
						when 6=>
							Data_for_write<= x"00";
						when 7=>
							divide_4bits<=pid_velocity_input(7 Downto 4);
							Data_for_write<= Convert_Digit;
							
						when 8=>
							Data_for_write<= x"00";
						when 9=>
							divide_4bits<=pid_velocity_input(3 Downto 0);
							Data_for_write<= Convert_Digit;
							
						when 10=>
							
							Data_for_write<= x"00";
						when 11=>
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"00";
							if (busy_old = '1' AND busy = '0') then
								
								busy_count<=0;
								State_Machine<=PID_Position_Output;
								
							end if;
						when others => NULL;
					end case;

			when PID_Position_Output => 
				  slave_address<= "1110001"; --71
				  case busy_count is
						when 0 =>
							
							Data_for_write<= x"00";
						when 1=>
							divide_4bits<=pid_position_input(15 Downto 12);
							Data_for_write<= Convert_Digit;
													
						when 2 =>
							Data_for_write<= x"00";
						when 3=>
							divide_4bits<=pid_position_input(11 Downto 8);
							Data_for_write<= Convert_Digit;
							
						when 4 =>
							Data_for_write<= x"00";
						when 5=>
						   Data_for_write<= x"00";
						when 6=>
							Data_for_write<= x"00";
						when 7=>
							divide_4bits<=pid_position_input(7 Downto 4);
							Data_for_write<= Convert_Digit;
							
						when 8=>
							Data_for_write<= x"00";
						when 9=>
							divide_4bits<=pid_position_input(3 Downto 0);
							Data_for_write<= Convert_Digit;
							
						when 10=>
							
							Data_for_write<= x"00";
						when 11=>
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"00";
							if (busy_old = '1' AND busy = '0') then
								
								busy_count<=0;
								State_Machine<=Storage;
								
							end if;
						when others => NULL;
					end case;
							
				when Storage => 
				  slave_address<= "1110101"; --75
				  case busy_count is
						when 0 =>
							
							Data_for_write<= x"00";
						when 1=>
							divide_4bits<=storage_input(15 Downto 12);
							Data_for_write<= Convert_Digit;
													
						when 2 =>
							Data_for_write<= x"00";
						when 3=>
							divide_4bits<=storage_input(11 Downto 8);
							Data_for_write<= Convert_Digit;
							
						when 4 =>
							Data_for_write<= x"00";
						when 5=>
						   Data_for_write<= x"00";
						when 6=>
							Data_for_write<= x"00";
						when 7=>
							divide_4bits<=storage_input(7 Downto 4);
							Data_for_write<= Convert_Digit;
							
						when 8=>
							Data_for_write<= x"00";
						when 9=>
							divide_4bits<=storage_input(3 Downto 0);
							Data_for_write<= Convert_Digit;
							
						when 10=>
							
							Data_for_write<= x"00";
						when 11=>
							if busy='0' then
								enable_I2C_Module <= '1';
							else
								enable_I2C_Module <= '0';
							end if;
							Data_for_write<= x"00";
							if (busy_old = '1' AND busy = '0') then
								
								busy_count<=0;
								State_Machine<=Velocity;
								
							end if;
						when others => NULL;
					end case;
							
						
				  
--			when Extra_process =>
				  --slave_address<= "1110010"; --72
				 
--				  if count > 500000 then
--				  State_Machine<=Start_7Display1;
--				  end if;
			when others =>
				  State_Machine<=Idle;
		end case;
	end if;

end process;

----PROCESS FOR SLAVE_MODULE and STORAGE_MODULE
--process (CLK,talk_address_came)
--begin
--	if rising_edge(clk) and talk_address_came = '1' then
--				case talk_address is
--					when x"FF" =>
--						data_for_sending<=position_input(7 DOWNTO 0);
--					when x"02" =>
--						data_for_sending<=position_input(15 DOWNTO 8);
--					when x"03" =>
--						data_for_sending<=turn_input(7 DOWNTO 0);
--					when x"04" =>
--						data_for_sending<=turn_input(15 DOWNTO 8);
--					when x"05" =>
--						data_for_sending<=turn_input(23 DOWNTO 16);
--					when x"06" =>
--						data_for_sending<=turn_input(31 DOWNTO 24);
--					when x"07" =>
--						data_for_sending<=velocity_input(7 DOWNTO 0);
--					when x"08" =>
--						data_for_sending<=velocity_input(15 DOWNTO 8);
--					 when others =>
--						data_for_sending<=x"00";
--				end case;
--	end if;
--end process;
--
--process (CLK,listen_address_came)
--begin
--		if rising_edge(clk) and listen_address_came = '1' then
--			listen_address_signal<=listen_address;
--			data_for_saving_signal<=data_for_saving;
--			if save_done = '1' then
--				enable_storage_signal<='1';
--				RW_storage_signal<='0';
--			else
--				RW_storage_signal<='1';
--				enable_storage_signal<='0';
--			end if;
--		end if;
--end process;
--address_for_storage<=listen_address_signal;
--data_for_storage<=data_for_saving_signal;
--enable_storage<=enable_storage_signal;
--rw_storage<=rw_storage_signal;
end Behavioral;

