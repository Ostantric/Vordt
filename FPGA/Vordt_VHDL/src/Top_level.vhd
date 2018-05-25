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
		reset : IN STD_LOGIC;
		UART_RX_Reset : IN STD_LOGIC;
		Motor1_Decoder_Reset : IN STD_LOGIC;
		Motor2_Decoder_Reset : IN STD_LOGIC;
		Encoder1_A : IN STD_LOGIC ;
		Encoder1_B : IN STD_LOGIC ;
		Encoder2_A : IN STD_LOGIC ;
		Encoder2_B : IN STD_LOGIC ;
		
		--adjust_speed : IN STD_LOGIC;
		Sabertooth_Serial_TX : out STD_LOGIC;
		MCU_Serial_TX : out STD_LOGIC;
		MCU_Serial_RX : in STD_LOGIC;
		MCU_Ready_For_UART_TX : in STD_LOGIC;
		--storage_out : out STD_LOGIC_VECTOR(7 DOWNTO 0);
		--listen_Addres : out STD_LOGIC_VECTOR(7 DOWNTO 0);
		--I2C_Slave_SDA : INOUT STD_LOGIC;
		--I2C_Slave_SCL : INOUT STD_LOGIC;
		M1D_I2C_Master_SDA : INOUT STD_LOGIC;
		M1D_I2C_Master_SCL : INOUT STD_LOGIC;
		M2D_I2C_Master_SDA : INOUT STD_LOGIC;
		M2D_I2C_Master_SCL : INOUT STD_LOGIC
		);
end Top_level;

architecture Structural of Top_level is

---------------------------------------SIGNALS---------------------------------------
-----------Motor1----------------------------------------------
---Feedback---
signal Motor1_position_signal : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal Motor1_Velocity_Signal : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal Motor1_Turn_Count_Signal : STD_LOGIC_VECTOR(31 DOWNTO 0);
---PID---
signal Motor1_Position_PID_SETPOINT_Signal : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal Motor1_Turn_PID_SETPOINT_Signal : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal Motor1_Velocity_PID_SETPOINT_signal: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal Motor1_Velocity_PID_OUTPUT_signal,Motor1_Velocity_PID_Direction_signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal Motor1_Max_Speed_For_Position_PID_signal : STD_LOGIC_VECTOR(15 DOWNTO 0);
-----------Motor2----------------------------------------------
---Feedback---
signal Motor2_position_signal : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal Motor2_Velocity_Signal : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal Motor2_Turn_Count_Signal : STD_LOGIC_VECTOR(31 DOWNTO 0);
---PID---
signal Motor2_Position_PID_SETPOINT_Signal : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal Motor2_Turn_PID_SETPOINT_Signal : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal Motor2_Velocity_PID_SETPOINT_signal: STD_LOGIC_VECTOR(15 DOWNTO 0);
signal Motor2_Velocity_PID_OUTPUT_signal,Motor2_Velocity_PID_Direction_signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal Motor2_Max_Speed_For_Position_PID_signal : STD_LOGIC_VECTOR(15 DOWNTO 0);
-----------Sabertooth----------------------------------------------
signal Sabertooth_TX_Done_Signal : std_logic;
signal Sabertooth_TX_Byte_Signal : std_logic_vector(7 downto 0);
signal Sabertooth_TX_DV_Signal : std_logic;
signal Sabertooth_TX_ACTIVE_signal : std_logic;
--signal Sabertooth_Motor1_INPUT : STD_LOGIC_VECTOR(23 DOWNTO 0);
--signal Sabertooth_Motor2_INPUT : STD_LOGIC_VECTOR(23 DOWNTO 0);
-----------MCU COM----------------------------------------------
---Transmitter---
signal MCU_TX_Done_Signal : std_logic;
signal MCU_TX_Byte_Signal : std_logic_vector(7 downto 0);
signal MCU_TX_DV_Signal : std_logic;
signal MCU_TX_ACTIVE_signal : std_logic;
---Receiver---
signal MCU_RX_DV_Signal : std_logic;
signal MCU_RX_Byte_Signal : std_logic_vector(7 downto 0);
-----------I2C COM----------------------------------------------
---Master & Handler---
signal M1D_I2C_Busy_Signal : STD_LOGIC;
signal M1D_I2C_ACK_Error_Signal : STD_LOGIC;
signal M1D_I2C_Reset_Signal : STD_LOGIC;
signal M1D_I2C_Enable_Signal: STD_LOGIC;
signal M1D_I2C_Address_Signal : STD_LOGIC_VECTOR(6 DOWNTO 0);
signal M1D_I2C_Data_Write_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal M1D_I2C_Data_Read_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);

