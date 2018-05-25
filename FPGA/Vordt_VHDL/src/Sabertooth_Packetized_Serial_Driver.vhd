----------------------------------------------------------------------------------
-- Company: Mute's Design & Lab 
-- Engineer: Murat Terzi
-- 
-- Create Date:    20:14:56 03/05/2018 
-- Design Name: 
-- Module Name:    Sabeertooth Driver - Behavioral 
-- Project Name: Vordt
-- Target Devices:XC6SLX9 
-- Tool versions: 
-- Description: 
-- Driving 60x2 amp sabertooth driver
-- protocol details in the documentation
-- Dependencies: 
--
-- Revision: 
-- Revision 1.0 - File Created and working
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

entity Sabertooth_Packetized_Serial_Driver is
PORT (
		--in
		CLK : IN STD_LOGIC;
		Reset: IN STD_LOGIC;
		TX_Done : IN STD_LOGIC;
		TX_ACTIVE : IN STD_LOGIC;
		--Motor1_Input : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
		--Motor2_Input : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
		Motor1_Direction : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		Motor1_Power : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		Motor2_Direction : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		Motor2_Power : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		--out
		TX_DV : OUT STD_LOGIC;
		Output_Command : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
end Sabertooth_Packetized_Serial_Driver;

architecture Behavioral of Sabertooth_Packetized_Serial_Driver is
	type States is (Idle, Motor1_First, Motor1_Second, Motor1_Third, Motor1_Fourth,
	Motor2_First, Motor2_Second, Motor2_Third, Motor2_Fourth, Wait_State, Wait_One);
	signal State_Machine : States;
	signal count : integer range 0 to 510;
	signal Motor1_Address_Command : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal Motor1_Motor_Command : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal Motor1_Power_Command : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal Motor1_CheckSum_Command : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal Motor2_Address_Command : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal Motor2_Motor_Command : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal Motor2_Power_Command : STD_LOGIC_VECTOR(7 DOWNTO 0);
	signal Motor2_CheckSum_Command : STD_LOGIC_VECTOR(7 DOWNTO 0);
	--signal Motor1_Packet : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others => '0');
	--signal Motor2_Packet : STD_LOGIC_VECTOR(23 DOWNTO 0) := (others => '0');

	signal dv_signal :std_logic :='0';
	signal Output_Command_signal : STD_LOGIC_VECTOR(7 DOWNTO 0):=x"00";
begin

