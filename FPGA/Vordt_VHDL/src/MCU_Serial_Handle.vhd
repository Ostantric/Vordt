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
    PORT (
            --in
            CLK : IN STD_LOGIC;
            TX_Done : IN STD_LOGIC;
            TX_ACTIVE : IN STD_LOGIC;
            RX_Done : IN STD_LOGIC;
            Velocity_Input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            Position_Input : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
            Turn_Input : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            Incoming_Packet : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            MCU_Ready : IN STD_LOGIC;
            --out
            TX_DV : OUT STD_LOGIC;
            --FPGA_UART_RX_Ready : OUT STD_LOGIC;
            Desired_Turn : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            Desired_Position : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            Desired_Max_Vel : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            Output_For_UART_TX : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
            );
end MCU_Serial_Handle;

architecture Behavioral of MCU_Serial_Handle is
    type TX_States is (Idle, Send_Position,Send_Velocity,Send_Turn, Wait_One);
    type RX_States is (Idle, Type_Check, Update_Desired_Position, Update_Desired_Max_Vel, Update_Desired_Turn,Wait_One);
    signal TX_State_Machine : TX_States := Idle;
    signal RX_State_Machine : RX_States := Idle;
    signal Receive_32bit_Register : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
    signal Transmit_32bit_Register : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000";
    signal Type_register : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"00";
    signal Tx_Byte_Count : integer range 0 to 11 :=0;
    signal Rx_Byte_Count : integer range 0 to 11 :=0;
    signal counter : integer :=0;
	 signal dv_signal : STD_LOGIC :='0';

    begin
    --Transmitter State Machine
    --Big-Endian
    TX_Machine : process (CLK)
    begin
        if rising_edge(CLK) then
            case TX_State_Machine is
                when Idle=>
                    if TX_ACTIVE = '0' then
                        TX_State_Machine<=Send_Position;
                    else
                        TX_State_Machine<=Wait_One;
                    end if;
                when Send_Position=>--Send Current Position-State    
                    case Tx_Byte_Count is
                        when 0 to 1 => -- Check if MCU Ready
                            Output_For_UART_TX<= x"01"; --Sending Position_Incoming Notice
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    if MCU_Ready = '1' then                            
                                        Tx_Byte_Count<=Tx_Byte_Count+1;
                                        counter<=0;
                                    else --try every 10000 tick
                                        if counter = 10000 then
                                            counter <= 0;
                                            Tx_Byte_Count<=0;
                                            Transmit_32bit_Register(15 Downto 0)<=Position_Input;
                                            TX_State_Machine<=Send_Position;  
                                        else
                                            counter<=counter+1;
                                        end if;
                                    end if;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 2 to 3=> --15 to 8
                            Output_For_UART_TX<=Transmit_32bit_Register(15 Downto 8);
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=Tx_Byte_Count+1;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 4 to 5=> -- 7 to 0
                            Output_For_UART_TX<=Transmit_32bit_Register(7 Downto 0);
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=Tx_Byte_Count+1;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when others =>
                            Transmit_32bit_Register<=x"00000000";
                            Tx_Byte_Count<=0;
                            TX_State_Machine<=Send_Velocity;  
                    end case;
                when Send_Velocity=>--Send Current Velocity-State
                    case Tx_Byte_Count is
                        when 0 to 1=> -- Check if MCU Ready
                            Output_For_UART_TX<= x"02"; --Sending Velocity_Incoming Notice
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    if MCU_Ready = '1' then                            
                                        Tx_Byte_Count<=Tx_Byte_Count+1;
                                        counter<=0;
                                        Transmit_32bit_Register(15 Downto 0)<=Velocity_Input;
                                    else --try every 10000 tick
                                        if counter = 10000 then
                                            counter <= 0;
                                            Tx_Byte_Count<=0;
                                            TX_State_Machine<=Send_Velocity;  
                                        else
                                            counter<=counter+1;
                                        end if;
                                    end if;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 2 to 3=> --15 to 8
                            Output_For_UART_TX<=Transmit_32bit_Register(15 Downto 8);
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=Tx_Byte_Count+1;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when 4 to 5=> -- 7 to 0
                            Output_For_UART_TX<=Transmit_32bit_Register(7 Downto 0);
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    Tx_Byte_Count<=Tx_Byte_Count+1;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                        when others =>
                            Transmit_32bit_Register<=x"00000000";
                            Tx_Byte_Count<=0;
                            TX_State_Machine<=Send_Turn;  
                    end case;                
                when Send_Turn=>--Send Current Turn-State              
                    case Tx_Byte_Count is
                        when 0 to 1=> -- Check if MCU Ready
                            Output_For_UART_TX<= x"03"; --Sending Turn_Incoming Notice
                            if tx_done = '1' then
                                dv_signal<='0';
                                if dv_signal='0' then
                                    if MCU_Ready = '1' then                            
                                        Tx_Byte_Count<=Tx_Byte_Count+1;
                                        counter<=0;
                                        Transmit_32bit_Register<=Turn_Input;
                                    else --try again every 10000 tick
                                        if counter = 10000 then
                                            counter <= 0;
                                            Tx_Byte_Count<=0;
                                            TX_State_Machine<=Send_Turn;  
                                        else
                                            counter<=counter+1;
                                        end if;
                                    end if;
                                end if;
                            else
                                dv_signal<='1';
                            end if;
                            when 2 to 3=> --31 to 24
                                Output_For_UART_TX<=Transmit_32bit_Register(31 Downto 24);
                                if tx_done = '1' then
                                    dv_signal<='0';
                                    if dv_signal='0' then
                                        Tx_Byte_Count<=Tx_Byte_Count+1;
                                    end if;
                                else
                                    dv_signal<='1';
                                end if;
                            when 4 to 5=> -- 23 to 16
                                Output_For_UART_TX<=Transmit_32bit_Register(23 Downto 16);
                                if tx_done = '1' then
                                    dv_signal<='0';
                                    if dv_signal='0' then
                                        Tx_Byte_Count<=Tx_Byte_Count+1;
                                    end if;
                                else
                                    dv_signal<='1';
                                end if;
                            when 6 to 7=> -- 15 to 8
                                Output_For_UART_TX<=Transmit_32bit_Register(15 Downto 8);
                                if tx_done = '1' then
                                    dv_signal<='0';
                                    if dv_signal='0' then
                                        Tx_Byte_Count<=Tx_Byte_Count+1;
                                    end if;
                                else
                                    dv_signal<='1';
                                end if;
                            when 8 to 9=> -- 7 to 0
                                Output_For_UART_TX<=Transmit_32bit_Register(7 Downto 0);
                                if tx_done = '1' then
                                    dv_signal<='0';
                                    if dv_signal='0' then
                                        Tx_Byte_Count<=Tx_Byte_Count+1;
                                    end if;
                                else
                                    dv_signal<='1';
                                end if;
                            when others =>
                                Transmit_32bit_Register<=x"00000000";
                                Tx_Byte_Count<=0;
                                TX_State_Machine<=Wait_One;  
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
    --Big-Endian
    RX_Machine : process (CLK)
    begin
        if falling_edge(CLK) then
            case RX_State_Machine is
                when Idle=>
                    if RX_Done = '1' then
                        Type_register<=Incoming_Packet;
                        RX_State_Machine<=Type_Check;
                    else
                        RX_State_Machine<=Idle;
                    end if;
                when Type_Check=> --Type 
                    Receive_32bit_Register<=x"00000000";
                    case Type_register is
                        when x"01"=> --desired_position
                            Rx_Byte_Count<=0;
                            RX_State_Machine<=Update_Desired_Position;
                        when x"02"=> --desired_max_velocity
                            Rx_Byte_Count<=0;
                            RX_State_Machine<=Update_Desired_Max_Vel;
                        when x"03"=> --desired_turn
                            Rx_Byte_Count<=0;    
                            RX_State_Machine<=Update_Desired_Turn;
                        when others=>
                            RX_State_Machine<=Idle;
                    end case;
                when Update_Desired_Position=> --Update Posiition for PID 
                    case Rx_Byte_Count is
                        when 0 to 1=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(15 DOWNTO 8)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 2 to 3=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(7 DOWNTO 0)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 4 to 5=>
                            Desired_Position<=Receive_32bit_Register(15 DOWNTO 0);
                            Rx_Byte_Count<=Rx_Byte_Count+1;
                        when others=>
                            Receive_32bit_Register<=x"00000000";
                            Rx_Byte_Count<=0;
                            RX_State_Machine<=Idle;
                    end case;
                when Update_Desired_Max_Vel=> --Update Max_Vel for PID
                    case Rx_Byte_Count is
                        when 0 to 1=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(15 DOWNTO 8)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 2 to 3=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(7 DOWNTO 0)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 4 to 5=>
                            Desired_Max_Vel<=Receive_32bit_Register(15 DOWNTO 0);
                            Rx_Byte_Count<=Rx_Byte_Count+1;
                        when others=>
                            Receive_32bit_Register<=x"00000000";
                            Rx_Byte_Count<=0;
                            RX_State_Machine<=Idle;
                    end case;

                when Update_Desired_Turn=> --Update Turn for PID
                    case Rx_Byte_Count is
                        when 0 to 1=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(31 DOWNTO 24)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 2 to 3=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(23 DOWNTO 16)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 4 to 5=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(15 DOWNTO 8)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 6 to 7=>
                            if RX_Done = '1' then
                                Receive_32bit_Register(7 DOWNTO 0)<=Incoming_Packet;
                                Rx_Byte_Count<=Rx_Byte_Count+1;
                            end if;
                        when 8 to 9=>
                            Desired_Turn<=Receive_32bit_Register;
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







    
