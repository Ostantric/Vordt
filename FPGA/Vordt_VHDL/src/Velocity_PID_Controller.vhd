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
-- propagation delay can be decreased by adding more states.
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
		Motor_Number : IN STD_LOGIC;
		Direction_Command : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
end Velocity_PID_Controller;

architecture Behavioral of Velocity_PID_Controller is
	type States is (Idle, calculate_error,PID_Gain_Adjust, calculate_PID,Calculate_output, adjust_output,Last_process);
	signal State_Machine : States;
	--signal convert_setpoint,PID_input_convert : STD_LOGIC_VECTOR (15 Downto 0);
	signal sample_rate : integer range 0 to 5000001; --x"7A120" --1/100 seconds or 10 milliseconds
	signal Kp : integer range 0 to 64 :=0;		--proportional constant
   signal Kd : integer range 0 to 64 :=0;		--Derivative constant, hard to tweak this!
   signal Ki : integer range 0 to 64 :=0;		--integral constant
	signal error : integer range -1000 to 1000 :=0;
	signal PID_input : INTEGER RANGE -32768 TO 32767 :=0;
	signal p,i,d : integer range -10000 to 10000 :=0;
	signal setpoint :  INTEGER RANGE -32768 TO 32767 :=0;
	signal output,output_checked : integer range -200 to 200:=0;
	signal Error_past : integer range -300 to 300 :=0;
	signal Output_past : integer range -200 to 200 :=0;
	--signal direction: std_logic_Vector (7 Downto 0);
begin

process (CLK,reset_n)
begin
	if reset_n = '0' then
		sample_rate <= 0;
		error<=0;
		output<=0;
		output_checked<=0;
		Error_past<=0;
		Output_past<=0;
		State_Machine<=idle;
		setpoint<=0;
		PID_input<=0;
		p<=0;
		i<=0;
		d<=0;
		direction_command<=x"00";
		output_command<=x"00";
	elsif rising_edge(CLK) then
			

			if sample_rate = Clock_ticks_per_sample + 1 then
				sample_rate <= 0;
			else
				sample_rate <= sample_rate + 1;
			end if;
		case State_Machine is
			when idle =>
					if sample_rate = Clock_ticks_per_sample then
						Error_past <= Error;
						--i_condition1 <= Error-Error_past;
						--i_condition2 <= Error_past-Error;
						output<=to_integer(signed(Output_Command));
						Output_past <=output;
						setpoint<=to_integer(signed(Set_point));
						PID_input<=to_integer(signed(Feedback));
						State_Machine <=calculate_error;
					end if;
			when calculate_Error =>
				Error<= Setpoint-PID_input;
				State_Machine <=PID_Gain_Adjust;
			when PID_Gain_Adjust=>
--				if Error<4 and Error>-4 then
--					Kp<=2;
--					Ki<=2;
--					Kd<=2;
--				else
					Kp<=5;
					Ki<=10;
					Kd<=6;
					--kd<=0;
--				end if;
				State_Machine <=calculate_PID;
			when calculate_PID =>
				p <= Kp * (Error);--Proportional
				d <= Kd * (Error-Error_past);--Derivative
				i <= Ki * (Error+Error_past);--Integral

				--i_condition1<=i_condition1/2;
				--i_condition2<=i_condition2/2;
				State_Machine <=Calculate_output;