signal M2D_I2C_Busy_Signal : STD_LOGIC;
signal M2D_I2C_ACK_Error_Signal : STD_LOGIC;
signal M2D_I2C_Reset_Signal : STD_LOGIC;
signal M2D_I2C_Enable_Signal: STD_LOGIC;
signal M2D_I2C_Address_Signal : STD_LOGIC_VECTOR(6 DOWNTO 0);
signal M2D_I2C_Data_Write_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal M2D_I2C_Data_Read_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);

signal I2C_RW_Signal : STD_LOGIC;
---Slave & Handler---
signal I2C_Slave_Busy_Signal : STD_LOGIC;
signal I2C_Slave_Listen_Address_Done_Signal : STD_LOGIC;
signal I2C_Slave_Talk_Address_Done_Signal : STD_LOGIC;
signal I2C_Slave_Send_Done_Signal : STD_LOGIC;
signal I2C_Slave_Save_Done_Signal : STD_LOGIC;
signal I2C_Slave_Sending_Signal :STD_LOGIC_VECTOR(7 DOWNTO 0);
signal I2C_Slave_Saving_Signal :STD_LOGIC_VECTOR(7 DOWNTO 0);
signal I2C_Slave_Listen_Adress_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal I2C_Slave_Talk_Adress_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
-----------Storage----------------------------------------------
---NOTE:FOR FUTURE USE---
signal Storage_RW_Signal : STD_LOGIC;
signal Storage_Enable_Signal : STD_LOGIC;
signal Storage_Address_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal Storage_Input_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal Storage_Output_Signal : STD_LOGIC_VECTOR(7 DOWNTO 0);
-----------Debugging Purposes----------------------------------------------
signal Test_Motor1_Position_PID_SETPOINT_Signal : STD_LOGIC_VECTOR(15 DOWNTO 0);
signal Test_Motor1_Turn_PID_SETPOINT_Signal : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal Test_Motor1_Velocity_PID_SETPOINT_signal :STD_LOGIC_VECTOR(15 DOWNTO 0);
signal show_storage_input :STD_LOGIC_VECTOR(15 DOWNTO 0);
------------------------------SIGNALS END------------------------------

--------------PORT MAPS--------------
begin
-----Motor1 Entities-----
Motor1_Decoder:entity work.Decoder
port map (CLK=>CLK,
			 Reset_D=>Motor1_Decoder_Reset,
			 --Reset=>reset,
			 Encoder_A=>Encoder1_A,
			 Encoder_B=>Encoder1_B,
			 Position=>Motor1_position_signal,
			 Velocity=>Motor1_Velocity_Signal,
			 Turn_Count=>Motor1_Turn_Count_Signal
);

Motor1_Velocity_PID_Controller:entity work.Velocity_PID_Controller
port map (CLK=>CLK,
			 reset_n=>reset,
			 Set_point=>Motor1_Velocity_PID_SETPOINT_signal,
			-- Set_point=>Test_Motor1_Velocity_PID_SETPOINT_signal,
			 --Set_point=>x"00" & Storage_Input_Signal,
			 Feedback=>Motor1_Velocity_Signal,
			 Output_Command=>Motor1_Velocity_PID_OUTPUT_signal,
			 Motor_Number=> '0', --Motor Number 1
			 Direction_Command=>Motor1_Velocity_PID_Direction_signal
);

Motor1_Position_PID_Controller:entity work.Position_PID_Controller
port map (CLK=>CLK,
			 Reset=>reset,
			 Max_Speed=>Motor1_Max_Speed_For_Position_PID_signal,
			 --Position_Set_point=>Test_Motor1_Position_PID_SETPOINT_Signal,
			 Position_Set_Point=>Motor1_Position_PID_SETPOINT_Signal,
			 --Position_Set_point=>x"5000",
			 --Turn_Set_point=>std_logic_vector(to_signed(Motor1_Turn_PID_SETPOINT_Signal,32)),
			 --Turn_Set_point=>Test_Motor1_Turn_PID_SETPOINT_Signal,
			 Turn_Set_Point=>Motor1_Turn_PID_SETPOINT_Signal,
			 Position_Feedback=>Motor1_position_signal,
			 Turn_Feedback=>Motor1_Turn_Count_Signal,
			 Output_Command=>Motor1_Velocity_PID_SETPOINT_signal
);
-----Motor2 Entities-----
Motor2_Decoder:entity work.Decoder
port map (CLK=>CLK,
			 Reset_D=>Motor2_Decoder_Reset,
			 --Reset=>reset,
			 Encoder_A=>Encoder2_A,
			 Encoder_B=>Encoder2_B,
			 Position=>Motor2_position_signal,
			 Velocity=>Motor2_Velocity_Signal,
			 Turn_Count=>Motor2_Turn_Count_Signal
);

