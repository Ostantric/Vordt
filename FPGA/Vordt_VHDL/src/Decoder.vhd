----------------------------------------------------------------------------------
-- Company: MuTe's Design & Lab 
-- Engineer: Murat Terzi
-- 
-- Create Date:    10:39:39 02/28/2018 
-- Design Name: 
-- Module Name:    Decoder 
-- Project Name: Vordt 
-- Target Devices: XC6SLX9
-- Tool versions: 
-- Description: 
-- 	One optical encoder attached to motor. 
-- 	A and B hooked up to input pins. 4x encoding were used.
-- 	Velocity one unit time is 8ms.
-- Dependencies: 
--
-- Revision: 04/01/2018
-- Revision 0.5 - Working beta
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

entity Decoder is
GENERIC(
    ONE_TURN_TICK_COUNT : INTEGER := 32767); 
PORT (
		CLK : IN STD_LOGIC;
		Encoder1_A : IN STD_LOGIC;
		Encoder1_B : IN STD_LOGIC;
		Position : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		--Absolute_Position : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		Turn_Count : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		Velocity : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		--Direction : OUT STD_LOGIC_VECTOR(1 downto 0)
		);
end Decoder;

architecture Mix of Decoder is

--type Encoder_ARRAY is array (0 to 15) of unsigned(1 downto 0); 
type Encoder_ARRAY is array (0 to 15) of integer;
type Veloctiy_Array is array (0 to 7) of signed (15 DOWNTO 0);


signal Velocity_Array_Signal : Veloctiy_Array := ((others=> x"0000"));
--signal Array_Signal : Encoder_ARRAY:=("00","11","00","01","01","00","11","00","00","01","00","11","11","00","01","00");
signal Array_Signal : Encoder_ARRAY:=(0,-1,0,1,1,0,-1,0,0,1,0,-1,-1,0,1,0);
signal index_output : integer range -1 to 1 := 0;
signal state_present_first,overflow : unsigned (1 DOWNTO 0) := "00";
Signal state_present: unsigned (1 DOWNTO 0) := "00";
Signal fix : STD_LOGIC :='0';
Signal velocity_calculate_state: STD_LOGIC :='0';
Signal state_past,state_past_delay_1: unsigned (1 DOWNTO 0) := "00";
Signal index: unsigned (3 DOWNTO 0) := (others => '0');
Signal array_output: integer range -1 to 1 := 0;
signal array_output_first :integer range -1 to 1 := 0;
signal temp_array_output:integer range -1 to 1 := 0;
signal prescaler : unsigned(25 downto 0) :=(others => '0') ;
signal prescaler2: unsigned(25 downto 0) :=(others => '0') ;
signal temp_tick: integer range -32768 to 32768 := 0;
signal temp_tick2: integer range -32768 to 32768 := 0;
signal temp_tick3: integer range -32768 to 32768 := 0;
signal tick: integer range -32768 to 32768 := 0;
signal tick_past: integer range -32768 to 32768 :=0;
signal start_tick_point : integer range -32768 to 32768 :=0;
signal ck25MHz: std_logic :='0';		-- ck 25MHz
signal clk_2Hz_i : std_logic :='0';
signal Turn : integer := 0;
signal start_turn_point : integer := 0;
signal speed : signed(15 downto 0):=(others => '0');
signal answer,answer_fixed : signed(15 downto 0):=(others => '0');
signal speed_temp,sum_of_8: signed(15 downto 0):=(others => '0');
signal reset: std_logic :='1';
signal block_turn: std_logic := '0';
signal average_count,average_count_old : integer range 0 to 8 := 0;
--attribute KEEP : string; 
--attribute KEEP of sum_of_8: signal is "TRUE";
--attribute KEEP of speed: signal is "TRUE";
--attribute KEEP of speed_temp: signal is "TRUE";
begin
--for better understanding checkout the testbench, then every process will make sense.
div2: process(clk) -- create 25MHZ clock
  begin
    if clk'event and clk = '1' then
	   ck25MHz <= not ck25MHz; 
   end if;
 end process div2;	

