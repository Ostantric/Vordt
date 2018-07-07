#include <iostream>
#include <stdio.h>
#include "driver/uart.h"
#include "driver/gpio.h"
#include "esp_system.h"
#include <stdarg.h>
class MCP_Advanced
{
    uint16_t crc;
	int timeout;
    uart_port_t uart_num;
	//uint8_t *read_buffer = (uint8_t *) malloc(100);
    /*******Registers***********/
    enum {  M1FORWARD = 0,
			M1BACKWARD = 1,
			SETMINMB = 2,
			SETMAXMB = 3,
			M2FORWARD = 4,
			M2BACKWARD = 5,
			M17BIT = 6,
			M27BIT = 7,
			MIXEDFORWARD = 8,
			MIXEDBACKWARD = 9,
			MIXEDRIGHT = 10,
			MIXEDLEFT = 11,
			MIXEDFB = 12,
			MIXEDLR = 13,
			GETM1ENC = 16,
			GETM2ENC = 17,
			GETM1SPEED = 18,
			GETM2SPEED = 19,
			RESETENC = 20,
			GETVERSION = 21,
			SETM1ENCCOUNT = 22,
			SETM2ENCCOUNT = 23,
			GETMBATT = 24,
			GETLBATT = 25,
			SETMINLB = 26,
			SETMAXLB = 27,
			SETM1VELPID = 28,
			SETM2VELPID = 29,
			GETM1ISPEED = 30,
			GETM2ISPEED = 31,
			M1DUTY = 32,
			M2DUTY = 33,
			MIXEDDUTY = 34,
			M1SPEED = 35,
			M2SPEED = 36,
			MIXEDSPEED = 37,
			M1SPEEDACCEL = 38,
			M2SPEEDACCEL = 39,
			MIXEDSPEEDACCEL = 40,
			M1SPEEDDIST = 41,
			M2SPEEDDIST = 42,
			MIXEDSPEEDDIST = 43,
			M1SPEEDACCELDIST = 44,
			M2SPEEDACCELDIST = 45,
			MIXEDSPEEDACCELDIST = 46,
			GETBUFFERS = 47,
			GETPWMS = 48,
			GETCURRENTS = 49,
			MIXEDSPEED2ACCEL = 50,
			MIXEDSPEED2ACCELDIST = 51,
			M1DUTYACCEL = 52,
			M2DUTYACCEL = 53,
			MIXEDDUTYACCEL = 54,
			READM1VELPID = 55,
			READM2VELPID = 56,
			SETMAINVOLTAGES = 57,
			SETLOGICVOLTAGES = 58,
			GETMINMAXMAINVOLTAGES = 59,
			GETMINMAXLOGICVOLTAGES = 60,
			SETM1POSPID = 61,
			SETM2POSPID = 62,
			READM1POSPID = 63,
			READM2POSPID = 64,
			M1SPEEDACCELDECCELPOS = 65,
			M2SPEEDACCELDECCELPOS = 66,
			MIXEDSPEEDACCELDECCELPOS = 67,
			SETM1DEFAULTACCEL = 68,
			SETM2DEFAULTACCEL = 69,
			SETPINFUNCTIONS = 74,
			GETPINFUNCTIONS = 75,
			SETDEADBAND	= 76,
			GETDEADBAND	= 77,
			GETENCODERS = 78,
			GETISPEEDS = 79,
			RESTOREDEFAULTS = 80,
			SETM1M2DEFAULTACCEL = 81,
			GETTEMP = 82,
			GETTEMP2 = 83,	//Only valid on some models
			GETERROR = 90,
			GETENCODERMODE = 91,
			SETM1ENCODERMODE = 92,
			SETM2ENCODERMODE = 93,
			WRITENVM = 94,
			READNVM = 95,	//Reloads values from Flash into Ram
			SETCONFIG = 98,
			GETCONFIG = 99,
			SETM1MAXMINCURRENT = 133,
			SETM2MAXMINCURRENT = 134,
			GETM1MAXMINCURRENT = 135,
			GETM2MAXMINCURRENT = 136,
			SETSIGNALPRO = 143,
			GETSIGNALPRO = 144,
			SETSTREAMPRO = 145,
			GETSTREAMPRO = 146,
			GETSIGNALVAL = 147,
			SETPWMMODE = 148,
			GETPWMMODE = 149,
			ESTOPRESET = 200,
			ESTOPRESET_LOCKUNLOCK = 201,
			GETESTOPLOCK = 202,
			SETSCRIPTDELAY = 246,
			GETSCRIPTDELAY = 247,
			STARTSCRIPT = 248,
			STOPSCRIPT = 249,
			GETUSEREEPROM = 252,
			WRITEUSEREEPROM = 253,
			FLAGBOOTLOADER = 255};	//Only available via USB communications
    public:
        MCP_Advanced(uart_port_t UART,int tout);
        ~MCP_Advanced();
		/***** Status,Configuration & Script Commands ****************************************************************/
		//Start,Stop
		bool Start_Script(uint8_t address);
		bool Stop_Script(uint8_t address);
		//Resets
		bool Reset_Settings(uint8_t address);
		bool Reset_Estop_Error(uint8_t address);
		//Set
		bool Set_Main_Voltage_Limits(uint8_t address, uint16_t minVolt, uint16_t maxVolt);
		bool Set_Logic_Voltage_Limits(uint8_t address, uint16_t minVolt, uint16_t maxVolt);
		bool Set_Priority_Levels(uint8_t address, uint8_t level1, uint8_t level2, uint8_t level3);
		bool Set_Address_and_MixedFlag(uint8_t address, uint8_t new_address, uint8_t mixed);
		bool Set_Signal_Properties(uint8_t address,uint8_t pin,uint8_t type,uint8_t mode,uint8_t target,uint8_t minaction, uint8_t maxaction, 
		uint32_t timeout,uint32_t loadhome,uint32_t minaction_posvalue, uint32_t maxaction_posvalue, uint32_t center,uint32_t deadband,uint32_t powerexp,
		uint32_t minoutput, uint32_t maxoutput, uint32_t powermin);
		bool Set_Stream_Properties(uint8_t address, uint8_t index, uint8_t type, uint32_t rate, uint32_t timeout);
		bool Set_PWM_Mode(uint8_t address, uint8_t mode);
		bool Set_ESTOP_Reset_Lock(uint8_t address); //ask basicmicro
		bool Set_Script_Autorun_Delay(uint8_t address, uint32_t delay);
		bool Write_EEPROM_USER_MEM(uint8_t address,uint8_t memory_address, uint16_t value);
		//Get
		uint16_t Get_Board_Status(uint8_t address);
		bool Get_Main_Voltage_Limits(uint8_t address,uint16_t &minVolt,uint16_t &maxVolt);
		uint16_t Get_Main_Voltage(uint8_t address,bool *valid=NULL);
		bool Get_Logic_Voltage_Limits(uint8_t address,uint16_t &minVolt,uint16_t &maxVolt);
		uint16_t Get_Logic_Voltage(uint8_t address,bool *valid=NULL);
		bool Get_Priority_Levels(uint8_t address, uint8_t level1, uint8_t level2, uint8_t level3);
		uint16_t Get_Board_Temperature(uint8_t address, bool *valid=NULL);
		bool Get_Both_Currents(uint8_t address,int16_t &current_M1, int16_t &current_M2);
		bool Get_Both_PWMs(uint8_t address,int16_t &PWM_M1, int16_t &PWM_M2);
		uint8_t Get_Mixed_Flag(uint8_t address);
		bool Get_all_Signal_Properties(uint8_t address, uint8_t &pin_count ,char &all_signal_properties);
		bool Get_all_Signal_Values(uint8_t address, uint8_t &pin_count, char &all_signal_values);
		bool Get_Stream_Properties(uint8_t address, uint8_t &index, uint8_t &type, uint32_t &rate, uint32_t &timeout);
		uint8_t Get_PWM_Mode(uint8_t address);
		uint8_t Get_ESTOP_Reset_Lock(uint8_t address);
		bool Get_Script_Autorun_Delay(uint8_t address, uint32_t &delay);
		bool Read_EEPROM_USER_MEM(uint8_t address, uint8_t memory_address, uint16_t &return_value);
		/*********************************************************************************************/

