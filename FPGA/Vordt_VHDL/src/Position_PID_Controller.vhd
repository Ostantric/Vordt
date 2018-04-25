----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:16:07 03/05/2018 
-- Design Name: 
-- Module Name:    Position_PID_Controller - Behavioral 
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

entity Position_PID_Controller is
generic (
    Clock_ticks_per_sample : integer := 50000;     -- 50M/1000 = 50000, 0.1 milliseconds
	 Ticks_per_turn : integer := 32767
    );
PORT (
		CLK : IN STD_LOGIC;
		Max_Speed : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		Position_Set_point : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		Turn_Set_point : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		Position_Feedback : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		Turn_Feedback: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		Output_Command : Buffer STD_LOGIC_VECTOR(15 DOWNTO 0)
		);
end Position_PID_Controller;

architecture Behavioral of Position_PID_Controller is
	type States is (Idle, calculate_error, Turn_Setpoint_Adjustment, Position_Error_Correction, calculate_PID, Calculate_output,Speed_Limit_Check,Last_process);
	signal State_Machine : States := Idle;
	signal sample_rate : integer := Clock_ticks_per_sample; --x"7A120" --1/100 seconds or 10 milliseconds
    signal Kp : integer := 6;		--proportional constant
    signal Kd : integer := 1;		--Derivative constant, hard to tweak this!
    signal Ki : integer := 28;	--integral constant
	signal Pre_Position_Error,Position_Error,Position_Error_Checked, Turn_Error : integer:=0;
	signal Position_Feedback_Signal, Turn_input : integer :=0;
	signal p_position,i_position,d_position : integer:=0;
	signal Position_setpoint, Turn_setpoint : integer := 0;
	signal output,output_checked : integer :=0;
	signal maximum_allowed_speed : integer :=0;
	signal Position_Error_Checked_past,Turn_Error_past : integer :=0;
	signal Output_past : integer :=0;
	signal stage : integer range 0 to 5 :=0;
	signal inner_stage : integer range 0 to 3 :=0;

begin

process (CLK)