Motor2_Velocity_PID_Controller:entity work.Velocity_PID_Controller
port map (CLK=>CLK,
			 reset_n=>reset,
			 Set_point=>Motor2_Velocity_PID_SETPOINT_signal,
			 Feedback=>Motor2_Velocity_Signal,
			 Output_Command=>Motor2_Velocity_PID_OUTPUT_signal,
			 Motor_Number=> '1', -- Motor Number 2
			 Direction_Command=>Motor2_Velocity_PID_Direction_signal
);

Motor2_Position_PID_Controller:entity work.Position_PID_Controller
port map (CLK=>CLK,
			 Reset=>reset,
			 Max_Speed=>Motor2_Max_Speed_For_Position_PID_signal,
			 Position_Set_Point=>Motor2_Position_PID_SETPOINT_Signal,
			 Turn_Set_Point=>Motor2_Turn_PID_SETPOINT_Signal,
			 Position_Feedback=>Motor2_position_signal,
			 Turn_Feedback=>Motor2_Turn_Count_Signal,
			 Output_Command=>Motor2_Velocity_PID_SETPOINT_signal
);
-----MCU COM Entities----
MCU_UART_Transmitter:entity work.MCU_UART_TX
--Baudrate is 4M
--50M/4M = 12.5
--CLKS_PER_BIT = 12
port map (i_CLK=>CLK,
		    i_TX_DV=>MCU_TX_DV_Signal,
			 i_TX_Byte =>MCU_TX_Byte_Signal,
			 o_TX_Serial =>MCU_Serial_TX,
			 o_TX_Done =>MCU_TX_Done_Signal,
			 o_TX_Active=>MCU_TX_ACTIVE_signal
);

MCU_UART_Receiver:entity work.MCU_UART_RX
--Baudrate is 4M
--50M/4M = 12.5
--CLKS_PER_BIT = 12
port map (i_CLK=>CLK,
			i_RX_Serial =>MCU_Serial_RX,
			o_RX_DV => MCU_RX_DV_Signal,
			o_RX_Byte => MCU_RX_Byte_Signal
);

MCU_Serial_Handle:entity work.MCU_Serial_Handle
port map (CLK=>CLK,
			reset=>reset,
			RX_Reset=>UART_RX_Reset,
			TX_Done =>MCU_TX_Done_Signal,
            TX_ACTIVE => MCU_TX_ACTIVE_signal,
            RX_Done => MCU_RX_DV_Signal,
            Motor1_Velocity_Input =>Motor1_Velocity_Signal,
            Motor1_Position_Input =>Motor1_position_signal,
			Motor1_Turn_Input =>Motor1_Turn_Count_Signal,
			Motor2_Velocity_Input =>Motor2_Velocity_Signal,
            Motor2_Position_Input =>Motor2_position_signal,
            Motor2_Turn_Input =>Motor2_Turn_Count_Signal,
            Incoming_Packet =>MCU_RX_Byte_Signal,
            MCU_Ready =>MCU_Ready_For_UART_TX,
            --out
            TX_DV =>MCU_TX_DV_Signal,
            --FPGA_UART_RX_Ready : OUT STD_LOGIC;
            Motor1_Desired_Turn =>Motor1_Turn_PID_SETPOINT_Signal,
            Motor1_Desired_Position =>Motor1_Position_PID_SETPOINT_Signal,
			Motor1_Desired_Max_Vel =>Motor1_Max_Speed_For_Position_PID_signal,
			Motor2_Desired_Turn =>Motor2_Turn_PID_SETPOINT_Signal,
            Motor2_Desired_Position =>Motor2_Position_PID_SETPOINT_Signal,
            Motor2_Desired_Max_Vel =>Motor2_Max_Speed_For_Position_PID_signal,
            Output_For_UART_TX =>MCU_TX_Byte_Signal
			
);
-----Sabertooth Entities----
Sabertooth_UART_Transmitter:entity work.Sabertooth_UART_TX 
--Baudrate is 9600
--50M/9600=5208.3333
--CLKS_PER_BIT = 5209
port map (i_CLK=>CLK,
		    i_TX_DV=>Sabertooth_TX_DV_Signal,
			 i_TX_Byte =>Sabertooth_TX_Byte_Signal,
			 o_TX_Serial =>Sabertooth_Serial_TX,
			 o_TX_Done =>Sabertooth_TX_Done_Signal,
			 o_TX_Active=>Sabertooth_TX_ACTIVE_signal
);