prescaler_process : process (ck25MHz) -- create prescaler for 1/50 seconds using 25mhz clock.
	--clock is 25MHZ.
	--Prescaler is used to count.
	--30D40, 1/125 seconds =>8 milliseconds
	--3D090, 1/100 seconds =>10 milliseconds
	--7A120, 1/50 seconds =>20 milliseconds
   --4C4B40, 1/5 seconds =>200 milliseconds
   --17D7840, 1 seconds
  begin
    if rising_edge(ck25MHz) then   
      if prescaler = X"30D40" then   --1/125 seconds
        prescaler   <= (others => '0');
      else
        prescaler <= prescaler + "1";
      end if;
	end if;
  end process prescaler_process;
store_10_velocity: process (ck25MHz) --update velocity every one second.
	begin
		if falling_edge(ck25MHz) then
			if prescaler = X"30D40" then     
				--speed<=speed_temp;
				average_count<=average_count+1;
				
				temp_tick3<=temp_tick2;

				Velocity_Array_Signal(average_count_old)<=to_signed(temp_tick2,16);
		end if;
			if average_count > 7 then
				average_count<= 0;
			end if;
		end if;
end process store_10_velocity;


average_velocity: process (clk) --update velocity every one second.
	--clock is 50MHZ.
	--Prescaler2 is used to count. 
	--7A120 1/100 seconds => 10 milliseconds
	--17D7840, 1/2 seconds
	--2FAF080, 1 seconds 
	begin
		if falling_edge(clk) then
			if average_count_old = 8 then
				sum_of_8<=Velocity_Array_Signal(0)+Velocity_Array_Signal(1)+Velocity_Array_Signal(2)
							  +Velocity_Array_Signal(3)+Velocity_Array_Signal(4)+Velocity_Array_Signal(5)
							  +Velocity_Array_Signal(6)+Velocity_Array_Signal(7);
			else
				sum_of_8<= x"0000";
			end if;
		end if;
		if rising_edge(clk) then
			if average_count_old = 8 and average_count = 0 then --divide by 8.
				--need to calculate in 2k(binary) because thug life(otherwise propagation delay is huge)
				if temp_tick <0 then  --negative number
				--translate to positive number first
				answer_fixed<=(NOT(sum_of_8-x"0001")) srl 3; --calculate 1/8.(bitwise shift right)
				--go back to negative number
				answer<=NOT(answer_fixed)+x"0001"; --(2's comp!)
				else -- positive number
				answer<=sum_of_8 srl 3;
				end if;
				--or using std_integer we can divide by 2^k.
				--answer<=sum_of_8/8;
				speed_temp<=answer;
			end if;
		end if;
end process average_velocity;
show_every_one_second: process (clk) --update velocity every one second.
	--clock is 50MHZ.
	--Prescaler2 is used to count. 
	--7A120 1/100 seconds => 10 milliseconds
	--17D7840, 1/2 seconds
	--2FAF080, 1 seconds 
	begin
		if rising_edge(clk) then
			if prescaler2 = X"2FAF080" then     -- 50M ticks = one second (2FAF080 in hex)
				--speed<=speed_temp;

				prescaler2   <= (others => '0');
			else
				prescaler2 <= prescaler2 + "1";
			end if;
			
			if prescaler2 = X"2" then
				Reset<='0';
			end if;
		end if;
end process show_every_one_second;

speed_calculate : process (CLK)
  --Clock = 50MHZ which is doubled the presecaler's clock
  --so we have 2 ticks to calculate which is well enough.
  begin 
	if rising_edge(CLK) then   -- two rising edges until prescaler gets a new value.
      if prescaler = X"30D40" then -- 1/125 seconds in 25mhz.
			--reset<='0';
			speed<=to_signed(temp_tick3,16);
			average_count_old<=average_count;
			--temp_tick<=tick; --store tick
			if overflow = "10" then
				--temp_tick2<=(tick+1)+(ONE_TURN_TICK_COUNT-temp_tick); --store tick-tick_old
				temp_tick2<=(tick+1)+(ONE_TURN_TICK_COUNT-start_tick_point); --store tick-tick_start_point
				fix <= '1';
			elsif overflow = "01" then
				temp_tick2<=(tick-1)+(-ONE_TURN_TICK_COUNT-start_tick_point); --store tick-tick_start_point
				fix <= '1';
			else
				--temp_tick2<=tick-temp_tick; --store tick-tick_old
				temp_tick2<=tick-start_tick_point; --store tick-tick_start_point
				fix <= '0';
			end if;
		elsif prescaler = X"0000" then
			start_tick_point<=tick;
			start_turn_point<=turn;
		 end if;
	end if;
		if falling_edge(CLK) then   -- two rising edges until prescaler gets a new value.
		      if prescaler = X"30D40" then -- 1/125 seconds in 25mhz.
				end if;
		end if;

  end process speed_calculate;
  
process(CLK,tick,turn) -- store state and calculate index_output from array
	begin
		if RISING_EDGE(CLK) THEN
		state_past<=state_present;
		--state_past<=state_past_delay_1;
--		case Encoder1_A is
--			when '1' => if (Encoder1_B='1') then state_present<="00"; else state_present <="01"; end if;
--			when others => if(Encoder1_B='1') then state_present<="11"; else state_present<="10"; end if;
--			end case;
		temp_array_output<=array_output;
		index_output<=Array_Signal(to_integer(index));
		tick_past<=tick;
		end if;
		
		if FALLING_EDGE(CLK) THEN
			if turn > 0 then
				if tick > ONE_TURN_TICK_COUNT then
					tick<=0;
					turn<=turn + 1;
					overflow <= "10";
				elsif tick = 0 then
					if temp_array_output = 1 then
						tick <= tick + 1;
						turn <= turn;
					elsif temp_array_output = -1 then
					   tick <= ONE_TURN_TICK_COUNT;
						turn <= turn - 1;
						overflow <= "10";
					else
						tick <= tick;
						turn <= turn;
						if fix = '1' then
							overflow <= "00";
						end if;
					end if;
				else
					tick<=tick+temp_array_output;
					if fix = '1' then
						overflow <= "00";
					end if;
				end if;
			elsif turn <0 then
					if tick < -ONE_TURN_TICK_COUNT then
						tick<=0;
						turn<=turn - 1;
						overflow <= "01";
					elsif tick = 0 then
						if temp_array_output = 1 then
							tick <= -ONE_TURN_TICK_COUNT;
							turn <= turn + 1;
							overflow <= "01";
						elsif temp_array_output = -1 then
							tick <= tick -1;
							turn <= turn;
						else
							tick <= tick;
							turn <= turn;
							if fix = '1' then
								overflow <= "00";
							end if;
						end if;		
					else
						tick<=tick+temp_array_output;
						if fix = '1' then
							overflow <= "00";
						end if;
					end if;
			else --equals to 0
				if tick > ONE_TURN_TICK_COUNT then
					tick<=0;
					turn<=turn + 1;
					overflow <= "10";
				elsif tick < -ONE_TURN_TICK_COUNT then
					tick<=0;
					turn<=turn -1;
					overflow <= "01";
				else
					tick<=tick+temp_array_output;
					if fix = '1' then
						overflow <= "00";
					end if;
				end if;			
			end if;
		end if;
			
end process;

position<= x"0000" when tick = 32768 else
			  x"0000" when tick = -32768 else
			  std_logic_vector(to_signed(tick,16)); 
--absolute_position<= 

velocity<=std_logic_vector(speed); -- update velocity
Turn_Count<=std_logic_vector(to_signed(Turn,32));
				

--speed<=speed_temp;
--speed <= speed_temp when speed_temp(15)='0' else
--			NOT(speed_temp - x"0001") when speed_temp(15)='1' else
--			x"0000";
			
--direction <= "00" when speed_temp(15)='0' else --clockwise
--				 "01" when speed_temp(15)='1' else --counterclockwise
--				 "11" when speed_temp=x"0000";

state_present<= "00" when Encoder1_A= '1' AND Encoder1_B = '1' else 
			"01" when Encoder1_A= '1' AND Encoder1_B = '0' else
			"10" when Encoder1_A= '0' AND Encoder1_B = '0' else
			"11" when Encoder1_A= '0' AND Encoder1_B = '1' else
			"XX";
index<=("00" & state_present)+("00" & state_present)+("00" & state_present)+("00" & state_present)+("00" & state_past);

array_output<=array_output_first when reset = '0' else 0;

--
--array_output_first<= "11111111111111" & index_output when index_output = "11" else
--					"00000000000000" & index_output when index_output = "00" else
--					"00000000000000" & index_output when index_output = "01" else
--					"0000000000000000";				
array_output_first<=index_output;


end Mix;