begin
	if rising_edge(CLK) then
	case State_Machine is
		when idle =>
				if(sample_rate = Clock_ticks_per_sample) then
					Position_Error_Checked_past <=Position_Error_Checked;
					maximum_allowed_speed<= to_integer(signed(Max_Speed));
					--Turn_Error_past <=Turn_Error;
					output<=to_integer(signed(Output_Command));
					Output_past <=output;
					--setpoint<= to_integer(signed(Set_point));
					State_Machine <=calculate_error;
				end if;

		when calculate_Error =>
			Pre_Position_Error<= Position_setpoint - Position_Feedback_Signal;
			Turn_Error<= Turn_setpoint - Turn_input;
			State_Machine <=Turn_Setpoint_Adjustment;
			stage<=0;

		when Turn_Setpoint_Adjustment=>
			case stage is
				when 0 =>
					if Turn_Error = 0 then
						Position_Error <= Pre_Position_Error;
						State_Machine <=Position_Error_Correction;
					else
						stage <= 1;
					end if;
				when 1 =>
					if Turn_Error > 1 then
						Position_Error <= 32767;
						State_Machine <=Position_Error_Correction;
					else
						stage <= 2;
					end if;
				when 2 =>
					if Turn_Error < -1 then
						Position_Error <= -32767;
						State_Machine <=Position_Error_Correction;
					else
						stage <= 3;
					end if;
				when 3 =>
					if Turn_Error = 1 then
						case inner_stage is
							when 0 =>
								if Turn_setpoint >0 then
									Position_Error <=  (Position_Setpoint+(32767-Position_Feedback_Signal+1));
									State_Machine <=Position_Error_Correction;
								else
									inner_stage<=1;
								end if;
							when 1 =>
								if Turn_setpoint <0 then
									Position_Error <=  -((-32767-Position_Setpoint)+Position_Feedback_Signal-1);
									State_Machine <=Position_Error_Correction;
								else
									inner_stage<=2;
								end if;
							when 2 =>
								if Turn_setpoint = 0 then
									Position_Error <= -((-32767-Position_Setpoint)+Position_Feedback_Signal-1);
									State_Machine <=Position_Error_Correction;
								else
									inner_stage<=0;
								end if;
							when others => null;
						end case;
					else
						stage <= 4;
						inner_stage<=0;
					end if;
				when 4=>
					if Turn_Error = -1 then
						case inner_stage is
							when 0 =>
								if Turn_setpoint >0 then
									Position_Error <= -((32767-Position_Setpoint)+Position_Feedback_Signal+1);
									State_Machine <=Position_Error_Correction;
								else
									inner_stage <= 1;
								end if;
							when 1 =>
								if Turn_setpoint <0 then
									Position_Error <=  (Position_Setpoint-1+(-32767-Position_Feedback_Signal));
									State_Machine <=Position_Error_Correction;
								else
									inner_stage <= 2;
								end if;
							when 2 =>
									if Turn_setpoint = 0 then
										Position_Error <= -((32767-Position_Setpoint)+Position_Feedback_Signal+1);
										State_Machine <=Position_Error_Correction;
									else
										inner_stage<=0;
									end if;
							when others => null;
						end case;
					else
						stage <= 0;
						inner_stage<=0;
					end if;
				when others => 	
					State_Machine <=Position_Error_Correction;
			end case;

		when Position_Error_Correction =>
			if Position_Error>32767 then
				Position_Error_Checked <= 32767;
			elsif Position_Error < -32767 then
				Position_Error_Checked <= -32767;
			else
				Position_Error_Checked <= Position_Error;
			end if;
			State_Machine <=calculate_PID;

		when calculate_PID =>
			p_position <= Kp*(Position_Error_Checked);
			i_position <= Ki*(Position_Error_Checked+Position_Error_Checked_past);
			d_position <= Kd * (Position_Error_Checked-Position_Error_Checked_past);
			State_Machine <=Calculate_output;	

		when Calculate_output =>
				if Position_Error_Checked > 1000 then
					output<= (p_position+i_position+d_position)/8192;				
				elsif Position_Error_Checked > 150  and Position_Error_Checked <1001  then
					output<= (p_position+i_position+d_position)/4096;
				elsif Position_Error_Checked < 151  and Position_Error_Checked > 80 then
					output<= (p_position+i_position+d_position)/2048;
				elsif Position_Error_Checked < 81  and Position_Error_Checked > 20 then
					output<= (p_position+i_position+d_position)/1024;
				elsif Position_Error_Checked < 21  and Position_Error_Checked > -21 then
					output<= 0;
				elsif Position_Error_Checked < -20  and Position_Error_Checked > -81 then
					output<= (p_position+i_position+d_position)/1024;
				elsif Position_Error_Checked < -80  and Position_Error_Checked > -151 then
					output<= (p_position+i_position+d_position)/2048;
				elsif Position_Error_Checked < -150 and Position_Error_Checked > -1000 then
					output<= (p_position+i_position+d_position)/4096;
				else
					output<= (p_position+i_position+d_position)/8192;
				end if;				
			State_Machine<=Speed_Limit_Check;

		when Speed_Limit_Check =>
				if abs(output) >= abs(maximum_allowed_speed) then
					if output > 0 then
							output_checked<=maximum_allowed_speed;
					else
							output_checked<= -maximum_allowed_speed;
					end if;
				else
					output_checked <= output;
				end if;
				State_Machine<=Last_process;

		when Last_process =>
			--todo : add checking
			State_Machine <=idle;
--			if Error = 0 then
--				output<=0;
--			end if;
			--Output_Command<=std_logic_vector(to_unsigned(output,8));
	end case;
				end if;
end process;

process (CLK)
begin
if rising_edge(CLK) then
if(sample_rate = Clock_ticks_per_sample) then
sample_rate <= 0;
else
sample_rate <= sample_rate + 1;
end if;
end if;
end process;

Position_setpoint<= to_integer(signed(Position_Set_point));
Turn_setpoint<= to_integer(Signed(Turn_Set_point));
Position_Feedback_Signal<=to_integer(signed(Position_Feedback));
Turn_input<=to_integer(signed(Turn_Feedback));

--output_command <= Max_Speed when output > to_integer(unsigned(Max_Speed)) else
--						std_logic_vector(to_unsigned(output,16)) ;

output_command <= std_logic_vector(to_signed(output_checked,16)) ;

						
end Behavioral;

