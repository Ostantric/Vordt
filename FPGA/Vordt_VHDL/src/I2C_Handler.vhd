----------------------------------------------------------------------------------
-- Company: Mute's Design & Lab
-- Engineer: Murat Terzi
-- 
-- Create Date:    23:13:19 03/07/2018 
-- Design Name: 
-- Module Name:    I2C_Handler 
-- Project Name: Vordt
-- Target Devices: XC6SLX9
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 04/01/2018
-- Revision 0.4 - Working beta 
-- Additional Comments: 
-- missing register and respond slave features
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
	 Motor1_Displays_velocity_input  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);		
	 Motor1_Displays_position_input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	 Motor1_Displays_turn_input : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	 Motor1_Displays_PID_Velocity_input : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 Motor1_Displays_PID_Position_Input  : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 Motor1_Displays_storage_input : STD_LOGIC_VECTOR(15 DOWNTO 0);

	 Motor2_Displays_velocity_input  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);		
	 Motor2_Displays_position_input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	 Motor2_Displays_turn_input : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
	 Motor2_Displays_PID_Velocity_input : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 Motor2_Displays_PID_Position_Input  : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 Motor2_Displays_storage_input : STD_LOGIC_VECTOR(15 DOWNTO 0);
	 ----MASTER Module
	 --Motor1
	 Motor1_Displays_busy: IN STD_LOGIC;
	 Motor1_Displays_slave_address : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	 Motor1_Displays_Data_for_write : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	 Motor1_Displays_enable_I2C_Module : OUT STD_LOGIC :='0';
     --Motor2
	 Motor2_Displays_busy: IN STD_LOGIC;
	 Motor2_Displays_slave_address : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	 Motor2_Displays_Data_for_write : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	 Motor2_Displays_enable_I2C_Module : OUT STD_LOGIC :='0';

	 read_write_signal : OUT STD_LOGIC
	 ----SLAVE Module
		--DATA_STORAGE stuff
	 --address_for_storage : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	 --data_for_storage : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	 --data_from_storage : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
	 --enable_storage : OUT STD_LOGIC;
	 --RW_storage : OUT STD_LOGIC; 
		--I2C stuff
	 --slave_module_Motor1_Displays_busy: IN STD_LOGIC;
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
	signal Motor1_Displays_State_Machine : States:=idle;
	signal Motor2_Displays_State_Machine : States:=idle;
	signal Command_count : integer range 0 to 4 := 0;

	signal Motor1_Displays_busy_count : integer range 0 to 21 := 0 ;
	signal Motor1_Displays_busy_old : std_logic;

	signal Motor2_Displays_busy_count : integer range 0 to 21 := 0 ;
	signal Motor2_Displays_busy_old : std_logic;
	
	signal Motor1_Displays_Convert_Digit : STD_LOGIC_VECTOR(7 Downto 0);
	signal Motor1_Displays_divide_4bits : STD_LOGIC_Vector(3 downto 0);

	signal Motor2_Displays_Convert_Digit : STD_LOGIC_VECTOR(7 Downto 0);
	signal Motor2_Displays_divide_4bits : STD_LOGIC_Vector(3 downto 0);

	signal count : integer range 0 to 1000000 :=0;
	signal listen_address_signal :STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal data_for_saving_signal :STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal save : std_logic := '0';
	signal enable_storage_signal : std_logic := '0';
	signal rw_storage_signal : std_logic := '0';
	
begin

