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
		TX_Done : IN STD_LOGIC;
		TX_ACTIVE : IN STD_LOGIC;
		Input : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
		--out
		TX_DV : OUT STD_LOGIC;
		Output_Command : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
end Sabertooth_Packetized_Serial_Driver;

architecture Behavioral of Sabertooth_Packetized_Serial_Driver is
	type States is (Idle, First, Second, Third, Fourth, Wait_One);
	signal State_Machine : States := Idle;
	signal count : integer range 0 to 50000000 := 0;
	signal Address_Command : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	signal Motor_Command : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	signal Power_Command : STD_LOGIC_VECTOR(7 DOWNTO 0):= (others => '0');
	signal CheckSum_Command : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
	signal dv_signal :std_logic;
	signal Output_Command_signal : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
begin

process (CLK)
begin
	if rising_edge(CLK) then
		case State_Machine is
			when Idle=>
					--if Ready = '1' then
						if TX_ACTIVE = '0' then
							State_Machine<=First;
						else
							State_Machine<=Wait_One;
						end if;
					--end if;
			when First=>
					Output_Command_signal<=Address_Command;
					if tx_done = '1' then
						dv_signal<='0';
						if dv_signal='0' then
							State_Machine<=Second;
						end if;
					else
						dv_signal<='1';
					end if;
			when Second=>
					Output_Command_signal<=Motor_Command;
					if tx_done = '1' then
						dv_signal<='0';
						if dv_signal='0' then
							State_Machine<=Third;
						end if;
					else
						dv_signal<='1';
					end if;
			when Third=>
					Output_Command_signal<=Power_Command;
					if tx_done = '1' then
						dv_signal<='0';
						if dv_signal='0' then
							State_Machine<=Fourth;
						end if;
					else
						dv_signal<='1';
					end if;
			when Fourth=>
					Output_Command_signal<=CheckSum_Command;
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

process (CLK)
begin 
	if rising_edge(CLK) then
		count<=count + 1;
--		if count = 49000000 then
--				count <= 48000000;
--		end if;
	end if;
end process;


tx_dv<=dv_signal;
Output_Command<=Output_Command_signal;

Address_Command<=input(23 Downto 16);
Motor_Command<=input(15 Downto 8);
Power_Command<=input(7 Downto 0);
CheckSum_Command<=((Address_Command + Motor_Command + Power_Command) AND "01111111");

--Address_Command<=std_logic_vector(to_unsigned(128,Address_Command'length));
--Motor_Command<=std_logic_vector(to_unsigned(0,Motor_Command'length));
--Power_Command<=std_logic_vector(to_unsigned(10,Power_Command'length));
end Behavioral;