		/***** Motor Related Commands **********************************/
		//**Drive**//
		//Open loop
		bool Drive_M1_Forward(uint8_t address,uint8_t PWM);
		bool Drive_M1_Backward(uint8_t address,uint8_t PWM);
		bool Drive_M2_Forward(uint8_t address,uint8_t PWM);
		bool Drive_M2_Backward(uint8_t address,uint8_t PWM);
		bool Drive_Mix_Forward(uint8_t address,uint8_t PWM);
		bool Drive_Mix_Backward(uint8_t address,uint8_t PWM);
		bool Drive_Mix_Left(uint8_t address,uint8_t PWM);
		bool Drive_Mix_Right(uint8_t address,uint8_t PWM);
		bool Drive_M1_Duty_Cycle(uint8_t address, int16_t duty_cycle);
		bool Drive_M2_Duty_Cycle(uint8_t address, int16_t duty_cycle);
		bool Drive_Both_Duty_Cycle(uint8_t address, int16_t duty_cycle1, int16_t duty_cycle2);
		bool Drive_M1_Duty_Cycle_with_Accel(uint8_t address, int16_t duty_cycle, uint32_t accel);
		bool Drive_M2_Duty_Cycle_with_Accel(uint8_t address, int16_t duty_cycle, uint32_t accel);
		bool Drive_Both_Duty_Cycle_with_Accel(uint8_t address, int16_t duty_cycle1, uint32_t accel1, int16_t duty_cycle2, uint32_t accel2);
		//Closed loop
		bool Drive_M1_with_Vel(uint8_t address, int32_t velocity);
	    bool Drive_M2_with_Vel(uint8_t address, int32_t velocity);
		bool Drive_Both_with_Vel(uint8_t address, int32_t velocity1, int32_t velocity2);
		bool Drive_M1_with_Vel_and_Acc(uint8_t address, uint32_t accel, int32_t velocity);
		bool Drive_M2_with_Vel_and_Acc(uint8_t address, uint32_t accel, int32_t velocity);
		bool Drive_Both_with_Vel_and_Acc(uint8_t address, uint32_t accel, int32_t velocity1, int32_t velocity2);
		bool Drive_Both_with_Vel_and_Acc1_Acc2(uint8_t address, uint32_t accel1, int32_t velocity1, uint32_t accel2, int32_t velocity2);
		bool Buffered_Drive_M1_X_amount_with_Vel(uint8_t address, int32_t velocity, uint32_t distance, uint8_t type = 0);
		bool Buffered_Drive_M2_X_amount_with_Vel(uint8_t address, int32_t velocity, uint32_t distance, uint8_t type = 0);
		bool Buffered_Drive_Both_X_amount_with_Vel(uint8_t address, int32_t velocity1, uint32_t distance1, int32_t velocity2, uint32_t distance2, uint8_t type = 0);
		bool Buffered_Drive_M1_X_amount_with_Vel_and_Acc(uint8_t address, uint32_t accel, int32_t velocity, uint32_t distance, uint8_t type = 0);
		bool Buffered_Drive_M2_X_amount_with_Vel_and_Acc(uint8_t address, uint32_t accel, int32_t velocity, uint32_t distance, uint8_t type = 0);
		bool Buffered_Drive_Both_X_amount_with_Vel_and_Acc(uint8_t address, uint32_t accel, int32_t velocity1, uint32_t distance1, 
		int32_t velocity2, uint32_t distance2, uint8_t type = 0);
		bool Buffered_Drive_Both_X_amount_with_Vel_and_Acc1_Acc2(uint8_t address, uint32_t accel1, int32_t velocity1, uint32_t distance1, 
		uint32_t accel2, int32_t velocity2, uint32_t distance2, uint8_t type = 0);
		bool Buffered_Drive_M1_to_Position_with_Vel_and_AccDecc(uint8_t address, uint32_t accel, int32_t velocity, uint32_t deccel, uint32_t distance, uint8_t type = 0);
		bool Buffered_Drive_M2_to_Position_with_Vel_and_AccDecc(uint8_t address, uint32_t accel, int32_t velocity, uint32_t deccel, uint32_t distance, uint8_t type = 0);
		bool Buffered_Drive_Both_to_Position_with_Vel_and_AccDecc1_AccDecc2(uint8_t address, uint32_t accel1, int32_t velocity1, uint32_t deccel1, uint32_t distance1, 
		uint32_t accel2, int32_t velocity2, uint32_t deccel2, uint32_t distance2, uint8_t type = 0);
		//Set
		bool Set_M1_Default_Duty_Acc(uint8_t address, uint32_t accel);
		bool Set_M2_Default_Duty_Acc(uint8_t address, uint32_t accel);
		bool Set_Both_Default_Duty_Acc(uint8_t address, uint32_t accel1, uint32_t accel2);
		//Get
		bool Get_Motor_Buffers(uint8_t address, uint8_t &M1_buffer, uint8_t &M2_buffer);
		/********************************************************/