process (CLK,Reset)
begin
	if reset = '0' then
		Motor1_Address_Command<=x"00";
		Motor1_Motor_Command<=x"00";
		Motor1_Power_Command<=x"00";
		Motor1_CheckSum_Command<=x"00";
		
		Motor2_Address_Command<=x"00";
		Motor2_Motor_Command<=x"00";
		Motor2_Power_Command<=x"00";
		Motor2_CheckSum_Command<=x"00";

		dv_signal<='0';
		Output_Command_signal<=x"00";
		count<=0;
		State_Machine<=idle;
	elsif rising_edge(CLK) then
		
				
			case State_Machine is
				when Idle=>
						--if Ready = '1' then
							if TX_ACTIVE = '0' then
								State_Machine<=Motor1_First;
								Motor1_Address_Command<=x"80";
								Motor1_Motor_Command<=Motor1_Direction;
								Motor1_Power_Command<=Motor1_Power;
								Motor1_CheckSum_Command<=((Motor1_Address_Command + Motor1_Motor_Command + Motor1_Power_Command) AND "01111111");
								Motor2_Address_Command<=x"80";
								Motor2_Motor_Command<=Motor2_Direction;
								Motor2_Power_Command<=Motor2_Power;
								Motor2_CheckSum_Command<=((Motor2_Address_Command + Motor2_Motor_Command + Motor2_Power_Command) AND "01111111");	
								--Motor1_Address_Command<=Motor1_Input(23 Downto 16);
							else
								State_Machine<=Wait_One;
							end if;
						--end if;
				when Motor1_First=>
						--Motor1_Motor_Command<=Motor1_Input(15 Downto 8);
						Output_Command_signal<=Motor1_Address_Command;
						if tx_done = '1' then
							dv_signal<='0';
							if dv_signal='0' then
								State_Machine<=Motor1_Second;
							end if;
						else
							dv_signal<='1';
						end if;
				when Motor1_Second=>
						--Motor1_Power_Command<=Motor1_Input(7 Downto 0);
						Output_Command_signal<=Motor1_Motor_Command;
						if tx_done = '1' then
							dv_signal<='0';
							if dv_signal='0' then
								State_Machine<=Motor1_Third;
							end if;
						else
							dv_signal<='1';
						end if;
				when Motor1_Third=>
						Output_Command_signal<=Motor1_Power_Command;
						if tx_done = '1' then
							dv_signal<='0';
							if dv_signal='0' then
								State_Machine<=Motor1_Fourth;
							end if;
						else
							dv_signal<='1';
						end if;
				when Motor1_Fourth=>
						Output_Command_signal<=Motor1_CheckSum_Command;
						if tx_done = '1' then
							dv_signal<='0';
							if dv_signal = '0' then
								State_Machine<=Wait_State;
							end if;
						else
							dv_signal<='1';
						end if;
				when Wait_State =>
						if count = 500 then
							count <= 0;
							State_Machine<=Motor2_First;
						elsif count = 20 then
							count<=count + 1;
						elsif count = 15 then
							--Motor2_Power_Command<=Motor2_Input(7 Downto 0);
							--Motor2_Power_Command<=Motor2_Direction;
							count<=count + 1;
						elsif count = 10 then
							--Motor2_Motor_Command<=Motor2_Packet(15 Downto 8);
							--Motor2_Motor_Command<=Motor2_Power;
							count<=count + 1;
						elsif count = 5 then
							--Motor2_Address_Command<=Motor2_Packet(23 Downto 16);
							--Motor2_Address_Command<=x"80";
							count<=count + 1;
						else
							--Motor2_Packet<=Motor2_Input;
							count<=count + 1;
						end if;
						State_Machine<=Motor2_First;
				when Motor2_First=>
						Output_Command_signal<=Motor2_Address_Command;
						if tx_done = '1' then
							dv_signal<='0';
							if dv_signal='0' then
								State_Machine<=Motor2_Second;
							end if;
						else
							dv_signal<='1';
						end if;
				when Motor2_Second=>
						--Output_Command_signal<=Motor2_Motor_Command;
						--Output_Command_signal<=x"05";
						Output_Command_signal<=Motor2_Motor_Command;
						if tx_done = '1' then
							dv_signal<='0';
							if dv_signal='0' then
								State_Machine<=Motor2_Third;
							end if;
						else
							dv_signal<='1';
						end if;
				when Motor2_Third=>
						Output_Command_signal<=Motor2_Power_Command;
						if tx_done = '1' then
							dv_signal<='0';
							if dv_signal='0' then
								State_Machine<=Motor2_Fourth;
							end if;
						else
							dv_signal<='1';
						end if;
				when Motor2_Fourth=>
						Output_Command_signal<=Motor2_CheckSum_Command;
						if tx_done = '1' then
							dv_signal<='0';
							if dv_signal = '0' then
								State_Machine<=Wait_One;
							end if;
						else
							dv_signal<='1';
						end if;
				when Wait_One =>
						dv_signal<='0';
						State_Machine<=Idle;
						
				when others => 
						dv_signal<='0';
						State_Machine<=Idle;
				end case;
	end if;
end process;

--process (CLK)
--begin 
--	if rising_edge(CLK) then
--		
--		if count = 500 then
--				count <= 0;
--		else
--			count<=count + 1;
--		end if;
--	end if;
--end process;


Output_Command<=Output_Command_signal;
tx_dv<=dv_signal;



--Motor1_Address_Command<=std_logic_vector(to_unsigned(128,Motor1_Address_Command'length));
--Motor1_Motor_Command<=std_logic_vector(to_unsigned(0,Motor1_Motor_Command'length));
--Motor1_Power_Command<=std_logic_vector(to_unsigned(10,Motor1_Power_Command'length));
end Behavioral;

