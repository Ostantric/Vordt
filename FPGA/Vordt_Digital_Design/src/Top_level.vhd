----------------------------------------------------------------------------------
-- Company: Mute's Design & Lab
-- Engineer:  Murat Terzi
-- 
-- Create Date:    20:18:09 02/27/2018 
-- Design Name: 
-- Module Name:    Top_level - Structural 
-- Project Name: Vordt
-- Target Devices: XC6SLX9
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


use work.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Top_level is
PORT ( 
		CLK : IN STD_LOGIC;
		Encoder1_A : IN STD_LOGIC ;
		Encoder1_B : IN STD_LOGIC ;
		reset : IN STD_LOGIC;
		--adjust_speed : IN STD_LOGIC;
		Serial_TX : out STD_LOGIC;
		--storage_out : out STD_LOGIC_VECTOR(7 DOWNTO 0);
		--listen_Addres : out STD_LOGIC_VECTOR(7 DOWNTO 0);
		I2C_Slave_SDA : INOUT STD_LOGIC;
		I2C_Slave_SCL : INOUT STD_LOGIC;
		I2C_Master_SDA : INOUT STD_LOGIC;
		I2C_Master_SCL : INOUT STD_LOGIC
		);
end Top_level;

architecture Structural of Top_level is
--SIGNALS---------
signal Position_Signal : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal Velocity_Signal : STD_LOGIC_VECTOR(15 DOWNTO 0);

signal TX_Done_Signal : std_logic;
signal TX_Byte_Signal : std_logic_vector(7 downto 0);
signal TX_DV_Signal : std_logic;
signal TX_ACTIVE_signal : std_logic;

signal Desired_Velocity_Signal : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '1');
signal Desired_Position_Signal : STD_LOGIC_VECTOR(15 DOWNTO 0);

signal Sabertooth_INPUT : STD_LOGIC_VECTOR(23 DOWNTO 0);

signal I2C_Busy_Signal : STD_LOGIC;
signal I2C_ACK_Error_Signal : STD_LOGIC;
signal I2C_Reset_Signal : STD_LOGIC;
signal I2C_Enable_Signal: STD_LOGIC;
signal I2C_RW_Signal : STD_LOGIC;
signal I2C_Address_Signal : STD_LOGIC_VECTOR(6 DOWNTO 0);
signal I2C_Data_Write_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal I2C_Data_Read_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal I2C_Data_Read2_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);

signal Velocity_PID_SETPOINT_signal: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal Velocity_PID_OUTPUT_signal,Velocity_PID_Direction_signal : STD_LOGIC_VECTOR(7 DOWNTO 0);

signal Max_Speed_For_Position_PID_signal : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal Position_PID_SETPOINT_signal : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal Motor_Direction_Signal : STD_LOGIC_VECTOR(1 DOWNTO 0);
signal Turn_Count_Signal : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal Turn_Position_PID_SETPOINT_Signal : integer;
signal Test_velocity_PID_SETPOINT_Signal :STD_LOGIC_VECTOR(15 DOWNTO 0);
signal show_storage_input :STD_LOGIC_VECTOR(15 DOWNTO 0);

signal I2C_Slave_Busy_Signal : STD_LOGIC;
signal I2C_Slave_Listen_Address_Done_Signal : STD_LOGIC;
signal I2C_Slave_Talk_Address_Done_Signal : STD_LOGIC;
signal I2C_Slave_Send_Done_Signal : STD_LOGIC;
signal I2C_Slave_Save_Done_Signal : STD_LOGIC;
signal I2C_Slave_Sending_Signal :STD_LOGIC_VECTOR(7 DOWNTO 0);
signal I2C_Slave_Saving_Signal :STD_LOGIC_VECTOR(7 DOWNTO 0);
signal I2C_Slave_Listen_Adress_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal I2C_Slave_Talk_Adress_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);


signal Storage_RW_Signal : STD_LOGIC;
signal Storage_Enable_Signal : STD_LOGIC;
signal Storage_Address_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal Storage_Input_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal Storage_Output_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);


