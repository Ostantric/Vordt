----------------------------------------------------------------------------------
-- Company: Mute's Design & Lab
-- Engineer: Murat Terzi
-- 
-- Create Date:    20:14:56 03/05/2018 
-- Design Name: 
-- Module Name:    Velocity_PID_Controller - Behavioral 
-- Project Name: Vordt
-- Target Devices: XC6SLX9
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 04/08/2018
-- Revision 0.8 - Working alpha
-- Additional Comments: 
-- need cleanup and logic to handle smooth direction changes.
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

entity Velocity_PID_Controller is
generic (
    Clock_ticks_per_sample : integer := 5000000     -- 50M/10 = 5000000, 100 milliseconds
    );
PORT (
		CLK : IN STD_LOGIC;
		reset_n : IN STD_LOGIC;
		Set_point : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		Feedback : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		Output_Command : Buffer STD_LOGIC_VECTOR(7 DOWNTO 0); --sabertooth motor power value
		Direction_Command : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
end Velocity_PID_Controller;

architecture Behavioral of Velocity_PID_Controller is
	type States is (Idle, calculate_error, calculate_PID, Calculate_output,Last_process);
	signal State_Machine : States;
	signal convert_setpoint,PID_input_convert : STD_LOGIC_VECTOR (15 Downto 0);
	signal sample_rate : integer range 0 to 5000001  := 0; --x"7A120" --1/100 seconds or 10 milliseconds
	signal Kp : integer := 5;		--proportional constant
   signal Kd : integer := 6;		--differential constant, hard to tweak this!
   signal Ki : integer := 9;		--integral constant
	signal error : integer:=0;
	signal PID_input,input_calc : INTEGER RANGE -10000 TO 10000;
	signal p,i,d : integer:=0;
	signal setpoint,setpoint_calc :  INTEGER RANGE -10000 TO 10000;
	signal output : integer :=0;
	signal Error_past : integer :=0;
	signal Output_past : integer :=0;
	signal direction: std_logic_Vector (7 Downto 0);
begin

process (CLK,reset_n,sample_rate)
begin
	if reset_n = '0' then
		sample_rate <= 0;
		error<=0;
		output<=0;
		State_Machine<=idle;
	else		
		if rising_edge(CLK) then
			if sample_rate = Clock_ticks_per_sample + 1 then
				sample_rate <= 0;
			else
				sample_rate <= sample_rate + 1;
			end if;
		case State_Machine is
			when idle =>
					if sample_rate = Clock_ticks_per_sample then
						Error_past <= Error;
						output<=to_integer(unsigned(Output_Command));
						Output_past <=output;
						--setpoint<= to_integer(signed(Set_point));
						State_Machine <=calculate_error;
					end if;
			when calculate_Error =>
				Error<= Setpoint-PID_input;
				State_Machine <=calculate_PID;
			when calculate_PID =>
				p <= Kp*(Error);
				i <= Ki*(Error+Error_past);
				d <= Kd * (Error-Error_past);
				State_Machine <=Calculate_output;
			when Calculate_output =>
					if Error > 99 then
						output<= Output_past + ((p+i+d)/256);
					elsif Error >4  and Error < 100 then
						output<= Output_past + ((p+i+d)/128);
					elsif Error < 5 and Error > -5 then
						output<= Output_past + ((p+i+d)/64);
					elsif Error < -4 and Error > -100 then
						output<= Output_past + ((p+i+d)/128);
					elsif Error < -99 then
						output<= Output_past + ((p+i+d)/256);
					else
						output<= Output_past + ((p+i+d)/256);
					end if;
				State_Machine<=Last_process;
			when Last_process =>
				State_Machine <=idle;
	--			if Error = 0 then
	--				output<=0;
	--			end if;
				--Output_Command<=std_logic_vector(to_unsigned(output,8));
		end case;
					end if;
		end if;
end process;

--scale_down<= 128 when Error > 299 else  
--				 64 when  Error >13  and Error < 300 else
--				 16 when Error < 14 and Error > -15 else
--				 64 when Error < -14 and Error > -300 else
--				 128;

--speed <= speed_temp when speed_temp(15)='0' else
--			NOT(speed_temp - x"0001") when speed_temp(15)='1' else
--			x"0000";
--convert_setpoint<=Set_point when setpoint_calc >0 else
--						 NOT(Set_point) + x"0001" when setpoint_calc < 0 else
--						x"0000";

--PID_input_convert<=NOT(Feedback - x"0001") when input_calc <0 else
--						 feedback;

--setpoint<= to_integer(unsigned(convert_setpoint));
setpoint_calc<= to_integer(signed(Set_point(7 Downto 0)));

setpoint<= to_integer(signed(Set_point(7 Downto 0)));
PID_input<=to_integer(signed(Feedback));


--PID_input<=to_integer(signed(PID_input_convert));
--input_calc<=to_integer(signed(Feedback));

output_command <= x"7E" when output > 126 else
						x"7E" when output < -126 else
						std_logic_vector(to_signed(-output,8)) when output < 0 else
						std_logic_vector(to_signed(output,8));
						
direction_command <= x"00" when output > 0 else
							x"01";

end Behavioral;