Sabertooth_Driver:entity work.Sabertooth_Packetized_Serial_Driver
port map (CLK=>CLK,
		    Reset=>Reset,
		    TX_Done=>Sabertooth_TX_Done_Signal,
			 TX_ACTIVE =>Sabertooth_TX_ACTIVE_signal,
			 TX_DV =>Sabertooth_TX_DV_Signal,
			 --Motor1_Input =>Sabertooth_Motor1_INPUT,
			 --Motor2_Input =>Sabertooth_Motor2_INPUT,
			 Motor1_Direction=>Motor1_Velocity_PID_Direction_signal,
			 Motor1_Power=>Motor1_Velocity_PID_OUTPUT_signal,
			 Motor2_Direction=>Motor2_Velocity_PID_Direction_signal,
			 Motor2_Power=>Motor2_Velocity_PID_OUTPUT_signal,
			 Output_Command=>Sabertooth_Tx_Byte_Signal
);
-----I2C Entities----
I2C_Handler:entity work.I2C_Handler
port map (CLK=>CLK,
			 reset=>reset,
			 --master_module signals
			 --velocity_input=>x"00" & Motor1_Velocity_PID_OUTPUT_signal,
			 --velocity_input=>Motor1_Velocity_Signal,
			 --position_input=>x"00" & Motor1_Velocity_PID_OUTPUT_signal,
			 --position_input=>x"00" & Storage_Address_Signal,


			 --position_input=>x"1234",
			 Motor1_Displays_position_input=>Motor1_position_signal,
			 Motor1_Displays_velocity_input=>Motor1_Velocity_Signal,
			 Motor1_Displays_PID_Velocity_input=>Motor1_Velocity_PID_Direction_signal & Motor1_Velocity_PID_OUTPUT_signal,
			 Motor1_Displays_PID_Position_Input=>Motor1_Velocity_PID_SETPOINT_signal,
			 Motor1_Displays_storage_input=>I2C_Slave_Saving_Signal & x"00",
			 Motor1_Displays_turn_input=>Motor1_Turn_Count_Signal,
			 
			 Motor1_Displays_busy=>M1D_I2C_Busy_Signal,
			 Motor1_Displays_slave_address=>M1D_I2C_Address_Signal,
			 Motor1_Displays_Data_for_write=>M1D_I2C_Data_Write_Signal,
			 Motor1_Displays_enable_I2C_Module=>M1D_I2C_Enable_Signal,

			 Motor2_Displays_position_input=>Motor2_position_signal,
			 Motor2_Displays_velocity_input=>Motor2_Velocity_Signal,
			 Motor2_Displays_PID_Velocity_input=>Motor2_Velocity_PID_Direction_signal & Motor2_Velocity_PID_OUTPUT_signal,
			 Motor2_Displays_PID_Position_Input=>Motor2_Velocity_PID_SETPOINT_signal,
			 Motor2_Displays_storage_input=>I2C_Slave_Saving_Signal & x"00",
			 Motor2_Displays_turn_input=>Motor2_Turn_Count_Signal,
			 
			 Motor2_Displays_busy=>M2D_I2C_Busy_Signal,
			 Motor2_Displays_slave_address=>M2D_I2C_Address_Signal,
			 Motor2_Displays_Data_for_write=>M2D_I2C_Data_Write_Signal,
			 Motor2_Displays_enable_I2C_Module=>M2D_I2C_Enable_Signal,

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

-- I2C_Slave_Module:entity work.I2C_Slave_Module
-- port map(
-- 		clk=>CLK,
-- 		reset_n=>reset,
-- 		busy=>I2C_Slave_Busy_Signal,
-- 		send_done=>I2C_Slave_Send_Done_Signal,
-- 		save_done=>I2C_Slave_Save_Done_Signal,
-- 		listen_address_received=>I2C_Slave_Listen_Address_Done_Signal,
-- 		talk_address_received=>I2C_Slave_Talk_Address_Done_Signal,
-- 		data_to_send=>I2C_Slave_Sending_Signal,
-- 		data_to_save=>I2C_Slave_Saving_Signal,
-- 		listen_address=>I2C_Slave_Listen_Adress_Signal,
-- 		talk_address=>I2C_Slave_Talk_Adress_Signal,
-- 		sda=>I2C_Slave_SDA,
-- 		scl=>I2C_Slave_SCL		
-- );

Motor1_Displays_I2C_Master_Module:entity work.I2C_Module
port map (CLK=>CLK,
			 reset_n=>reset,
			 addr=>M1D_I2C_Address_Signal,
			 data_wr=>M1D_I2C_Data_Write_Signal,
			 ena=>M1D_I2C_Enable_Signal,
			 rw=>I2C_RW_Signal,
		     SDA=>M1D_I2C_Master_SDA, 
			 SCL=>M1D_I2C_Master_SCL,
			 busy=>M1D_I2C_Busy_Signal,
			 data_rd=>M1D_I2C_Data_Read_Signal,
			 ack_error=>M1D_I2C_ACK_Error_Signal
);

Motor2_Displays_I2C_Master_Module:entity work.I2C_Module
port map (CLK=>CLK,
			 reset_n=>reset,
			 addr=>M2D_I2C_Address_Signal,
			 data_wr=>M2D_I2C_Data_Write_Signal,
			 ena=>M2D_I2C_Enable_Signal,
			 rw=>I2C_RW_Signal,
		     SDA=>M2D_I2C_Master_SDA, 
			 SCL=>M2D_I2C_Master_SCL,
			 busy=>M2D_I2C_Busy_Signal,
			 data_rd=>M2D_I2C_Data_Read_Signal,
			 ack_error=>M2D_I2C_ACK_Error_Signal
);

--FUTURE USE--
--Data_Storage:entity work.Data_Storage
--port map (CLK=>CLK,
--			RW=>Storage_RW_Signal,
--			enable=>Storage_Enable_Signal,
--			Input=>Storage_Input_Signal,
--			Address=>Storage_Address_Signal,
--			--Output=>Storage_Output_Signal
--			Output=>storage_out
--);




--Seven_segment_driver:entity work.Seven_segment_driver
--port map (CLK=>CLK,
--		    input=>Motor1_position_signal,
--			 led =>led,
--			 seg =>seg,
--			 an =>an
--			 
--);


--Motor1_Velocity_PID_SETPOINT_signal<=x"0090" when adjust_speed = '1' else
--										x"0000";
										
--Motor1_Max_Speed_For_Position_PID_signal<=x"0025" when adjust_speed = '1' else
--											  x"000A";

Test_Motor1_Turn_PID_SETPOINT_Signal<=x"00000000";
--Motor1_Max_Speed_For_Position_PID_signal<=x"0080";

--Motor1_Position_PID_SETPOINT_Signal<=x"4000";
--Motor1_Turn_PID_SETPOINT_Signal<=0;
--Test_Motor1_Velocity_PID_SETPOINT_signal<=x"00" & Storage_Input_Signal;

Test_Motor1_Velocity_PID_SETPOINT_signal<= x"00" & I2C_Slave_Saving_Signal;
Test_Motor1_Position_PID_SETPOINT_Signal<= I2C_Slave_Saving_Signal & x"00";

--Test_Motor1_Velocity_PID_SETPOINT_signal<=x"FFD5" when adjust_speed = '1' else
--											  x"0030";
--Test_Motor1_Velocity_PID_SETPOINT_signal<=x"0015";

--show_storage_input<=x"00" & Storage_Input_Signal;
--Sabertooth_Motor1_INPUT(23 Downto 16)<=std_logic_vector(to_unsigned(128,8)); --address
--Sabertooth_Motor1_INPUT(15 downto 8)<=Motor1_Velocity_PID_Direction_signal;
--Sabertooth_Motor1_INPUT(7 Downto 0)<=Motor1_Velocity_PID_OUTPUT_signal;

--Sabertooth_Motor2_INPUT(23 Downto 16)<=std_logic_vector(to_unsigned(128,8)); --address
--Sabertooth_Motor2_INPUT(15 downto 8)<=Motor2_Velocity_PID_Direction_signal;
--Sabertooth_Motor2_INPUT(7 Downto 0)<=Motor2_Velocity_PID_OUTPUT_signal;

--Sabertooth_INPUT(15 downto 8)<=std_logic_vector(to_unsigned(0,8)); -- motor no. and direction(check documentation)
--Sabertooth_INPUT(7 Downto 0)<=std_logic_vector(to_unsigned(15,8)); -- power

--send_done<=I2C_Slave_Send_Done_Signal;
--listen_Addres<=I2C_Slave_Listen_Adress_Signal;
end Structural;