--PORT MAPS-------
begin
Decoder:entity work.Decoder
port map (CLK=>CLK,
			 Encoder1_A=>Encoder1_A,
			 Encoder1_B=>Encoder1_B,
			 Position=>position_signal,
			 Velocity=>Velocity_Signal,
			 Turn_Count=>Turn_Count_Signal
			 --Direction=>Motor_Direction_Signal
);



UART_Transmitter:entity work.UART_TX
port map (i_CLK=>CLK,
		    i_TX_DV=>TX_DV_Signal,
			 i_TX_Byte =>TX_Byte_Signal,
			 o_TX_Serial =>Serial_TX,
			 o_TX_Done =>TX_Done_Signal,
			 o_TX_Active=>TX_ACTIVE_signal
);

Sabertooth_Driver:entity work.Sabertooth_Packetized_Serial_Driver
port map (CLK=>CLK,
		    TX_Done=>TX_Done_Signal,
			 TX_ACTIVE =>TX_ACTIVE_signal,
			 TX_DV =>TX_DV_Signal,
			 Input =>Sabertooth_INPUT,
			 Output_Command=>Tx_Byte_Signal
);

I2C_Handler:entity work.I2C_Handler
port map (CLK=>CLK,
			 reset=>reset,
			 --master_module signals
			 --velocity_input=>x"00" & Velocity_PID_OUTPUT_signal,
			 --velocity_input=>Velocity_Signal,
			 --position_input=>x"00" & Velocity_PID_OUTPUT_signal,
			 --position_input=>x"00" & Storage_Address_Signal,

			 position_input=>Position_Signal,
			 velocity_input=>Velocity_Signal,
			 pid_velocity_input=>Velocity_PID_Direction_signal & Velocity_PID_OUTPUT_signal,
			 pid_position_input=>test_Velocity_PID_SETPOINT_signal,
			 storage_input=>x"00" & I2C_Slave_Saving_Signal,
			 
			 turn_input=>Turn_Count_Signal,
			 busy=>I2C_Busy_Signal,
			 slave_address=>I2C_Address_Signal,
			 Data_for_write=>I2C_Data_Write_Signal,
			 enable_I2C_Module=>I2C_Enable_Signal,
			 read_write_signal=>I2C_RW_Signal
			 --slave_module signals
			 --slave_module_busy=>I2C_Slave_Busy_Signal,
			 --listen_address_came=>I2C_Slave_Listen_Address_Done_Signal,
			 --talk_address_came=>I2C_Slave_Talk_Address_Done_Signal,
			 --listen_address=>I2C_Slave_Listen_Adress_Signal,
			 --talk_address=>I2C_Slave_Talk_Adress_Signal,
			 --save_done=>I2C_Slave_Save_Done_Signal,
			 --data_for_sending=>I2C_Slave_Sending_Signal,
			 --data_for_saving=>I2C_Slave_Saving_Signal,
			 --data_storage signals
			 --address_for_storage=>Storage_Address_Signal,
			 --data_for_storage=>Storage_Input_Signal,
			 --data_from_storage=>Storage_Output_Signal,
			 --enable_storage=>Storage_Enable_Signal,
			 --RW_storage=>Storage_RW_Signal
);

I2C_Slave_Module:entity work.I2C_Slave_Module
port map(
		clk=>CLK,
		reset_n=>reset,
		busy=>I2C_Slave_Busy_Signal,
		send_done=>I2C_Slave_Send_Done_Signal,
		save_done=>I2C_Slave_Save_Done_Signal,
		listen_address_received=>I2C_Slave_Listen_Address_Done_Signal,
		talk_address_received=>I2C_Slave_Talk_Address_Done_Signal,
		data_to_send=>I2C_Slave_Sending_Signal,
		data_to_save=>I2C_Slave_Saving_Signal,
		listen_address=>I2C_Slave_Listen_Adress_Signal,
		talk_address=>I2C_Slave_Talk_Adress_Signal,
		sda=>I2C_Slave_SDA,
		scl=>I2C_Slave_SCL		
);


I2C_Master_Module:entity work.I2C_Module
port map (CLK=>CLK,
			 reset_n=>reset,
			 addr=>I2C_Address_Signal,
			 data_wr=>I2C_Data_Write_Signal,
			 ena=>I2C_Enable_Signal,
			 rw=>I2C_RW_Signal,
		    SDA=>I2C_Master_SDA, 
			 SCL=>I2C_Master_SCL,
			 busy=>I2C_Busy_Signal,
			 data_rd=>I2C_Data_Read_Signal,
			 ack_error=>I2C_ACK_Error_Signal
);

