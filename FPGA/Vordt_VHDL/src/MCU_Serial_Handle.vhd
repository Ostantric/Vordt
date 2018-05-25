----------------------------------------------------------------------------------
-- Company: Mute's Design & Lab
-- Engineer: Murat Terzi
-- Credit : 
--
-- Create Date:    21:15:55 04/20/2018 
-- Design Name:
-- Module Name:    MCU_Handle 
-- Project Name: Vordt
-- Target Devices: XC6SLX9
-- Tool versions: 
-- Description: 
-- 
-- Dependencies: 
--
-- Revision: 04/21/2018
-- Revision 0.2 - Alpha Not tested
-- Additional Comments: 
-- Two State Machines are implemented
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

entity MCU_Serial_Handle is
	generic (
     MCU_Wait_Time : integer := 10;
     WaitIn : integer := 100 --give 10us to MCU 
   );
    PORT (
            --in
            CLK : IN STD_LOGIC;
            Reset : IN STD_LOGIC;
            RX_Reset: IN STD_LOGIC;
            TX_Done : IN STD_LOGIC;
            TX_ACTIVE : IN STD_LOGIC;
            RX_Done : IN STD_LOGIC;
            Motor1_Velocity_Input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            Motor1_Position_Input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            Motor1_Turn_Input : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            Motor2_Velocity_Input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            Motor2_Position_Input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            Motor2_Turn_Input : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            Incoming_Packet : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            MCU_Ready : IN STD_LOGIC;
            --out
            TX_DV : OUT STD_LOGIC;
            --FPGA_UART_RX_Ready : OUT STD_LOGIC;
            Motor1_Desired_Turn : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            Motor1_Desired_Position : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            Motor1_Desired_Max_Vel : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            Motor2_Desired_Turn : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            Motor2_Desired_Position : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            Motor2_Desired_Max_Vel : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            Output_For_UART_TX : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
            );
end MCU_Serial_Handle;