process(Motor1_Displays_divide_4bits)
begin
	case Motor1_Displays_divide_4bits is
		 when "0000" => Motor1_Displays_Convert_Digit <= x"3F"; -- "0"     
		 when "0001" => Motor1_Displays_Convert_Digit <= x"06"; -- "1" 
		 when "0010" => Motor1_Displays_Convert_Digit <= x"5B"; -- "2" 
		 when "0011" => Motor1_Displays_Convert_Digit <= x"4F"; -- "3" 
		 when "0100" => Motor1_Displays_Convert_Digit <= x"66"; -- "4" 
		 when "0101" => Motor1_Displays_Convert_Digit <= x"6D"; -- "5" 
		 when "0110" => Motor1_Displays_Convert_Digit <= x"7D"; -- "6" 
		 when "0111" => Motor1_Displays_Convert_Digit <= x"07"; -- "7" 
		 when "1000" => Motor1_Displays_Convert_Digit <= x"7F"; -- "8"     
		 when "1001" => Motor1_Displays_Convert_Digit <= x"6F"; -- "9" 
		 when "1010" => Motor1_Displays_Convert_Digit <= x"77"; -- a
		 when "1011" => Motor1_Displays_Convert_Digit <= x"7C"; -- b
		 when "1100" => Motor1_Displays_Convert_Digit <= x"39"; -- C
		 when "1101" => Motor1_Displays_Convert_Digit <= x"5E"; -- d
		 when "1110" => Motor1_Displays_Convert_Digit <= x"79"; -- E
		 when "1111" => Motor1_Displays_Convert_Digit <= x"71"; -- F
		 when others => Motor1_Displays_Convert_Digit <= x"3F";
		 end case;
end process;

process(Motor2_Displays_divide_4bits)
begin
	case Motor2_Displays_divide_4bits is
		 when "0000" => Motor2_Displays_Convert_Digit <= x"3F"; -- "0"     
		 when "0001" => Motor2_Displays_Convert_Digit <= x"06"; -- "1" 
		 when "0010" => Motor2_Displays_Convert_Digit <= x"5B"; -- "2" 
		 when "0011" => Motor2_Displays_Convert_Digit <= x"4F"; -- "3" 
		 when "0100" => Motor2_Displays_Convert_Digit <= x"66"; -- "4" 
		 when "0101" => Motor2_Displays_Convert_Digit <= x"6D"; -- "5" 
		 when "0110" => Motor2_Displays_Convert_Digit <= x"7D"; -- "6" 
		 when "0111" => Motor2_Displays_Convert_Digit <= x"07"; -- "7" 
		 when "1000" => Motor2_Displays_Convert_Digit <= x"7F"; -- "8"     
		 when "1001" => Motor2_Displays_Convert_Digit <= x"6F"; -- "9" 
		 when "1010" => Motor2_Displays_Convert_Digit <= x"77"; -- a
		 when "1011" => Motor2_Displays_Convert_Digit <= x"7C"; -- b
		 when "1100" => Motor2_Displays_Convert_Digit <= x"39"; -- C
		 when "1101" => Motor2_Displays_Convert_Digit <= x"5E"; -- d
		 when "1110" => Motor2_Displays_Convert_Digit <= x"79"; -- E
		 when "1111" => Motor2_Displays_Convert_Digit <= x"71"; -- F
		 when others => Motor2_Displays_Convert_Digit <= x"3F";
		 end case;
end process;

--process(clk)
--begin
--	if rising_edge(clk) then
--    case Motor1_Displays_divide_4bits is
--    when "0000" => Motor1_Displays_Convert_Digit <= x"3F"; -- "0"     
--    when "0001" => Motor1_Displays_Convert_Digit <= x"06"; -- "1" 
--    when "0010" => Motor1_Displays_Convert_Digit <= x"5B"; -- "2" 
--    when "0011" => Motor1_Displays_Convert_Digit <= x"4F"; -- "3" 
--    when "0100" => Motor1_Displays_Convert_Digit <= x"66"; -- "4" 
--    when "0101" => Motor1_Displays_Convert_Digit <= x"6D"; -- "5" 
--    when "0110" => Motor1_Displays_Convert_Digit <= x"7D"; -- "6" 
--    when "0111" => Motor1_Displays_Convert_Digit <= x"07"; -- "7" 
--    when "1000" => Motor1_Displays_Convert_Digit <= x"7F"; -- "8"     
--    when "1001" => Motor1_Displays_Convert_Digit <= x"6F"; -- "9" 
--    when "1010" => Motor1_Displays_Convert_Digit <= x"77"; -- a
--    when "1011" => Motor1_Displays_Convert_Digit <= x"7C"; -- b
--    when "1100" => Motor1_Displays_Convert_Digit <= x"39"; -- C
--    when "1101" => Motor1_Displays_Convert_Digit <= x"5E"; -- d
--    when "1110" => Motor1_Displays_Convert_Digit <= x"79"; -- E
--    when "1111" => Motor1_Displays_Convert_Digit <= x"71"; -- F
--	 when others => Motor1_Displays_Convert_Digit <= x"3F";
--    end case;
--	end if;
--end process;


