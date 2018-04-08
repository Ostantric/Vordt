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
    Clock_ticks_per_sample : integer := 500     -- 50M/10 = 5000000, 10 milliseconds
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
	type States is (Idle, calculate_error, calculate_PID, Calculate_output,Last_process);
	signal State_Machine : States := Idle;
	signal sample_rate : integer := Clock_ticks_per_sample; --x"7A120" --1/100 seconds or 10 milliseconds
   signal Kp : integer := 5;		--proportional constant
   signal Kd : integer := 1;		--differential constant, hard to tweak this!
   signal Ki : integer := 10;		--integral constant
	signal error : integer:=0;
	signal Position_input, Turn_input : integer :=0;
	signal p,i,d : integer:=0;
	signal Position_setpoint, Turn_setpoint : integer := 0 ;
	signal output : integer :=0;
	signal Error_past : integer :=0;
	signal Output_past : integer :=0;

begin

process (CLK)

begin
	if rising_edge(CLK) then
	case State_Machine is
		when idle =>
				if(sample_rate = Clock_ticks_per_sample) then
					Error_past <=Error;
					output<=to_integer(signed(Output_Command));
					Output_past <=output;
					--setpoint<= to_integer(signed(Set_point));
					State_Machine <=calculate_error;
				end if;
		when calculate_Error =>
			
			Error<= Position_setpoint-Position_input;
			State_Machine <=calculate_PID;
		when calculate_PID =>
			p <= Kp*(Error);
			i <= Ki*(Error+Error_past);
			d <= Kd * (Error-Error_past);
			State_Machine <=Calculate_output;	
		when Calculate_output =>
			--if output < Max_Speed then
			if Error > 3000 then
				output<= (p+i+d)/8192;
			elsif Error >300  and Error <3001  then
				output<= (p+i+d)/4096;
			elsif Error < 301 and Error > -301 then
				output<= (p+i+d)/2048;
			elsif Error < -300 and Error > -3000 then
				output<= (p+i+d)/4096;
			else
				output<= (p+i+d)/8192;
			end if;
			--end if;
			State_Machine<=Last_process;
		when Last_process =>
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
Position_input<=to_integer(signed(Position_Feedback));
Turn_input<=to_integer(signed(Turn_Feedback));

--output_command <= Max_Speed when output > to_integer(unsigned(Max_Speed)) else
--						std_logic_vector(to_unsigned(output,16)) ;

output_command <= std_logic_vector(to_unsigned(output,16)) ;

						
end Behavioral;