--Data_Storage:entity work.Data_Storage
--port map (CLK=>CLK,
--			RW=>Storage_RW_Signal,
--			enable=>Storage_Enable_Signal,
--			Input=>Storage_Input_Signal,
--			Address=>Storage_Address_Signal,
--			--Output=>Storage_Output_Signal
--			Output=>storage_out
--);

Velocity_PID:entity work.Velocity_PID_Controller
port map (CLK=>CLK,
			 reset_n=>reset,
			 --Set_point=>Velocity_PID_SETPOINT_signal,
			 Set_point=>Test_velocity_PID_SETPOINT_Signal,
			 --Set_point=>x"00" & Storage_Input_Signal,
			 Feedback=>Velocity_Signal,
			 Output_Command=>Velocity_PID_OUTPUT_signal,
			 Direction_Command=>Velocity_PID_Direction_signal
);

--Position_PID:entity work.Position_PID_Controller
--port map (CLK=>CLK,
--			 Max_Speed=>Max_Speed_For_Position_PID_signal,
--			 Position_Set_point=>Position_PID_SETPOINT_signal,
--			 Turn_Set_point=>std_logic_vector(to_signed(Turn_Position_PID_SETPOINT_Signal,32)),
--			 Position_Feedback=>Position_Signal,
--			 Turn_Feedback=>Turn_Count_Signal,
--			 Output_Command=>Velocity_PID_SETPOINT_signal
--);



--Seven_segment_driver:entity work.Seven_segment_driver
--port map (CLK=>CLK,
--		    input=>position_signal,
--			 led =>led,
--			 seg =>seg,
--			 an =>an
--			 
--);

--Velocity_PID_Controller:entity work.Velocity_PID_Controller
--port map (CLK=>CLK,
--			 Feedback=>Velocity_Signal,
--			 Input =>Desired_Velocity_Signal,
--		    Output_Command=>Tx_Byte_Signal,
--			 TX_DV=>TX_DV_Signal,
--			 TX_Done=>TX_Done_Signal,
--			 TX_ACTIVE=>TX_ACTIVE_signal
--);

--Position_PID_Controller:entity work.Position_PID_Controller
--port map (CLK=>CLK,
--			 Feedback=>Position_Signal,
--			 Input =>Desired_Position_Signal,
--		    Output_Command=>TX_Byte_Signal,
--			 TX_Done=>TX_Done_Signal
--);
--Velocity_PID_SETPOINT_signal<=x"0090" when adjust_speed = '1' else
--										x"0000";
										
--Max_Speed_For_Position_PID_signal<=x"0025" when adjust_speed = '1' else
--											  x"000A";
--Position_PID_SETPOINT_signal<=x"4000";
--Turn_Position_PID_SETPOINT_Signal<=0;

--Test_velocity_PID_SETPOINT_Signal<=x"00" & Storage_Input_Signal;
Test_velocity_PID_SETPOINT_Signal<= x"00" & I2C_Slave_Saving_Signal;

--Test_velocity_PID_SETPOINT_Signal<=x"FFD5" when adjust_speed = '1' else
--											  x"0030";
--Test_velocity_PID_SETPOINT_Signal<=x"0015";
show_storage_input<=x"00" & Storage_Input_Signal;
Sabertooth_INPUT(23 Downto 16)<=std_logic_vector(to_unsigned(128,8)); --address
Sabertooth_INPUT(15 downto 8)<=Velocity_PID_Direction_signal;
Sabertooth_INPUT(7 Downto 0)<=Velocity_PID_OUTPUT_signal;

--Sabertooth_INPUT(15 downto 8)<=std_logic_vector(to_unsigned(0,8)); -- motor no. and direction(check documentation)
--Sabertooth_INPUT(7 Downto 0)<=std_logic_vector(to_unsigned(15,8)); -- power

--send_done<=I2C_Slave_Send_Done_Signal;
--listen_Addres<=I2C_Slave_Listen_Adress_Signal;
end Structural;