		/***** Motor Configuration Commands *********************************************/
        //Set
		bool Set_M1_MaxMin_Current(uint8_t address, int32_t max_current, int32_t min_current);
		bool Set_M2_MaxMin_Current(uint8_t address, int32_t max_current, int32_t min_current);
		//Get
		bool Get_M1_MaxMin_Current(uint8_t address, int32_t &max_current, int32_t &min_current);
		bool Get_M2_MaxMin_Current(uint8_t address, int32_t &max_current, int32_t &min_current);
		/************************************************************************/
        
		/***** PID Configuration Commands ********************************************************************************************************************************/
		//Set
		bool Set_M1_PID_Position(uint8_t address, float kp, float ki, float kd, uint32_t maxi, uint32_t deadzone, uint32_t minpos, uint32_t maxpos);
		bool Set_M2_PID_Position(uint8_t address, float kp, float ki, float kd, uint32_t maxi, uint32_t deadzone, uint32_t minpos, uint32_t maxpos);
		bool Set_M1_PID_Velocity(uint8_t address, float kp, float ki, float kd, uint32_t qpps);
		bool Set_M2_PID_Velocity(uint8_t address, float kp, float ki, float kd, uint32_t qpps);
		//Get
		bool Get_M1_PID_Position(uint8_t address, float &kp, float &ki, float &kd, uint32_t &maxi, uint32_t &deadzone, uint32_t &minpos, uint32_t &maxpos);
	    bool Get_M2_PID_Position(uint8_t address, float &kp, float &ki, float &kd, uint32_t &maxi, uint32_t &deadzone, uint32_t &minpos, uint32_t &maxpos);
		bool Get_M1_PID_Velocity(uint8_t address, float &kp, float &ki, float &kd, uint32_t &qpps);
		bool Get_M2_PID_Velocity(uint8_t address, float &kp, float &ki, float &kd, uint32_t &qpps);
		/*****************************************************************************************************************************************/
		