read_write_signal<='0';
--PROCESS FOR MASTER MODULE
Motor1_Displays : process (CLK,reset)
begin
	if reset='0' then
		Motor1_Displays_State_Machine<=idle;
		count<=0;
		Motor1_Displays_busy_count<=0;
		Motor1_Displays_enable_I2C_Module<='0';
		Motor1_Displays_slave_address<="0000000";
		Motor1_Displays_Data_for_write<=x"00";
	elsif rising_edge(CLK) then
		Motor1_Displays_busy_old<=Motor1_Displays_busy;
		count<=count+1;
			if (Motor1_Displays_busy_old = '1' AND Motor1_Displays_busy= '0') THEN  --i2c Motor1_Displays_busy just went high
				Motor1_Displays_busy_count<=Motor1_Displays_busy_count+1;
			end if;
			
		case Motor1_Displays_State_Machine is
			when idle =>
					Motor1_Displays_State_Machine<=Start_7Display1;
			when Start_7Display1 =>
					Motor1_Displays_slave_address<= "1110000"; --70
					case Motor1_Displays_busy_count is
						when 0 TO 1=> -- turn on osscilator
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"21";
						when 2 TO 3=> -- display on and blinkrate
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"E1"; --Brightness level = 1
							if (Motor1_Displays_busy_old = '1' AND Motor1_Displays_busy= '0') then
								if(Motor1_Displays_busy_count>4) then
								Motor1_Displays_busy_count<=0;
								Motor1_Displays_State_Machine<=Start_7Display2;
								end if;
							end if;
						when others => NULL;
					end case;
					
			when Start_7Display2 =>
					Motor1_Displays_slave_address<= "1110001"; --71	
					case Motor1_Displays_busy_count is
						when 0 To 1=> -- turn on osscilator
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"E1"; --Brightness level = 1
							if (Motor1_Displays_busy_old = '1' AND Motor1_Displays_busy= '0') then
								Motor1_Displays_busy_count<=0;
								Motor1_Displays_State_Machine<=Start_7Display3;
							end if;
						when others => NULL;
					end case;
					
			when Start_7Display3 =>
					Motor1_Displays_slave_address<= "1110010"; --72	
					case Motor1_Displays_busy_count is
						when 0 To 1=> -- turn on osscilator
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"E1"; --Brightness level = 1
							if (Motor1_Displays_busy_old = '1' AND Motor1_Displays_busy= '0') then
								Motor1_Displays_busy_count<=0;
								Motor1_Displays_State_Machine<=Start_7Display4;
							end if;
						when others => NULL;
					end case;
					
				when Start_7Display4 =>
					Motor1_Displays_slave_address<= "1110011"; --73	
					case Motor1_Displays_busy_count is
						when 0 To 1=> -- turn on osscilator
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"E1"; --Brightness level = 1
							if (Motor1_Displays_busy_old = '1' AND Motor1_Displays_busy= '0') then
								Motor1_Displays_busy_count<=0;
								Motor1_Displays_State_Machine<=Start_7Display5;
							end if;
						when others => NULL;
					end case;
					
				when Start_7Display5 =>
					Motor1_Displays_slave_address<= "1110100"; --74	
					case Motor1_Displays_busy_count is
						when 0 To 1=> -- turn on osscilator
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"E1"; --Brightness level = 1
							if (Motor1_Displays_busy_old = '1' AND Motor1_Displays_busy= '0') then
								Motor1_Displays_busy_count<=0;
								Motor1_Displays_State_Machine<=Start_7Display6;
							end if;
						when others => NULL;
					end case;
					
				when Start_7Display6 =>
					Motor1_Displays_slave_address<= "1110101"; --75	
					case Motor1_Displays_busy_count is
						when 0 To 1=> -- turn on osscilator
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"E1"; --Brightness level = 1
							if (Motor1_Displays_busy_old = '1' AND Motor1_Displays_busy= '0') then
								Motor1_Displays_busy_count<=0;
								Motor1_Displays_State_Machine<=Velocity;
							end if;
						when others => NULL;
					end case;
					
					
			when Velocity =>
				  Motor1_Displays_slave_address<= "1110000"; --70
				  case Motor1_Displays_busy_count is
						when 0 =>
							Motor1_Displays_Data_for_write<= x"00";
						when 1=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_velocity_input(15 Downto 12);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
													
						when 2 =>
							Motor1_Displays_Data_for_write<= x"00";
						when 3=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_velocity_input(11 Downto 8);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 4 =>
							Motor1_Displays_Data_for_write<= x"00";
						when 5=>
						   Motor1_Displays_Data_for_write<= x"00";
						when 6=>
							Motor1_Displays_Data_for_write<= x"00";
						when 7=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_velocity_input(7 Downto 4);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 8=>
							Motor1_Displays_Data_for_write<= x"00";
						when 9=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_velocity_input(3 Downto 0);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 10=>
							
							Motor1_Displays_Data_for_write<= x"00";
						when 11=>
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"00";
							if (Motor1_Displays_busy_old = '1' AND Motor1_Displays_busy= '0') then
								
								Motor1_Displays_busy_count<=0;
								Motor1_Displays_State_Machine<=position;
								
							end if;
						when others => NULL;
					end case;
						
			when Position => 
				  Motor1_Displays_slave_address<= "1110100"; --74
				  case Motor1_Displays_busy_count is
						when 0 =>
							
							Motor1_Displays_Data_for_write<= x"00";
						when 1=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_position_input(15 Downto 12);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
													
						when 2 =>
							Motor1_Displays_Data_for_write<= x"00";
						when 3=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_position_input(11 Downto 8);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 4 =>
							Motor1_Displays_Data_for_write<= x"00";
						when 5=>
						   Motor1_Displays_Data_for_write<= x"00";
						when 6=>
							Motor1_Displays_Data_for_write<= x"00";
						when 7=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_position_input(7 Downto 4);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 8=>
							Motor1_Displays_Data_for_write<= x"00";
						when 9=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_position_input(3 Downto 0);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 10=>
							
							Motor1_Displays_Data_for_write<= x"00";
						when 11=>
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"00";
							if (Motor1_Displays_busy_old = '1' AND Motor1_Displays_busy= '0') then
								
								Motor1_Displays_busy_count<=0;
								Motor1_Displays_State_Machine<=Turn;
								
							end if;
						when others => NULL;
					end case;

			when Turn => 
				  Motor1_Displays_slave_address<= "1110011"; --73
				  case Motor1_Displays_busy_count is
						when 0 =>
							
							Motor1_Displays_Data_for_write<= x"00";
						when 1=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_turn_input(15 Downto 12);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
													
						when 2 =>
							Motor1_Displays_Data_for_write<= x"00";
						when 3=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_turn_input(11 Downto 8);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 4 =>
							Motor1_Displays_Data_for_write<= x"00";
						when 5=>
						   Motor1_Displays_Data_for_write<= x"00";
						when 6=>
							Motor1_Displays_Data_for_write<= x"00";
						when 7=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_turn_input(7 Downto 4);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 8=>
							Motor1_Displays_Data_for_write<= x"00";
						when 9=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_turn_input(3 Downto 0);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 10=>
							
							Motor1_Displays_Data_for_write<= x"00";
						when 11=>
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"00";
							if (Motor1_Displays_busy_old = '1' AND Motor1_Displays_busy= '0') then
								
								Motor1_Displays_busy_count<=0;
								Motor1_Displays_State_Machine<=PID_Velocity_Output;
							end if;
						when others => NULL;
					end case;

			when PID_Velocity_Output => 
				  Motor1_Displays_slave_address<= "1110010"; --72
				  case Motor1_Displays_busy_count is
						when 0 =>
							
							Motor1_Displays_Data_for_write<= x"00";
						when 1=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_PID_Velocity_input(15 Downto 12);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
													
						when 2 =>
							Motor1_Displays_Data_for_write<= x"00";
						when 3=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_PID_Velocity_input(11 Downto 8);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 4 =>
							Motor1_Displays_Data_for_write<= x"00";
						when 5=>
						   Motor1_Displays_Data_for_write<= x"00";
						when 6=>
							Motor1_Displays_Data_for_write<= x"00";
						when 7=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_PID_Velocity_input(7 Downto 4);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 8=>
							Motor1_Displays_Data_for_write<= x"00";
						when 9=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_PID_Velocity_input(3 Downto 0);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 10=>
							
							Motor1_Displays_Data_for_write<= x"00";
						when 11=>
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"00";
							if (Motor1_Displays_busy_old = '1' AND Motor1_Displays_busy= '0') then
								
								Motor1_Displays_busy_count<=0;
								Motor1_Displays_State_Machine<=PID_Position_Output;
								
							end if;
						when others => NULL;
					end case;

			when PID_Position_Output => 
				  Motor1_Displays_slave_address<= "1110001"; --71
				  case Motor1_Displays_busy_count is
						when 0 =>
							
							Motor1_Displays_Data_for_write<= x"00";
						when 1=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_PID_Position_Input(15 Downto 12);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
													
						when 2 =>
							Motor1_Displays_Data_for_write<= x"00";
						when 3=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_PID_Position_Input(11 Downto 8);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 4 =>
							Motor1_Displays_Data_for_write<= x"00";
						when 5=>
						   Motor1_Displays_Data_for_write<= x"00";
						when 6=>
							Motor1_Displays_Data_for_write<= x"00";
						when 7=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_PID_Position_Input(7 Downto 4);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 8=>
							Motor1_Displays_Data_for_write<= x"00";
						when 9=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_PID_Position_Input(3 Downto 0);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 10=>
							
							Motor1_Displays_Data_for_write<= x"00";
						when 11=>
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"00";
							if (Motor1_Displays_busy_old = '1' AND Motor1_Displays_busy= '0') then
								
								Motor1_Displays_busy_count<=0;
								Motor1_Displays_State_Machine<=Storage;
								
							end if;
						when others => NULL;
					end case;
							
				when Storage => 
				  Motor1_Displays_slave_address<= "1110101"; --75
				  case Motor1_Displays_busy_count is
						when 0 =>
							
							Motor1_Displays_Data_for_write<= x"00";
						when 1=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_storage_input(15 Downto 12);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
													
						when 2 =>
							Motor1_Displays_Data_for_write<= x"00";
						when 3=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_storage_input(11 Downto 8);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 4 =>
							Motor1_Displays_Data_for_write<= x"00";
						when 5=>
						   Motor1_Displays_Data_for_write<= x"00";
						when 6=>
							Motor1_Displays_Data_for_write<= x"00";
						when 7=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_storage_input(7 Downto 4);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 8=>
							Motor1_Displays_Data_for_write<= x"00";
						when 9=>
							Motor1_Displays_divide_4bits<=Motor1_Displays_storage_input(3 Downto 0);
							Motor1_Displays_Data_for_write<= Motor1_Displays_Convert_Digit;
							
						when 10=>
							
							Motor1_Displays_Data_for_write<= x"00";
						when 11=>
							if Motor1_Displays_busy='0' then
								Motor1_Displays_enable_I2C_Module <= '1';
							else
								Motor1_Displays_enable_I2C_Module <= '0';
							end if;
							Motor1_Displays_Data_for_write<= x"00";
							if (Motor1_Displays_busy_old = '1' AND Motor1_Displays_busy= '0') then
								
								Motor1_Displays_busy_count<=0;
								Motor1_Displays_State_Machine<=Velocity;
								
							end if;
						when others => NULL;
					end case;
							
						
				  