architecture Behavioral of MCU_Serial_Handle is
    type TX_States is (Idle, Send_Motor1_Position,Send_Motor2_Position,Send_Motor1_Velocity,Send_Motor2_Velocity,Send_Motor1_Turn,Send_Motor2_Turn, Wait_One);
    type RX_States is (Idle, Motor_Select, Motor1_Desired_Type_Check, Motor2_Desired_Type_Check, Update_Motor1_Desired_Position, Update_Motor2_Desired_Position, Update_Motor1_Desired_Max_Vel, Update_Motor2_Desired_Max_Vel,Update_Motor1_Desired_Turn,Update_Motor2_Desired_Turn,Wait_One);
    signal TX_State_Machine : TX_States;
    signal RX_State_Machine : RX_States;
    signal Receive_32bit_Register : STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal Transmit_32bit_Register : STD_LOGIC_VECTOR(31 DOWNTO 0);
    signal Type_register : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal Motor_Select_register : STD_LOGIC_VECTOR(7 DOWNTO 0);
    signal Tx_Byte_Count : integer range 0 to 11 :=0;
    signal Rx_Byte_Count : integer range 0 to 11 :=0;
    signal counter : integer range 0 to 1023;
	signal dv_signal : STD_LOGIC;

    --Two-Turning Complete Machines
    -- TX_Machine is responsible for updating MCU with current values
    -- RX_Machine is responsible for listening incoming desired setpoints
    begin
    --Transmitter State Machine
    --Little-Endian
    TX_Machine : process (CLK,Reset)
    begin
        if reset = '0' then
            TX_State_Machine<=idle;
            Tx_Byte_Count<=0;
            counter<=0;
            dv_signal<='0';
            Transmit_32bit_Register<=x"00000000";
        elsif rising_edge(CLK) then
            case TX_State_Machine is
                when Idle=>
                    if TX_ACTIVE = '0' then
                        TX_State_Machine<=Send_Motor1_Position;
                    else
                        TX_State_Machine<=Wait_One;
                    end if;
                when Send_Motor1_Position=>--Send Current Motor1 Position    
                    case Tx_Byte_Count is
                        when 0=>--Check if MCU Ready
                            if MCU_Ready = '1' then                            
                                Tx_Byte_Count<=1;
                                Output_For_UART_TX<= x"01"; --Motor1
                                counter<=0;
                            -- else --MCU_Wait_Time 
							-- 	if counter = MCU_Wait_Time then
							-- 	    counter <= 0;
							-- 		Tx_Byte_Count<=0;
							-- 		Tx_State_Machine<=Send_Position; --Send the notice again  
							-- 	else
							-- 		counter<=counter+1;
                            -- 	end if;
                            else
                                Tx_Byte_Count<=0;
                            end if;
                        when 1 => --wait little bit
                            if counter = WaitIn then
                                counter <= 0;
                                Tx_Byte_Count<=2;
                            else
                                counter<=counter+1;
                            end if;
                        when 2 => --Sending Motor1 notice
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=3;
                                    Output_For_UART_TX<= x"01";--Position notice
									counter<=0;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 3 => --Sending Position_Incoming Notice
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=4;
                                    Transmit_32bit_Register(15 Downto 0)<=Motor1_Position_Input;
									counter<=0;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 4=> --7 to 0
                            Output_For_UART_TX<=Transmit_32bit_Register(7 Downto 0);
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=5;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 5=> -- 15 to 8
                            Output_For_UART_TX<=Transmit_32bit_Register(15 Downto 8);
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=6;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when others =>
                            --Transmit_32bit_Register<=x"00000000";
                            if counter = MCU_Wait_Time then
                                counter <= 0;
                                Tx_Byte_Count<=0;
                                Tx_State_Machine<=Send_Motor2_Position;
                            else
                                   counter<=counter+1;
                            end if; 
                    end case;
                when Send_Motor2_Position=>--Send Current Motor2 Position    
                    case Tx_Byte_Count is
                        when 0=>--Check if MCU Ready
                            if MCU_Ready = '1' then                            
                                Tx_Byte_Count<=1;
                                Output_For_UART_TX<= x"02"; --Motor2
                                counter<=0;
                            -- else --MCU_Wait_Time 
							-- 	if counter = MCU_Wait_Time then
							-- 	    counter <= 0;
							-- 		Tx_Byte_Count<=0;
							-- 		Tx_State_Machine<=Send_Position; --Send the notice again  
							-- 	else
							-- 		counter<=counter+1;
                            -- 	end if;
                            else
                                Tx_Byte_Count<=0;
                            end if;
                        when 1 => --wait little bit
                            if counter = WaitIn then
                                counter <= 0;
                                Tx_Byte_Count<=2;
                            else
                                counter<=counter+1;
                            end if;
                        when 2 => --Sending Motor2 notice
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=3;
                                    Output_For_UART_TX<= x"01";--Position notice
									counter<=0;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 3 => --Sending Position_Incoming Notice
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=4;
                                    Transmit_32bit_Register(15 Downto 0)<=Motor2_Position_Input;
									counter<=0;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 4 => --7 to 0
                            Output_For_UART_TX<=Transmit_32bit_Register(7 Downto 0);
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=5;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 5 => -- 15 to 8
                            Output_For_UART_TX<=Transmit_32bit_Register(15 Downto 8);
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=6;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when others =>
                            --Transmit_32bit_Register<=x"00000000";
                            if counter = MCU_Wait_Time then
                                counter <= 0;
                                Tx_Byte_Count<=0;
                                Tx_State_Machine<=Send_Motor1_Velocity;
                            else
                                   counter<=counter+1;
                            end if; 
                    end case;
                when Send_Motor1_Velocity=>--Send Current Motor1 Velocity
                    case Tx_Byte_Count is
                        when 0=> --Check if MCU Ready
							if MCU_Ready = '1' then                            
							    Tx_Byte_Count<=1;
                                counter<=0;
                                Output_For_UART_TX<= x"01";
                            -- else --MCU_Wait_Time
							--     if counter = MCU_Wait_Time then
							-- 	    counter <= 0;
							-- 		Tx_Byte_Count<=0;
							-- 		Tx_State_Machine<=Send_Velocity; --Send the notice again
                            --     else
							-- 		counter<=counter+1;
                            --     end if;
                            else
                                Tx_Byte_Count<=0;
                            end if;
                        when 1 => --wait little bit
                            if counter = WaitIn then
                                counter <= 0;
                                Tx_Byte_Count<=2;
                            else
                                counter<=counter+1;
                            end if;
                        when 2 => --Sending Motor1 notice
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=3;
                                    Output_For_UART_TX<= x"02";--Velocity notice
									counter<=0;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 3=> --Sending Velocity_Incoming Notice
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=4;
                                    Transmit_32bit_Register(15 Downto 0)<=Motor1_Velocity_Input;
									counter<=0;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
								
                        when 4 => --7 to 0
                            Output_For_UART_TX<=Transmit_32bit_Register(7 Downto 0);
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=5;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 5 => -- 15 to 8
                            Output_For_UART_TX<=Transmit_32bit_Register(15 Downto 8);
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=6;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when others =>
                            --Transmit_32bit_Register<=x"00000000";
                            if counter = MCU_Wait_Time then
                                counter <= 0;
                                Tx_Byte_Count<=0;
                                Tx_State_Machine<=Send_Motor2_Velocity;
                            else
                                   counter<=counter+1;
                            end if; 
                    end case;
                when Send_Motor2_Velocity=>--Send Current Motor2 Velocity
                    case Tx_Byte_Count is
                        when 0=> --Check if MCU Ready
							if MCU_Ready = '1' then                            
							    Tx_Byte_Count<=1;
                                counter<=0;
                                Output_For_UART_TX<= x"02";
                            -- else --MCU_Wait_Time
							--     if counter = MCU_Wait_Time then
							-- 	    counter <= 0;
							-- 		Tx_Byte_Count<=0;
							-- 		Tx_State_Machine<=Send_Velocity; --Send the notice again
                            --     else
							-- 		counter<=counter+1;
                            --     end if;
                            else
                                Tx_Byte_Count<=0;
                            end if;
                        when 1 => --wait little bit
                            if counter = WaitIn then
                                counter <= 0;
                                Tx_Byte_Count<=2;
                            else
                                counter<=counter+1;
                            end if;
                        when 2 => --Sending Motor1 notice
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=3;
                                    Output_For_UART_TX<= x"02";--Velocity notice
									counter<=0;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 3=> --Sending Velocity_Incoming Notice
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=4;
                                    Transmit_32bit_Register(15 Downto 0)<=Motor2_Velocity_Input;
									counter<=0;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 4 => --7 to 0
                            Output_For_UART_TX<=Transmit_32bit_Register(7 Downto 0);
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=5;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 5 => -- 15 to 8
                            Output_For_UART_TX<=Transmit_32bit_Register(15 Downto 8);
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=6;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when others =>
                            --Transmit_32bit_Register<=x"00000000";
                            if counter = MCU_Wait_Time then
                                counter <= 0;
                                Tx_Byte_Count<=0;
                                Tx_State_Machine<=Send_Motor1_Turn;
                            else
                                   counter<=counter+1;
                            end if; 
                    end case;               
                when Send_Motor1_Turn=>--Send Current Turn-State              
                    case Tx_Byte_Count is
                        when 0 => --Check if MCU Ready
                            if MCU_Ready = '1' then                            
                                Tx_Byte_Count<=1;
                                Output_For_UART_TX<= x"01"; --Sending Turn_Incoming Notice
								counter<=0;
                            -- else --MCU_Wait_Time
							--     if counter = MCU_Wait_Time then
							-- 	    counter <= 0;
							-- 		Tx_Byte_Count<=0;
							-- 		Tx_State_Machine<=Send_Turn; --Send the notice again
                            --     else
							-- 		counter<=counter+1;
                            --     end if;
                            else
                                Tx_Byte_Count<=0;
                            end if;
                        when 1 =>
                            if counter = WaitIn then
                                counter <= 0;
                                Tx_Byte_Count<=2;
                            else
                                counter<=counter+1;
                            end if; 
                         when 2 => --Sending Motor1 notice
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=3;
                                    Output_For_UART_TX<= x"03";--Turn notice
									counter<=0;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 3=>
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=4;
                                    Transmit_32bit_Register<=Motor1_Turn_Input;
								    counter<=0;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 4 =>--0 to 7
                            Output_For_UART_TX<=Transmit_32bit_Register(7 Downto 0);
                            if tx_done = '1' then
                                  dv_signal<='0';
                                    if dv_signal='0' then
                                        Tx_Byte_Count<=5;
                                    end if;
                                else
                                    dv_signal<='1';
                                end if;
                        when 5 => --15 to 8
                                Output_For_UART_TX<=Transmit_32bit_Register(15 Downto 8);
                                if tx_done = '1' then
                                    dv_signal<='0';
                                    if dv_signal='0' then
                                        Tx_Byte_Count<=6;
                                    end if;
                                else
                                    dv_signal<='1';
                                end if;
                        when 6 => --23 to 16
                                Output_For_UART_TX<=Transmit_32bit_Register(23 Downto 16);
                                if tx_done = '1' then
                                    dv_signal<='0';
                                    if dv_signal='0' then
                                        Tx_Byte_Count<=7;
                                    end if;
                                else
                                    dv_signal<='1';
                                end if;
                        when 7 => --31 to 24
                                Output_For_UART_TX<=Transmit_32bit_Register(31 Downto 24);
                                if tx_done = '1' then
                                    dv_signal<='0';
                                    if dv_signal='0' then
                                        Tx_Byte_Count<=8;
                                    end if;
                                else
                                    dv_signal<='1';
                                end if;
                        when others =>
                                --Transmit_32bit_Register<=x"00000000";
                                if counter = MCU_Wait_Time then
                                    counter <= 0;
                                    Tx_Byte_Count<=0;
                                    Tx_State_Machine<=Send_Motor2_Turn;
                                else
                                   	counter<=counter+1;
                                end if;  
                    end case;
                when Send_Motor2_Turn=>--Send Current Turn-State              
                    case Tx_Byte_Count is
                        when 0 => --Check if MCU Ready
                            if MCU_Ready = '1' then                            
                                Tx_Byte_Count<=1;
                                Output_For_UART_TX<= x"02"; --Sending Turn_Incoming Notice
								counter<=0;
                            -- else --MCU_Wait_Time
							--     if counter = MCU_Wait_Time then
							-- 	    counter <= 0;
							-- 		Tx_Byte_Count<=0;
							-- 		Tx_State_Machine<=Send_Turn; --Send the notice again
                            --     else
							-- 		counter<=counter+1;
                            --     end if;
                            else
                                Tx_Byte_Count<=0;
                            end if;
                        when 1 =>
                            if counter = WaitIn then
                                counter <= 0;
                                Tx_Byte_Count<=2;
                            else
                                counter<=counter+1;
                            end if; 
                         when 2 => --Sending Motor1 notice
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=3;
                                    Output_For_UART_TX<= x"03";--Turn notice
									counter<=0;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 3=>
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=4;
                                    Transmit_32bit_Register<=Motor2_Turn_Input;
								    counter<=0;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 4 =>--0 to 7
                            Output_For_UART_TX<=Transmit_32bit_Register(7 Downto 0);
                            if tx_done = '1' then
                                  dv_signal<='0';
                                    if dv_signal='0' then
                                        Tx_Byte_Count<=5;
                                    end if;
                                else
                                    dv_signal<='1';
                                end if;
                        when 5 => --15 to 8
                                Output_For_UART_TX<=Transmit_32bit_Register(15 Downto 8);
                                if tx_done = '1' then
                                    dv_signal<='0';
                                    if dv_signal='0' then
                                        Tx_Byte_Count<=6;
                                    end if;
                                else
                                    dv_signal<='1';
                                end if;
                        when 6 => --23 to 16
                                Output_For_UART_TX<=Transmit_32bit_Register(23 Downto 16);
                                if tx_done = '1' then
                                    dv_signal<='0';
                                    if dv_signal='0' then
                                        Tx_Byte_Count<=7;
                                    end if;
                                else
                                    dv_signal<='1';
                                end if;
                        when 7 => --31 to 24
                                Output_For_UART_TX<=Transmit_32bit_Register(31 Downto 24);
                                if tx_done = '1' then
                                    dv_signal<='0';
                                    if dv_signal='0' then
                                        Tx_Byte_Count<=8;
                                    end if;
                                else
                                    dv_signal<='1';
                                end if;
                        when others =>
                                --Transmit_32bit_Register<=x"00000000";
                                if counter = MCU_Wait_Time then
                                    counter <= 0;
                                    Tx_Byte_Count<=0;
                                    Tx_State_Machine<=Send_Motor1_Position;
                                else
                                   	counter<=counter+1;
                                end if;  
                    end case;
                          
                when Wait_One =>
                    dv_signal<='0';
                    TX_State_Machine<=Idle;
                when others => 
                    dv_signal<='0';
                    TX_State_Machine<=Idle;
            end case;
        end if;
    end process TX_Machine;

    --Receiver State Machine
    --Little-Endian
    RX_Machine : process (CLK,RX_Reset)
    begin
        if RX_Reset = '0' then
            RX_State_Machine<=idle;
            Rx_Byte_Count<=0;
            Type_register<=x"00";
            Motor_Select_register<=x"00";
            Receive_32bit_Register<=x"00000000";
        elsif falling_edge(CLK) then
            case RX_State_Machine is
                when Idle=>
                    Type_register<=x"00";
                    if RX_Done = '1' then
                        Motor_Select_register<=Incoming_Packet;
                        RX_State_Machine<=Motor_Select;
                    else
                        RX_State_Machine<=Idle;
                    end if;
                when Motor_Select=> -- Motor Number
                    if RX_Done = '1' then
                        Type_register<=Incoming_Packet;
                        case Motor_Select_register is
                            when x"01"=> --Motor1 selected
                                RX_State_Machine<=Motor1_Desired_Type_Check;
                            when x"02"=> --Motor2 selected
                                RX_State_Machine<=Motor2_Desired_Type_Check;
                            when others =>
                                RX_State_Machine<=Idle;
                        end case;
                    else
                        RX_State_Machine<=Motor_Select;
                    end if;
                when Motor1_Desired_Type_Check=> --Motor1 Type check 
                    Receive_32bit_Register<=x"00000000";
                    Rx_Byte_Count<=0;
                    case Type_register is
                        when x"01"=> --Motor1_Desired_Position
                            RX_State_Machine<=Update_Motor1_Desired_Position;
                        when x"02"=> --Motor1_Desired_Max_Velocity
                            RX_State_Machine<=Update_Motor1_Desired_Max_Vel;
                        when x"03"=> --Motor1_Desired_Turn
                            RX_State_Machine<=Update_Motor1_Desired_Turn;
                        when others=>
                            RX_State_Machine<=Idle;
                    end case;
                when Update_Motor1_Desired_Position=> --Update Motor1 desired Position for PID 
                    case Rx_Byte_Count is
                        when 0=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(15 DOWNTO 8)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 1=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(7 DOWNTO 0)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 2=>
                            Motor1_Desired_Position<=Receive_32bit_Register(15 DOWNTO 0);
                            Rx_Byte_Count<=Rx_Byte_Count+1;
                        when others=>
                            Receive_32bit_Register<=x"00000000";
                            Rx_Byte_Count<=0;
                            RX_State_Machine<=Idle;
                    end case;
                when Update_Motor1_Desired_Max_Vel=> --Update Motor1 desired Max_Vel for PID
                    case Rx_Byte_Count is
                        when 0=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(15 DOWNTO 8)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 1=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(7 DOWNTO 0)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 2=>
                            Motor1_Desired_Max_Vel<=Receive_32bit_Register(15 DOWNTO 0);
                            Rx_Byte_Count<=Rx_Byte_Count+1;
                        when others=>
                            Receive_32bit_Register<=x"00000000";
                            Rx_Byte_Count<=0;
                            RX_State_Machine<=Idle;
                    end case;
                when Update_Motor1_Desired_Turn=> --Update Motor1 desired Turn for PID
                    case Rx_Byte_Count is
                        when 0=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(31 DOWNTO 24)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 1=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(23 DOWNTO 16)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 2=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(15 DOWNTO 8)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 3=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(7 DOWNTO 0)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 4=>
                            Motor1_Desired_Turn<=Receive_32bit_Register;
                            Rx_Byte_Count<=Rx_Byte_Count+1;
                        when others=>
                            Receive_32bit_Register<=x"00000000";
                            Rx_Byte_Count<=0;
                            RX_State_Machine<=Idle;
                    end case;
                when Motor2_Desired_Type_Check=> --Motor 2 Type check 
                    Receive_32bit_Register<=x"00000000";
                    Rx_Byte_Count<=0;
                    case Type_register is
                        when x"01"=> --Motor2_Desired_Position
                            RX_State_Machine<=Update_Motor2_Desired_Position;
                        when x"02"=> --Motor2_Desired_Max_Velocity
                            RX_State_Machine<=Update_Motor2_Desired_Max_Vel;
                        when x"03"=> --Motor2_Desired_Turn
                            RX_State_Machine<=Update_Motor2_Desired_Turn;
                        when others=>
                            RX_State_Machine<=Idle;
                    end case;
                when Update_Motor2_Desired_Position=> --Update Motor2 Desired Position for PID 
                    case Rx_Byte_Count is
                        when 0=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(15 DOWNTO 8)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 1=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(7 DOWNTO 0)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 2=>
                            Motor2_Desired_Position<=Receive_32bit_Register(15 DOWNTO 0);
                            Rx_Byte_Count<=Rx_Byte_Count+1;
                        when others=>
                            Receive_32bit_Register<=x"00000000";
                            Rx_Byte_Count<=0;
                            RX_State_Machine<=Idle;
                    end case;
                when Update_Motor2_Desired_Max_Vel=> --Update Motor2 Desired Max_Vel for PID
                    case Rx_Byte_Count is
                        when 0=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(15 DOWNTO 8)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 1=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(7 DOWNTO 0)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 2=>
                            Motor2_Desired_Max_Vel<=Receive_32bit_Register(15 DOWNTO 0);
                            Rx_Byte_Count<=Rx_Byte_Count+1;
                        when others=>
                            Receive_32bit_Register<=x"00000000";
                            Rx_Byte_Count<=0;
                            RX_State_Machine<=Idle;
                    end case;

                when Update_Motor2_Desired_Turn=> --Update Turn for PID
                    case Rx_Byte_Count is
                        when 0=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(31 DOWNTO 24)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 1=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(23 DOWNTO 16)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 2=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(15 DOWNTO 8)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 3=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(7 DOWNTO 0)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 4=>
                            Motor2_Desired_Turn<=Receive_32bit_Register;
                            Rx_Byte_Count<=Rx_Byte_Count+1;
                        when others=>
                            Receive_32bit_Register<=x"00000000";
                            Rx_Byte_Count<=0;
                            RX_State_Machine<=Idle;
                    end case;

                when Wait_One=>
                    Rx_Byte_Count<=0;
                    RX_State_Machine<=Idle;
                when others => 
                    Rx_Byte_Count<=0;
                    RX_State_Machine<=Idle;
            end case;
        end if;
    end process RX_Machine;

TX_DV<=dv_signal;

end Behavioral;







    