--			when calculate_I =>	
--				if error > error_past then
--					i <= Ki*(Error_past+i_condition1);
--				elsif error < error_past then
--					i <= Ki * (error + i_condition2);
--				else
--				end if;
--				State_Machine <=Calculate_output;
			when Calculate_output =>
					--Three cases
					--two of them have inner multiple conditions
					--stop command has a special condition where ignores pid and corrects integral error(output<=5)
					--by implementing this, module works like a charm
					--here is the outcome;
						--disadvantage
							--propagation delay increases
							--minimum period is 13.840ns at speed grade: -2
							--increased Arrival time before clock : 5.438 ns
						--advantage
							--Division can be adjusted
							--adaptive pid for future work
							--Controlling Gearmotors with -2/2 ticks per unit time accuracy
					
					if setpoint > 0 then --Clockwise
						if pid_input > 0 then --Clockwise
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
						else --Counter clockwise
							if Error > 99 then
								output<= Output_past + ((p+i+d)/256);
							elsif Error < 35 and Error > 0 then
								output<= Output_past + ((p+i+d)/32);
							elsif Error < 100  and Error > 34 then
								output<= Output_past + ((p+i+d)/128);
							else
								output<= Output_past + ((p+i+d)/256);
							end if;
						end if;
					elsif setpoint < 0 then -- Counter clockwise
						if pid_input < 0 then -- Counter Clockwise
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
						else -- Clockwise
							if Error < -99 then
								output<= Output_past + ((p+i+d)/256);
							elsif Error > -35 and Error < 0 then
								output<= Output_past + ((p+i+d)/32);
							elsif Error > -100 and Error < -34 then
								output<= Output_past + ((p+i+d)/128);
							else
								output<= Output_past + ((p+i+d)/256);
							end if;
						end if;
					 else --stop command
							--two seperate conditions for output
							if Error > 99 then
								output<= Output_past + ((p+i+d)/256);
							elsif Error >4  and Error < 100 then
								output<= Output_past + ((p+i+d)/128);
							elsif Error < 5 and Error > -5 then
								output<= Output_past + ((p+i+d)/32);
							elsif Error < -4 and Error > -100 then
								output<= Output_past + ((p+i+d)/128);
							elsif Error < -99 then
								output<= Output_past + ((p+i+d)/256);
							else
								output<= Output_past + ((p+i+d)/256);
							end if;
					end if;
				State_Machine<=adjust_output;
			when adjust_output =>
				 if abs(output)<=6 then
				 	output_checked<=0;
				else
					output_checked<=output;
				end if;
				State_Machine<=Last_process;
			when Last_process =>
				if output_checked > 0 then
					if Motor_Number = '0' then --Motor1
						direction_command<=x"00";
					else -- Motor2
						direction_command<=x"04";
					end if;
				else
					if Motor_Number = '0' then
						direction_command<=x"01";
					else
						direction_command<=x"05";
					end if;
				end if;

				if output_checked >126 then
					output_command <= x"7E";
				elsif output_checked < -126 then
					output_command <= x"7E";
				elsif  output_checked <0 AND output_checked>-127 then
					output_command<=std_logic_vector(to_signed(-output_checked,8));
				else
					output_command<=std_logic_vector(to_signed(output_checked,8));
				end if;
				if output > 127 then
					output<=127;
				elsif output < -127 then
					output<=-127;
				else
					output<=output;
				end if;
				State_Machine <=idle;
	--			if Error = 0 then
	--				output<=0;
	--			end if;
				--Output_Command<=std_logic_vector(to_unsigned(output,8));
		end case;
					
		end if;
end process;

--scale_down<= 128 when Error > 299 else  
--				 64 when  Error >13  and Error < 300 else
--				 16 when Error < 14 and Error > -15 else
--				 64 when Error < -14 and Error > -300 else
--				 128;
--convert_setpoint<=Set_point when setpoint_calc >0 else
--						 NOT(Set_point) + x"0001" when setpoint_calc < 0 else
--						x"0000";
--PID_input_convert<=NOT(Feedback - x"0001") when input_calc <0 else
--						 feedback;
--setpoint<= to_integer(unsigned(convert_setpoint));
--setpoint_calc<= to_integer(signed(Set_point(7 Downto 0)));
--setpoint<= to_integer(signed(Set_point(7 Downto 0))); --this is for testing. 8 bit only because of I2C handle wasn't ready

--setpoint<= to_integer(signed(Set_point(15 Downto 0)));
--PID_input<=to_integer(signed(Feedback));

--PID_input<=to_integer(signed(PID_input_convert));
--input_calc<=to_integer(signed(Feedback));

--output_command <= x"7E" when output_checked > 126 else
--						x"7E" when output_checked < -126 else
--						std_logic_vector(to_signed(-output_checked,8)) when output_checked < 0 else
--						std_logic_vector(to_signed(output_checked,8));
						
--direction_command <= x"00" when output > 0 else
--							x"01";

end Behavioral;

