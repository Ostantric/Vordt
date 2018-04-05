----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:37:38 03/29/2018 
-- Design Name: 
-- Module Name:    I2C_Slave_Module - Behavioral 
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
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity I2C_Slave_Module is
GENERIC(
    --input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
    --bus_clk   : INTEGER := 400_000;   --speed the i2c bus (scl) will run at in Hz
	 slave_addr: STD_LOGIC_VECTOR(6 DOWNTO 0) := "1000000"); --address
	  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    --ena       : IN     STD_LOGIC;                    --latch in command

	 busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
	 --rw        : OUT     STD_LOGIC;                    --'0' is write, '1' is read
	 
	 send_done : OUT STD_LOGIC;
	 save_done : OUT STD_LOGIC;
	 
	 listen_address_received : OUT STD_LOGIC;
	 talk_address_received : OUT STD_LOGIC;
	 
    data_to_send : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to send to master
    data_to_save : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data from master
	 
	 listen_address : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	 talk_address : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
	 
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
	 
end I2C_Slave_Module;


architecture Behavioral of I2C_Slave_Module is
  --CONSTANT divider  :  INTEGER := (input_clk/bus_clk)/4; --number of clocks in 1/4 cycle of scl
  TYPE states IS(idle, address, send_ack, address_for_talk, address_for_listen, talk_state, listen_state, master_ack1, master_ack2,  stop); --needed states
  signal state_machine : states;
  signal scl_rising_edge : std_logic;
  signal scl_falling_edge : std_logic;
  signal sda_past   : std_logic;
  signal sda_past_2 : std_logic;
  signal sda_past_3 : std_logic;
  signal scl_past   : std_logic;
  signal scl_past_2 : std_logic;
  signal scl_past_3 : std_logic;
  signal sda_out_enable : std_logic;
  signal sda_out : std_logic;
  signal scl_out : std_logic;
  signal scl_out_enable : std_logic;
  signal bit_cnt : INTEGER RANGE 0 TO 9; --tracks bit number in transaction
  signal ack_sda_cnt : INTEGER RANGE 0 TO 40;
  signal ack_scl_cnt : INTEGER RANGE 0 TO 350;
  signal start_com : std_logic;
  signal stop_com : std_logic ;
  signal listen_done : std_logic;
  signal talk_done : std_logic;
  signal talk_address_done : std_logic;
  signal listen_address_done : std_logic;
  signal get_memory_address : std_logic ;
  signal rw_state : std_logic;
  --signal busy_signal : std_logic;
  signal continue : std_logic;
  signal slave_address_buffer : std_logic_vector(6 downto 0);
  signal talk_buffer : std_logic_vector(7 downto 0);
  signal listen_buffer : std_logic_vector(7 downto 0);
  signal address_for_talking : std_logic_vector(7 downto 0);
  signal address_for_listening : std_logic_vector(7 downto 0) ;
  
begin

process(clk,reset_n) is
begin
	if reset_n = '0' then
		start_com<='0';
		stop_com<='0';
		scl_falling_edge<='0';
		scl_rising_edge<='0';
		
	else
		if rising_edge(clk) then
			sda_past <= sda;
			sda_past_2 <= sda_past;
			sda_past_3 <= sda_past_2;
			
			scl_past <= scl;
			scl_past_2 <= scl_past;
			scl_past_3 <= scl_past_2;
			
			scl_rising_edge<='0';
			scl_falling_edge<='0';
			start_com<='0';
			stop_com<='0';
			--conditions
			if sda_past_2 = '0' and sda_past_3 = '1' and scl_past_2='1' and scl_past_3='1' then
				start_com<='1'; --start condition
				stop_com<='0';
			end if;
			if sda_past_2 = '1' and sda_past_3='0' and scl_past_2='1' and scl_past_3='1' then
				stop_com<='1'; --stop condition
				start_com<='0';
			end if;
			--scl edges
			if scl_past_2 = '1' and scl_past = '0' then
				scl_falling_edge <= '1'; --falling edge
			end if;
			if scl_past_2 = '0' and scl_past = '1' then
				scl_rising_edge <= '1'; --rising_edge
			end if;
		end if;
	end if;
end process;

process(clk,reset_n,bit_cnt,scl_rising_edge,scl_falling_edge) is
begin
	if reset_n='0' then
		state_machine<=idle;
		bit_cnt<=0;
		talk_done<='0';
		listen_done<='0';
		continue<='0';
		get_memory_address<='0';
		listen_address_done<='0';
		talk_address_done<='0';
		slave_address_buffer<="0000000";
		talk_buffer<=x"00";
		listen_buffer<=x"00";
		address_for_talking<=x"00";
		address_for_listening<=x"00";
		sda_out<='0';
		sda_out_enable<='0';
		scl_out<='0';
		scl_out_enable<='0';
	else
		if rising_edge(clk) then
			sda_out_enable<='0';
			sda_out<='0';
			scl_out<='0';
			scl_out_enable<='0';
			listen_done<='0';
			
			case state_machine is
					when idle =>
						if start_com = '1' then
							state_machine <= address;
							bit_cnt<=0;
							
						end if;
						
					when address=>
						if scl_rising_edge='1' then
							if bit_cnt<7 then
								--address bits
								slave_address_buffer(6-bit_cnt) <= sda_past_3; --7bit
								bit_cnt<=bit_cnt+1;
							elsif bit_cnt = 7 then
								--read or write bit
								rw_state<=sda_past_2;
								bit_cnt<=bit_cnt+1;
							end if;
						end if;
						--send ack on falling edge
						if scl_falling_edge='1' then
							if bit_cnt = 8 then
								bit_cnt <= 0; --reset for reading and sending
								--address comparision
								if slave_addr = slave_address_buffer then
									get_memory_address<='0';
									talk_address_done <= '0';
									listen_address_done <= '0';
									state_machine<=send_ack; -- addresses matched, send ack
									--get ready for master_read

									if rw_state = '1' then
										--load talk buffer
										talk_buffer<=data_to_send;
									end if;
								else
									--wrong slave address
									state_machine<= IDLE;
								end if;
							end if;
						end if;
						
					when send_ack=>
						--keep sda_low
						sda_out_enable<='1';
						sda_out<='0';
						ack_sda_cnt<=0;
						ack_scl_cnt<=0;
						--ack_cnt<=0;
						if scl_falling_edge = '1' then --falling edge
							--listen_done<='0';