		/***** Encoder Commands *********************************************************************/
		//Set
		bool Write_EEPROM_Encoder_Mode(uint8_t address);
		bool Set_Encoder1_Mode(uint8_t address, uint8_t mode_e1);
		bool Set_Encoder2_Mode(uint8_t address, uint8_t mode_e2);
		bool Set_Enconder1_Count(uint8_t address, uint32_t value);
		bool Set_Enconder2_Count(uint8_t address, uint32_t value);
		bool Reset_Encoders(uint8_t address);
		//Get
		bool Read_EEPROM_Encoder_Mode(uint8_t address,uint8_t &mode_e1, uint8_t &mode_e2);
		bool Get_Encoder_Mode(uint8_t address, uint8_t &mode_e1, uint8_t &mode_e2);
		bool Get_Encoder1_Count(uint8_t address,uint32_t &enc1, uint8_t &status);
		bool Get_Encoder2_Count(uint8_t address,uint32_t &enc2, uint8_t &status);
		bool Get_Both_Encoder_Counts(uint8_t address,uint32_t &enc1,uint32_t &enc2);
		bool Get_Encoder1_Speed(uint8_t address, uint32_t &speed, uint8_t &status);
		bool Get_Encoder2_Speed(uint8_t address, uint32_t &speed, uint8_t &status);
		bool Get_Encoder1_Raw_Speed(uint8_t address, uint32_t &speed, uint8_t &status);
		bool Get_Encoder2_Raw_Speed(uint8_t address, uint32_t &speed, uint8_t &status);
		bool Get_Both_Instantaneous_Speeds(uint8_t address, uint32_t &ispeed1, uint32_t &ispeed2);
		/************************************************************************************/

		void start(long speed);
        virtual int available();
        virtual void write(uint8_t byte);
        //virtual int read();
        int read(uint32_t timeout);
	    //virtual void flush();
	    void clear();

    private:
        void crc_clear();
        void crc_update (uint8_t data);
        uint16_t crc_get();
        bool write_n(uint8_t byte,...);
		bool write_n_nocheck(uint8_t byte,...);
        bool read_n(uint8_t byte,uint8_t address,uint8_t cmd,...);
        uint32_t Read4bytes_with_Status(uint8_t address,uint8_t cmd,uint8_t *status,bool *valid);
        uint32_t Read4bytes(uint8_t address,uint8_t cmd,bool *valid);
        uint16_t Read2bytes(uint8_t address,uint8_t cmd,bool *valid);
        uint8_t Readbyte(uint8_t address,uint8_t cmd,bool *valid);
};