--			when Extra_process =>
				  --Motor1_Displays_slave_address<= "1110010"; --72
				 
--				  if count > 500000 then
--				  Motor1_Displays_State_Machine<=Start_7Display1;
--				  end if;
				when others =>
				  Motor1_Displays_State_Machine<=Idle;
		end case;
	end if;

end process Motor1_Displays;

Motor2_Displays : process (CLK,reset)
begin
	if reset='0' then
		Motor2_Displays_State_Machine<=idle;
		count<=0;
		Motor2_Displays_busy_count<=0;
		Motor2_Displays_enable_I2C_Module<='0';
		Motor2_Displays_slave_address<="0000000";
		Motor2_Displays_Data_for_write<=x"00";
	elsif rising_edge(CLK) then
		Motor2_Displays_busy_old<=Motor2_Displays_busy;
		count<=count+1;
			if (Motor2_Displays_busy_old = '1' AND Motor2_Displays_busy= '0') THEN  --i2c Motor2_Displays_busy just went high
				Motor2_Displays_busy_count<=Motor2_Displays_busy_count+1;
			end if;
			
		case Motor2_Displays_State_Machine is
			when idle =>
					Motor2_Displays_State_Machine<=Start_7Display1;
			when Start_7Display1 =>
					Motor2_Displays_slave_address<= "1110000"; --70
					case Motor2_Displays_busy_count is
						when 0 TO 1=> -- turn on osscilator
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"21";
						when 2 TO 3=> -- display on and blinkrate
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"E1"; --Brightness level = 1
							if (Motor2_Displays_busy_old = '1' AND Motor2_Displays_busy= '0') then
								if(Motor2_Displays_busy_count>4) then
								Motor2_Displays_busy_count<=0;
								Motor2_Displays_State_Machine<=Start_7Display2;
								end if;
							end if;
						when others => NULL;
					end case;
					
			when Start_7Display2 =>
					Motor2_Displays_slave_address<= "1110001"; --71	
					case Motor2_Displays_busy_count is
						when 0 To 1=> -- turn on osscilator
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"E1"; --Brightness level = 1
							if (Motor2_Displays_busy_old = '1' AND Motor2_Displays_busy= '0') then
								Motor2_Displays_busy_count<=0;
								Motor2_Displays_State_Machine<=Start_7Display3;
							end if;
						when others => NULL;
					end case;
					
			when Start_7Display3 =>
					Motor2_Displays_slave_address<= "1110010"; --72	
					case Motor2_Displays_busy_count is
						when 0 To 1=> -- turn on osscilator
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"E1"; --Brightness level = 1
							if (Motor2_Displays_busy_old = '1' AND Motor2_Displays_busy= '0') then
								Motor2_Displays_busy_count<=0;
								Motor2_Displays_State_Machine<=Start_7Display4;
							end if;
						when others => NULL;
					end case;
					
				when Start_7Display4 =>
					Motor2_Displays_slave_address<= "1110011"; --73	
					case Motor2_Displays_busy_count is
						when 0 To 1=> -- turn on osscilator
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"E1"; --Brightness level = 1
							if (Motor2_Displays_busy_old = '1' AND Motor2_Displays_busy= '0') then
								Motor2_Displays_busy_count<=0;
								Motor2_Displays_State_Machine<=Start_7Display5;
							end if;
						when others => NULL;
					end case;
					
				when Start_7Display5 =>
					Motor2_Displays_slave_address<= "1110100"; --74	
					case Motor2_Displays_busy_count is
						when 0 To 1=> -- turn on osscilator
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"E1"; --Brightness level = 1
							if (Motor2_Displays_busy_old = '1' AND Motor2_Displays_busy= '0') then
								Motor2_Displays_busy_count<=0;
								Motor2_Displays_State_Machine<=Start_7Display6;
							end if;
						when others => NULL;
					end case;
					
				when Start_7Display6 =>
					Motor2_Displays_slave_address<= "1110101"; --75	
					case Motor2_Displays_busy_count is
						when 0 To 1=> -- turn on osscilator
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"21";
						when 2 TO 3 => -- display on and blinkrate
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"81"; -- display on with no blink
						when 4 TO 5 => -- brightness level
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"E1"; --Brightness level = 1
							if (Motor2_Displays_busy_old = '1' AND Motor2_Displays_busy= '0') then
								Motor2_Displays_busy_count<=0;
								Motor2_Displays_State_Machine<=Velocity;
							end if;
						when others => NULL;
					end case;
					
					
			when Velocity =>
				  Motor2_Displays_slave_address<= "1110000"; --70
				  case Motor2_Displays_busy_count is
						when 0 =>
							Motor2_Displays_Data_for_write<= x"00";
						when 1=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_velocity_input(15 Downto 12);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
													
						when 2 =>
							Motor2_Displays_Data_for_write<= x"00";
						when 3=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_velocity_input(11 Downto 8);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 4 =>
							Motor2_Displays_Data_for_write<= x"00";
						when 5=>
						   Motor2_Displays_Data_for_write<= x"00";
						when 6=>
							Motor2_Displays_Data_for_write<= x"00";
						when 7=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_velocity_input(7 Downto 4);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 8=>
							Motor2_Displays_Data_for_write<= x"00";
						when 9=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_velocity_input(3 Downto 0);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 10=>
							
							Motor2_Displays_Data_for_write<= x"00";
						when 11=>
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"00";
							if (Motor2_Displays_busy_old = '1' AND Motor2_Displays_busy= '0') then
								
								Motor2_Displays_busy_count<=0;
								Motor2_Displays_State_Machine<=position;
								
							end if;
						when others => NULL;
					end case;
						
			when Position => 
				  Motor2_Displays_slave_address<= "1110100"; --74
				  case Motor2_Displays_busy_count is
						when 0 =>
							
							Motor2_Displays_Data_for_write<= x"00";
						when 1=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_position_input(15 Downto 12);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
													
						when 2 =>
							Motor2_Displays_Data_for_write<= x"00";
						when 3=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_position_input(11 Downto 8);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 4 =>
							Motor2_Displays_Data_for_write<= x"00";
						when 5=>
						   Motor2_Displays_Data_for_write<= x"00";
						when 6=>
							Motor2_Displays_Data_for_write<= x"00";
						when 7=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_position_input(7 Downto 4);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 8=>
							Motor2_Displays_Data_for_write<= x"00";
						when 9=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_position_input(3 Downto 0);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 10=>
							
							Motor2_Displays_Data_for_write<= x"00";
						when 11=>
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"00";
							if (Motor2_Displays_busy_old = '1' AND Motor2_Displays_busy= '0') then
								
								Motor2_Displays_busy_count<=0;
								Motor2_Displays_State_Machine<=Turn;
								
							end if;
						when others => NULL;
					end case;

			when Turn => 
				  Motor2_Displays_slave_address<= "1110011"; --73
				  case Motor2_Displays_busy_count is
						when 0 =>
							
							Motor2_Displays_Data_for_write<= x"00";
						when 1=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_turn_input(15 Downto 12);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
													
						when 2 =>
							Motor2_Displays_Data_for_write<= x"00";
						when 3=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_turn_input(11 Downto 8);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 4 =>
							Motor2_Displays_Data_for_write<= x"00";
						when 5=>
						   Motor2_Displays_Data_for_write<= x"00";
						when 6=>
							Motor2_Displays_Data_for_write<= x"00";
						when 7=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_turn_input(7 Downto 4);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 8=>
							Motor2_Displays_Data_for_write<= x"00";
						when 9=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_turn_input(3 Downto 0);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 10=>
							
							Motor2_Displays_Data_for_write<= x"00";
						when 11=>
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"00";
							if (Motor2_Displays_busy_old = '1' AND Motor2_Displays_busy= '0') then
								
								Motor2_Displays_busy_count<=0;
								Motor2_Displays_State_Machine<=PID_Velocity_Output;
							end if;
						when others => NULL;
					end case;

			when PID_Velocity_Output => 
				  Motor2_Displays_slave_address<= "1110010"; --72
				  case Motor2_Displays_busy_count is
						when 0 =>
							
							Motor2_Displays_Data_for_write<= x"00";
						when 1=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_PID_Velocity_input(15 Downto 12);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
													
						when 2 =>
							Motor2_Displays_Data_for_write<= x"00";
						when 3=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_PID_Velocity_input(11 Downto 8);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 4 =>
							Motor2_Displays_Data_for_write<= x"00";
						when 5=>
						   Motor2_Displays_Data_for_write<= x"00";
						when 6=>
							Motor2_Displays_Data_for_write<= x"00";
						when 7=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_PID_Velocity_input(7 Downto 4);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 8=>
							Motor2_Displays_Data_for_write<= x"00";
						when 9=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_PID_Velocity_input(3 Downto 0);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 10=>
							
							Motor2_Displays_Data_for_write<= x"00";
						when 11=>
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"00";
							if (Motor2_Displays_busy_old = '1' AND Motor2_Displays_busy= '0') then
								
								Motor2_Displays_busy_count<=0;
								Motor2_Displays_State_Machine<=PID_Position_Output;
								
							end if;
						when others => NULL;
					end case;

			when PID_Position_Output => 
				  Motor2_Displays_slave_address<= "1110001"; --71
				  case Motor2_Displays_busy_count is
						when 0 =>
							
							Motor2_Displays_Data_for_write<= x"00";
						when 1=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_PID_Position_Input(15 Downto 12);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
													
						when 2 =>
							Motor2_Displays_Data_for_write<= x"00";
						when 3=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_PID_Position_Input(11 Downto 8);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 4 =>
							Motor2_Displays_Data_for_write<= x"00";
						when 5=>
						   Motor2_Displays_Data_for_write<= x"00";
						when 6=>
							Motor2_Displays_Data_for_write<= x"00";
						when 7=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_PID_Position_Input(7 Downto 4);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 8=>
							Motor2_Displays_Data_for_write<= x"00";
						when 9=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_PID_Position_Input(3 Downto 0);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 10=>
							
							Motor2_Displays_Data_for_write<= x"00";
						when 11=>
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"00";
							if (Motor2_Displays_busy_old = '1' AND Motor2_Displays_busy= '0') then
								
								Motor2_Displays_busy_count<=0;
								Motor2_Displays_State_Machine<=Storage;
								
							end if;
						when others => NULL;
					end case;
							
				when Storage => 
				  Motor2_Displays_slave_address<= "1110101"; --75
				  case Motor2_Displays_busy_count is
						when 0 =>
							
							Motor2_Displays_Data_for_write<= x"00";
						when 1=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_storage_input(15 Downto 12);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
													
						when 2 =>
							Motor2_Displays_Data_for_write<= x"00";
						when 3=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_storage_input(11 Downto 8);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 4 =>
							Motor2_Displays_Data_for_write<= x"00";
						when 5=>
						   Motor2_Displays_Data_for_write<= x"00";
						when 6=>
							Motor2_Displays_Data_for_write<= x"00";
						when 7=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_storage_input(7 Downto 4);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 8=>
							Motor2_Displays_Data_for_write<= x"00";
						when 9=>
							Motor2_Displays_divide_4bits<=Motor2_Displays_storage_input(3 Downto 0);
							Motor2_Displays_Data_for_write<= Motor2_Displays_Convert_Digit;
							
						when 10=>
							
							Motor2_Displays_Data_for_write<= x"00";
						when 11=>
							if Motor2_Displays_busy='0' then
								Motor2_Displays_enable_I2C_Module <= '1';
							else
								Motor2_Displays_enable_I2C_Module <= '0';
							end if;
							Motor2_Displays_Data_for_write<= x"00";
							if (Motor2_Displays_busy_old = '1' AND Motor2_Displays_busy= '0') then
								
								Motor2_Displays_busy_count<=0;
								Motor2_Displays_State_Machine<=Velocity;
								
							end if;
						when others => NULL;
					end case;
							
						
				  
--			when Extra_process =>
				  --Motor2_Displays_slave_address<= "1110010"; --72
				 
--				  if count > 500000 then
--				  Motor2_Displays_State_Machine<=Start_7Display1;
--				  end if;
				when others =>
				  Motor2_Displays_State_Machine<=Idle;
		end case;
	end if;

end process Motor2_Displays;
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
--						data_for_sending<=Motor1_Displays_turn_input(7 DOWNTO 0);
--					when x"04" =>
--						data_for_sending<=Motor1_Displays_turn_input(15 DOWNTO 8);
--					when x"05" =>
--						data_for_sending<=Motor1_Displays_turn_input(23 DOWNTO 16);
--					when x"06" =>
--						data_for_sending<=Motor1_Displays_turn_input(31 DOWNTO 24);
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