--							if get_memory_address = '0' then 
--								if rw_state = '1' then --read
--									state_machine <= address_for_talk;
--								else --write
--									state_machine <= address_for_listen;
--								end if;
--							else
--								talk_address_done <= '0';
--								listen_address_done <= '0';
--								if rw_state = '1' then --read
--									state_machine <= talk_state;
--								else --write
--									state_machine <= listen_state;
--								end if;
--							end if;
							--ack_cnt<=ack_cnt + 1;
							
							if rw_state = '1' then --read
									state_machine <= talk_state;
								else --write
									state_machine <= listen_state;
								end if;
						end if;
									
						
					when address_for_talk =>
						if scl_rising_edge = '1' then
							if bit_cnt <=7 then
								address_for_talking(7-bit_cnt) <= sda_past_2;
								bit_cnt <= bit_cnt+1;
							end if;
							if bit_cnt = 7 then
								get_memory_address <= '1';
								talk_address_done <= '1';
							end if;
						end if;
						if scl_falling_edge ='1' and bit_cnt = 8 then
							state_machine <= send_ack;
							bit_cnt <= 0;
						end if;
						
					when address_for_listen =>
						if scl_rising_edge = '1' then
							if bit_cnt <=7 then
								address_for_listening(7-bit_cnt) <= sda_past_2;
								bit_cnt <= bit_cnt+1;
							end if;
							if bit_cnt = 7 then
								get_memory_address <= '1';
								listen_address_done <= '1';
							end if;
						end if;
						if scl_falling_edge ='1' and bit_cnt = 8 then
							state_machine <= send_ack;
							bit_cnt <= 0;
						end if;
						
					when listen_state=>
---------------------------------------------------------------------------------------------
						--below logic is for ;
						--IF for some reason
						--MASTER or FPGA-Slave module CAN'T catch up 
						--then slow down give sometime
						--approx 800ns for sda = 0; this can be calld Master Blockage
						--approx 7000ns for scl = 0; this can be called Clock Stretching 
						
						if ack_sda_cnt <=39 then
						sda_out_enable<='1';
						sda_out<='0';
						ack_sda_cnt<=ack_sda_cnt + 1;
						else
						sda_out_enable<='0';
						sda_out<='0';
						end if;
						
						if ack_scl_cnt <=349 then
						scl_out_enable<='1';						
						ack_scl_cnt<=ack_scl_cnt + 1;
						else
						scl_out_enable<='0';
						end if;
---------------------------------------------------------------------------------------------						
						if scl_rising_edge = '1' then
							if bit_cnt <=7 then
								listen_buffer(7-bit_cnt) <= sda_past_3;
								bit_cnt <= bit_cnt+1;
							end if;
							if bit_cnt = 7 then
								listen_done <= '1';
							end if;
						end if;
						if scl_falling_edge ='1' and bit_cnt = 8 then
							state_machine <= send_ack;
							bit_cnt <= 0;
						end if;
								
					when talk_state=>
						sda_out_enable <= '1';
						sda_out <= talk_buffer(7-bit_cnt); --8bit
						
						if scl_falling_edge = '1' then --falling edge
							if bit_cnt<7 then
								bit_cnt<=bit_cnt+1;
							elsif bit_cnt = 7 then --byte sent
								bit_cnt<=0;
								state_machine<=master_ack1; --wait for master ack
							end if;
						end if;
							
					when master_ack1=>
							if scl_rising_edge = '1' then
								state_machine <= master_ack2;
								if sda_past_3 = '1' then
									--NACK, no more talking/listenning
									continue <= '0';
								else
									--ACK, keep going
									continue <= '1';
									talk_buffer<=data_to_send;
								end if;
							end if;
					when master_ack2=>
							if scl_falling_edge = '1' then
								if continue = '1' then --continue transmission
									if rw_state = '1' then
										state_machine<= talk_state;
									else
										state_machine<= listen_state;
									end if;
								else --wait for stop condition
									state_machine<= stop;
								end if;
							end if;

					when stop=>
							talk_done<= '1';
							--null;
					end case;
					
				if start_com = '1' then
					talk_done     <= '0';
					listen_done  <= '0';
					bit_cnt <= 0;
					slave_address_buffer<="0000000";
					address_for_listening<="00000000";
					address_for_talking<="00000000";
					state_machine  <= address;
			  end if;

			  if stop_com = '1' then
					talk_done     <= '0';
					listen_done  <= '0';
					bit_cnt <= 0;
					slave_address_buffer<="0000000";
					address_for_listening<="00000000";
					address_for_talking<="00000000";
					state_machine       <= IDLE;
			  end if;
			  
				end if;
			
    end if;
	
					
	
end process;

busy <= '0' when state_machine = idle else '1';

sda <= sda_out when sda_out_enable = '1' else 'Z';
scl <= scl_out when scl_out_enable = '1' else 'Z';

data_to_save<=listen_buffer;
listen_address<=address_for_listening;
talk_address<=address_for_talking;
listen_address_received<=listen_address_done;
talk_address_received<=talk_address_done;
send_done<=talk_done;
save_done<=listen_done;
end Behavioral;

