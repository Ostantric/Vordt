#include "MCP263.h"
#include "esp_log.h"
#define RX_BUF_SIZE 4096 //UART Read Buffer
#define TX_BUF_SIZE 4096 //UART Write Buffer
#define MAXRETRY 2
#define SetDWORDval(arg) (uint8_t)(((uint32_t)arg)>>24),(uint8_t)(((uint32_t)arg)>>16),(uint8_t)(((uint32_t)arg)>>8),(uint8_t)arg
#define SetWORDval(arg) (uint8_t)(((uint16_t)arg)>>8),(uint8_t)arg

// Constructor
MCP_Advanced::MCP_Advanced(uart_port_t UART, int tout){
    timeout = tout;
    uart_num=UART;
}

// Destructor
MCP_Advanced::~MCP_Advanced(){
}

void MCP_Advanced::start(long speed){
    uart_config_t uart_config = {
        .baud_rate = speed,
        .data_bits = UART_DATA_8_BITS,
        .parity    = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE
    };
	uart_param_config(uart_num, &uart_config);
    uart_set_pin(uart_num, GPIO_NUM_17, GPIO_NUM_16, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);
    uart_driver_install(uart_num, RX_BUF_SIZE , TX_BUF_SIZE, 0, NULL, 0);
}
int MCP_Advanced::available(){
	size_t available;
	uart_get_buffered_data_len(UART_NUM_2,&available);
	return available;
}

/******** CRC **********/
void MCP_Advanced::crc_clear(){
	crc = 0;
}

uint16_t MCP_Advanced::crc_get(){
	return crc;
}

void MCP_Advanced::crc_update (uint8_t data){
//CRC16 Checksum Calculation - MCP User Manual Page 64
	int i;
	crc = crc ^ ((uint16_t)data << 8);
	for (i=0; i<8; i++)
	{
		if (crc & 0x8000)
			crc = (crc << 1) ^ 0x1021;
		else
			crc <<= 1;
	}
}
/**********************/

void MCP_Advanced::write(uint8_t byte){
        char send;
        send=byte;
		uart_write_bytes(uart_num,&send,1);
}

bool MCP_Advanced::write_n(uint8_t cnt, ... ){
	uint8_t trys=MAXRETRY;
	uint8_t *read_buffer = (uint8_t *) malloc(1);
	while(trys>0){
		crc_clear();
		uart_flush(uart_num);
		//send data with crc
		char buffer[cnt+1];
		int check;
		va_list marker;
		va_start( marker, cnt );     /* Initialize variable arguments. */
		for(uint8_t index=0;index<cnt;index++){
			uint8_t data = va_arg(marker, int);
			crc_update(data);
			buffer[index]=data;
		}
		va_end( marker );              /* Reset variable arguments.      */
		uint16_t crc = crc_get();
		buffer[cnt]=crc>>8;
		buffer[cnt+1]=crc;
		uart_write_bytes(uart_num,buffer,cnt+2);
		check = uart_read_bytes(uart_num,read_buffer,1, timeout);
		if(check!=-1){
			if(read_buffer[0]==0xFF){
				delete read_buffer;//this is critical **
				return true;
			}
		}
		//uart_flush(uart_num);
		//if(read(timeout)==0xFF)
		trys--;
	}
	delete read_buffer; //this is critical
	return false;
}
bool MCP_Advanced::write_n_nocheck(uint8_t cnt,...){
	uint8_t trys=MAXRETRY;
	uint8_t *read_buffer = (uint8_t *) malloc(1);
	while(trys>0){
		crc_clear();
		//send data with crc
		char buffer[cnt+1];
		int check;
		va_list marker;
		va_start( marker, cnt );     /* Initialize variable arguments. */
		for(uint8_t index=0;index<cnt;index++){
			uint8_t data = va_arg(marker, int);
			crc_update(data);
			buffer[index]=data;
		}
		va_end( marker );              /* Reset variable arguments.      */
		uint16_t crc = crc_get();
		buffer[cnt]=crc>>8;
		buffer[cnt+1]=crc;
		check=uart_write_bytes(uart_num,buffer,cnt+2);
		if(check!=-1){
			delete read_buffer;
			return true;
		}
		trys--;
	}
	delete read_buffer;
	return false;


}
bool MCP_Advanced::read_n(uint8_t cnt,uint8_t address,uint8_t cmd,...){
	uint32_t value;
	uint8_t trys=MAXRETRY;
	int check;
	bool write_valid=false;
	uint16_t ccrc;
	uint8_t *read_buffer = (uint8_t *) malloc((cnt*4)+2);
	while(trys>0){
			crc_clear();
			uart_flush(uart_num);
			write_valid = write_n_nocheck(2,address,cmd);
			if(write_valid==false) ESP_LOGI("TEST","Write Failed");//add return false if needed
			check = uart_read_bytes(uart_num,read_buffer,(cnt*4)+2, timeout);
			/*for(int i=0;i<10;i++){
			ESP_LOGI("TEST","Valid ?: %d\n" , read_buffer[i]);
			}*/
			va_list marker;
			va_start( marker, cmd );
			//0x01020304 = P
			//0x12341231 = D
			for(uint8_t index=0;index<(cnt*4);index=index+4){
				uint32_t *ptr = va_arg(marker, uint32_t *);
				if(check!=-1){
					value=(read_buffer[index]<<24)|(read_buffer[index+1]<<16)|(read_buffer[index+2]<<8)|read_buffer[index+3];
					crc_update(read_buffer[index]);
					crc_update(read_buffer[index+1]);
					crc_update(read_buffer[index+2]);
					crc_update(read_buffer[index+3]);
					*ptr = value;
				}
				else{
					break;
				}
			}
			ccrc=(read_buffer[cnt*4]<<8)|(read_buffer[(cnt*4)+1]);
			if(check!=1){			
				delete read_buffer;
				return crc_get()==ccrc;//improve this, add two cases
			}
			trys--;
	}
	delete read_buffer;
	return false;
}
uint32_t MCP_Advanced::Read4bytes_with_Status(uint8_t address, uint8_t cmd, uint8_t *status, bool *valid){
		if (valid) *valid = false;
		uint16_t ccrc;
		uint8_t trys = MAXRETRY;
		uint32_t data = 0;
		bool write_valid=false;
		int check;
		uint8_t *read_buffer = (uint8_t *) malloc(7);
		while(trys>0){
			crc_clear();
			uart_flush(uart_num);
			write_valid=write_n_nocheck(2,address,cmd);
			if(write_valid==false) ESP_LOGI("TEST","Write Failed");
			check = uart_read_bytes(uart_num,read_buffer,7, timeout);
			//ESP_LOGI("class","received %d\n" , check);
			if(check!=-1){
				data=(read_buffer[0]<<24)|(read_buffer[1]<<16|(read_buffer[2])<<8|(read_buffer[3]));
				*status = read_buffer[4];
				ccrc=(read_buffer[5]<<8)|(read_buffer[6]);
				crc_update(read_buffer[0]);
				crc_update(read_buffer[1]);
				crc_update(read_buffer[2]);
				crc_update(read_buffer[3]);
				crc_update(read_buffer[4]);
				if(crc_get()==ccrc){
					delete read_buffer;
					*valid = true;
					return data;
				}
			}
			trys--;
		}
		delete read_buffer;
		return false;
}



uint32_t MCP_Advanced::Read4bytes(uint8_t address, uint8_t cmd, bool *valid){
		if (valid) *valid = false;
		uint16_t ccrc;
		uint8_t trys = MAXRETRY;
		uint32_t data = 0;
		bool write_valid=false;
		int check;
		uint8_t *read_buffer = (uint8_t *) malloc(6);
		while(trys>0){
			crc_clear();
			uart_flush(uart_num);
			write_valid=write_n_nocheck(2,address,cmd);
			if(write_valid==false) ESP_LOGI("TEST","Write Failed");
			check = uart_read_bytes(uart_num,read_buffer,6, timeout);
			//ESP_LOGI("class","received %d\n" , check);
			if(check!=-1){
				data=(read_buffer[0]<<24)|(read_buffer[1]<<16|(read_buffer[2])<<8|(read_buffer[3]));
				ccrc=(read_buffer[4]<<8)|(read_buffer[5]);
				crc_update(read_buffer[0]);
				crc_update(read_buffer[1]);
				crc_update(read_buffer[2]);
				crc_update(read_buffer[3]);
				if(crc_get()==ccrc){
					delete read_buffer;
					*valid = true;
					return data;
				}
			}
			trys--;
		}
		delete read_buffer;
		return false;
}

uint16_t MCP_Advanced::Read2bytes(uint8_t address, uint8_t cmd, bool *valid){
		if (valid) *valid = false;
		uint16_t ccrc;
		uint8_t trys = MAXRETRY;
		uint32_t data = 0;
		bool write_valid=false;
		int check;
		uint8_t *read_buffer = (uint8_t *) malloc(4);
		while(trys>0){
			crc_clear();
			uart_flush(uart_num);
			write_valid=write_n_nocheck(2,address,cmd);
			if(write_valid==false) ESP_LOGI("TEST","Write Failed");
			check = uart_read_bytes(uart_num,read_buffer,4, timeout);
			//ESP_LOGI("class","received %d\n" , check);
			if(check!=-1){
				data=(read_buffer[0]<<8)|(read_buffer[1]);
				ccrc=(read_buffer[2]<<8)|(read_buffer[3]);
				crc_update(read_buffer[0]);
				crc_update(read_buffer[1]);
				if(crc_get()==ccrc){
					delete read_buffer;
					*valid = true;
					return data;
				}
			}
			trys--;
		}
		delete read_buffer;
		return false;
}

/***** Status,Configuration & Script Commands *************************************************************************************************************/

bool MCP_Advanced::Stop_Script(uint8_t address){
	return write_n(2,address,STOPSCRIPT);
}
//SET
bool MCP_Advanced::Set_Main_Voltage_Limits(uint8_t address, uint16_t minVolt, uint16_t maxVolt){
		return write_n(6,address,SETMAINVOLTAGES,SetWORDval(minVolt),SetWORDval(maxVolt));
}
bool MCP_Advanced::Set_Logic_Voltage_Limits(uint8_t address, uint16_t minVolt, uint16_t maxVolt){
		return write_n(6,address,SETLOGICVOLTAGES,SetWORDval(minVolt),SetWORDval(maxVolt));
}

bool MCP_Advanced::Set_M1_MaxMin_Current(uint8_t address,int32_t max,int32_t min){
	return write_n(10,address,SETM1MAXMINCURRENT,SetDWORDval(max),SetDWORDval(min));
}

bool MCP_Advanced::Set_M2_MaxMin_Current(uint8_t address,int32_t max,int32_t min){
	return write_n(10,address,SETM2MAXMINCURRENT,SetDWORDval(max),SetDWORDval(min));
}

//GET
uint16_t MCP_Advanced::Get_Main_Voltage(uint8_t address,bool *valid){
	return Read2bytes(address,GETMBATT,valid);
}
uint16_t MCP_Advanced::Get_Logic_Voltage(uint8_t address,bool *valid){
	return Read2bytes(address,GETLBATT,valid);
}

bool MCP_Advanced::Get_M1_MaxMin_Current(uint8_t address,int32_t &max, int32_t &min){
	uint32_t tmax,tmin;
	bool valid = read_n(2,address,GETM1MAXMINCURRENT,&tmax,&tmin);
	if(valid){
		max = tmax;
		min = tmin;
	}
	return valid;
}
bool MCP_Advanced::Get_M2_MaxMin_Current(uint8_t address,int32_t &max, int32_t &min){
	uint32_t tmax,tmin;
	bool valid = read_n(2,address,GETM2MAXMINCURRENT,&tmax,&tmin);
	if(valid){
		max = tmax;
		min = tmin;
	}
	return valid;
}

uint16_t MCP_Advanced::Get_Board_Temperature(uint8_t address,bool *valid){
	return Read2bytes(address,GETTEMP,valid);
}

bool MCP_Advanced::Get_Main_Voltage_Limits(uint8_t address,uint16_t &MinVol, uint16_t &MaxVol){
	bool valid;
	uint32_t value = Read4bytes(address,GETMINMAXMAINVOLTAGES,&valid);
	if(valid){
		MinVol = value>>16;
		MaxVol = value&0xFFFF;
	}
	return valid;
}
bool MCP_Advanced::Get_Logic_Voltage_Limits(uint8_t address,uint16_t &MinVol, uint16_t &MaxVol){
	bool valid;
	uint32_t value = Read4bytes(address,GETMINMAXLOGICVOLTAGES,&valid);
	if(valid){
		MinVol = value>>16;
		MaxVol = value&0xFFFF;
	}
	return valid;
}

bool MCP_Advanced::Get_Both_PWMs(uint8_t address,int16_t &PWM_M1, int16_t &PWM_M2){
	bool valid;
	uint32_t value = Read4bytes(address,GETPWMS,&valid);
	if(valid){
		PWM_M1 = value>>16;
		PWM_M2 = value&0xFFFF;
	}
	return valid;
}

bool MCP_Advanced::Get_Both_Currents(uint8_t address,int16_t &current_M1, int16_t &current_M2){
	bool valid;
	uint32_t value = Read4bytes(address,GETCURRENTS,&valid);
	if(valid){
		current_M1 = value>>16;
		current_M2 = value&0xFFFF;
	}
	return valid;
}

bool MCP_Advanced::Get_Motor_Buffers(uint8_t address, uint8_t &M1_buffer, uint8_t &M2_buffer){
	bool valid;
	uint16_t value = Read2bytes(address,GETBUFFERS,&valid);
	if(valid){
		M1_buffer = value>>8;
		M2_buffer = value&0xFF;
	}
	return valid;
}


/************************************************************************************************************************************************************/

/****** Motor Drive ********************************************************************************************************************************************/
//PWM
bool MCP_Advanced::Drive_M1_Forward(uint8_t address,uint8_t pwm){
	return write_n(3,address,M1FORWARD,pwm);
}
bool MCP_Advanced::Drive_M1_Backward(uint8_t address,uint8_t pwm){
	return write_n(3,address,M1BACKWARD,pwm);
}
bool MCP_Advanced::Drive_M2_Forward(uint8_t address,uint8_t pwm){
	return write_n(3,address,M2FORWARD,pwm);
}
bool MCP_Advanced::Drive_M2_Backward(uint8_t address,uint8_t pwm){
	return write_n(3,address,M2BACKWARD,pwm);
}
bool MCP_Advanced::Drive_Mix_Forward(uint8_t address,uint8_t pwm){
	return write_n(3,address,MIXEDFORWARD,pwm);
}
bool MCP_Advanced::Drive_Mix_Backward(uint8_t address,uint8_t pwm){
	return write_n(3,address,MIXEDBACKWARD,pwm);
}
bool MCP_Advanced::Drive_Mix_Right(uint8_t address,uint8_t pwm){
	return write_n(3,address,MIXEDRIGHT,pwm);
}
bool MCP_Advanced::Drive_Mix_Left(uint8_t address,uint8_t pwm){
	return write_n(3,address,MIXEDLEFT,pwm);
}

//Duty
bool MCP_Advanced::Drive_M1_Duty_Cycle(uint8_t address,int16_t duty_cycle){
	return write_n(4,address,M1DUTY,SetWORDval(duty_cycle));
}
bool MCP_Advanced::Drive_M2_Duty_Cycle(uint8_t address,int16_t duty_cycle){
	return write_n(4,address,M2DUTY,SetWORDval(duty_cycle));
}
bool MCP_Advanced::Drive_Both_Duty_Cycle(uint8_t address, int16_t duty_cycle1, int16_t duty_cycle2){
	return write_n(6,address,MIXEDDUTY,SetWORDval(duty_cycle1),SetWORDval(duty_cycle2));
}
//Duty and Accel
bool MCP_Advanced::Drive_M1_Duty_Cycle_with_Accel(uint8_t address, int16_t duty_cycle, uint16_t accel){
	return write_n(8,address,M1DUTYACCEL,SetWORDval(duty_cycle),SetWORDval(accel));
}
bool MCP_Advanced::Drive_M2_Duty_Cycle_with_Accel(uint8_t address, int16_t duty_cycle, uint16_t accel){
	return write_n(8,address,M2DUTYACCEL,SetWORDval(duty_cycle),SetWORDval(accel));
}
bool MCP_Advanced::Drive_Both_Duty_Cycle_with_Accel(uint8_t address, int16_t duty_cycle1, uint16_t accel1, int16_t duty_cycle2, uint16_t accel2){
	return write_n(14,address,MIXEDDUTYACCEL,SetWORDval(duty_cycle1),SetWORDval(accel1),SetWORDval(duty_cycle2),SetWORDval(accel2));
}
//Vel
bool MCP_Advanced::Drive_M1_with_Vel(uint8_t address, int32_t velocity){
	return write_n(6,address,M1SPEED,SetDWORDval(velocity));
}
bool MCP_Advanced::Drive_M2_with_Vel(uint8_t address, int32_t velocity){
	return write_n(6,address,M2SPEED,SetDWORDval(velocity));
}
bool MCP_Advanced::Drive_Both_with_Vel(uint8_t address, int32_t velocity1, int32_t velocity2){
	return write_n(10,address,MIXEDSPEED,SetDWORDval(velocity1),SetDWORDval(velocity2));
}

//Vel and Accel
bool MCP_Advanced::Drive_M1_with_Vel_and_Acc(uint8_t address, uint32_t accel, int32_t velocity){
	return write_n(10,address,M1SPEEDACCEL,SetDWORDval(accel),SetDWORDval(velocity));
}
bool MCP_Advanced::Drive_M2_with_Vel_and_Acc(uint8_t address, uint32_t accel, int32_t velocity){
	return write_n(10,address,M2SPEEDACCEL,SetDWORDval(accel),SetDWORDval(velocity));
}
bool MCP_Advanced::Drive_Both_with_Vel_and_Acc(uint8_t address, uint32_t accel, int32_t velocity1, int32_t velocity2){
	return write_n(14,address,MIXEDSPEEDACCEL,SetDWORDval(accel),SetDWORDval(velocity1),SetDWORDval(velocity2));
}
bool MCP_Advanced::Drive_Both_with_Vel_and_Acc1_Acc2(uint8_t address, uint32_t accel1, int32_t velocity1, uint32_t accel2, int32_t velocity2){
	return write_n(18,address,MIXEDSPEED2ACCEL,SetDWORDval(accel1),SetDWORDval(velocity1),SetDWORDval(accel2),SetDWORDval(velocity2));
}

//Buffered Vel and Distance
bool MCP_Advanced::Buffered_Drive_M1_X_amount_with_Vel(uint8_t address, int32_t velocity, uint32_t distance, uint8_t type){
	return write_n(11,address,M1SPEEDDIST,SetDWORDval(velocity),SetDWORDval(distance),type);
}
bool MCP_Advanced::Buffered_Drive_M2_X_amount_with_Vel(uint8_t address, int32_t velocity, uint32_t distance, uint8_t type){
	return write_n(11,address,M2SPEEDDIST,SetDWORDval(velocity),SetDWORDval(distance),type);
}
bool MCP_Advanced::Buffered_Drive_Both_X_amount_with_Vel(uint8_t address, int32_t velocity1, uint32_t distance1, int32_t velocity2, uint32_t distance2, uint8_t type){
	return write_n(19,address,MIXEDSPEEDDIST,SetDWORDval(velocity1),SetDWORDval(distance1),SetDWORDval(velocity2),SetDWORDval(distance2),type);
}

//Buffered Vel, Accel and Distance
bool MCP_Advanced::Buffered_Drive_M1_X_amount_with_Vel_and_Acc(uint8_t address,uint32_t accel, int32_t velocity, uint32_t distance, uint8_t type){
	return write_n(15,address,M1SPEEDACCELDIST,SetDWORDval(accel),SetDWORDval(velocity),SetDWORDval(distance),type);
}
bool MCP_Advanced::Buffered_Drive_M2_X_amount_with_Vel_and_Acc(uint8_t address,uint32_t accel, int32_t velocity, uint32_t distance, uint8_t type){
	return write_n(15,address,M2SPEEDACCELDIST,SetDWORDval(accel),SetDWORDval(velocity),SetDWORDval(distance),type);
}
bool MCP_Advanced::Buffered_Drive_Both_X_amount_with_Vel_and_Acc(uint8_t address, uint32_t accel, int32_t velocity1, uint32_t distance1, 
		int32_t velocity2, uint32_t distance2, uint8_t type){
	return write_n(23,address,MIXEDSPEEDACCELDIST,SetDWORDval(accel),SetDWORDval(velocity1),SetDWORDval(distance1),SetDWORDval(velocity2),SetDWORDval(distance2),type);
}
bool MCP_Advanced::Buffered_Drive_Both_X_amount_with_Vel_and_Acc1_Acc2(uint8_t address, uint32_t accel1, int32_t velocity1, uint32_t distance1, 
		uint32_t accel2, int32_t velocity2, uint32_t distance2, uint8_t type){
	return write_n(27,address,MIXEDSPEED2ACCELDIST,SetDWORDval(accel1),SetDWORDval(velocity1),SetDWORDval(distance1),SetDWORDval(accel2),SetDWORDval(velocity2),SetDWORDval(distance2),type);
}

//Buffered Vel, Deccel, Accel and Distance
bool MCP_Advanced::Buffered_Drive_M1_to_Position_with_Vel_and_AccDecc(uint8_t address, uint32_t accel, int32_t velocity, uint32_t deccel, uint32_t position, uint8_t type){
		return write_n(19,address,M1SPEEDACCELDECCELPOS,SetDWORDval(accel),SetDWORDval(velocity),SetDWORDval(deccel),SetDWORDval(position),type);
}
bool MCP_Advanced::Buffered_Drive_M2_to_Position_with_Vel_and_AccDecc(uint8_t address, uint32_t accel, int32_t velocity, uint32_t deccel, uint32_t position, uint8_t type){
		return write_n(19,address,M2SPEEDACCELDECCELPOS,SetDWORDval(accel),SetDWORDval(velocity),SetDWORDval(deccel),SetDWORDval(position),type);
}
bool MCP_Advanced::Buffered_Drive_Both_to_Position_with_Vel_and_AccDecc1_AccDecc2(uint8_t address, uint32_t accel1, int32_t velocity1, uint32_t deccel1, uint32_t position1, 
		uint32_t accel2, int32_t velocity2, uint32_t deccel2, uint32_t position2, uint8_t type){
		return write_n(35,address,M2SPEEDACCELDECCELPOS,SetDWORDval(accel1),SetDWORDval(velocity1),SetDWORDval(deccel1),SetDWORDval(position1),SetDWORDval(accel2),
		SetDWORDval(velocity2),SetDWORDval(deccel2),SetDWORDval(position2),type);
}


/*************************************************************************************************************************************************************/

/****** PID *************************************************************************************************************************************************/
//Set
bool MCP_Advanced::Set_M1_PID_Position(uint8_t address, float kp, float ki, float kd, uint32_t maxi, uint32_t deadzone, uint32_t minpos, uint32_t maxpos){
	uint32_t kp_s=kp*1024;//10 shift left
	uint32_t ki_s=kp*1024;
	uint32_t kd_s=kp*1024;
	return write_n(30, address, SETM1POSPID, SetDWORDval(kd_s), SetDWORDval(kp_s), SetDWORDval(ki_s), SetDWORDval(maxi), SetDWORDval(deadzone), SetDWORDval(minpos), SetDWORDval(maxpos));
}
bool MCP_Advanced::Set_M2_PID_Position(uint8_t address, float kp, float ki, float kd, uint32_t maxi, uint32_t deadzone, uint32_t minpos, uint32_t maxpos){
	uint32_t kp_s=kp*1024;//10 shift left
	uint32_t ki_s=kp*1024;
	uint32_t kd_s=kp*1024;
	return write_n(30, address, SETM2POSPID, SetDWORDval(kd_s), SetDWORDval(kp_s), SetDWORDval(ki_s), SetDWORDval(maxi), SetDWORDval(deadzone), SetDWORDval(minpos), SetDWORDval(maxpos));
}
bool MCP_Advanced::Set_M1_PID_Velocity(uint8_t address, float kp, float ki, float kd, uint32_t qpps){
	uint32_t kp_s=kp*65536;//16 shift left
	uint32_t ki_s=kp*65536;
	uint32_t kd_s=kp*65536;
	return write_n(18, address, SETM1VELPID, SetDWORDval(kd_s), SetDWORDval(kp_s), SetDWORDval(ki_s), SetDWORDval(qpps));
}
bool MCP_Advanced::Set_M2_PID_Velocity(uint8_t address, float kp, float ki, float kd, uint32_t qpps){
	uint32_t kp_s=kp*65536;//16 shift left
	uint32_t ki_s=kp*65536;
	uint32_t kd_s=kp*65536;
	return write_n(18, address, SETM2VELPID, SetDWORDval(kd_s), SetDWORDval(kp_s), SetDWORDval(ki_s), SetDWORDval(qpps));
}
//Get
bool MCP_Advanced::Get_M1_PID_Position(uint8_t address, float &kp, float &ki, float &kd, uint32_t &maxi, uint32_t &deadzone, uint32_t &minpos, uint32_t &maxpos){
	uint32_t kp_s,ki_s,kd_s;
	bool valid = read_n(7,address,READM1POSPID,&kp_s,&ki_s,&kd_s, &maxi, &deadzone, &minpos, &maxpos);
	kp = ((float)kp_s)/1024;//10 shift right
	ki = ((float)ki_s)/1024;
	kd = ((float)kd_s)/1024;
	return valid;
}
bool MCP_Advanced::Get_M2_PID_Position(uint8_t address, float &kp, float &ki, float &kd, uint32_t &maxi, uint32_t &deadzone, uint32_t &minpos, uint32_t &maxpos){
	uint32_t kp_s,ki_s,kd_s;
	bool valid = read_n(7,address,READM2POSPID,&kp_s,&ki_s,&kd_s, &maxi, &deadzone, &minpos, &maxpos);
	kp = ((float)kp_s)/1024;//10 shift right
	ki = ((float)ki_s)/1024;
	kd = ((float)kd_s)/1024;
	return valid;
}
bool MCP_Advanced::Get_M1_PID_Velocity(uint8_t address, float &kp, float &ki, float &kd, uint32_t &qpps){
	uint32_t kp_s,ki_s,kd_s;
	bool valid = read_n(4,address,READM1VELPID,&kp_s,&ki_s,&kd_s, &qpps);
	kp = ((float)kp_s)/65536;
	ki = ((float)ki_s)/65536;
	kd = ((float)kd_s)/65536;
	return valid;
}
bool MCP_Advanced::Get_M2_PID_Velocity(uint8_t address, float &kp, float &ki, float &kd, uint32_t &qpps){
	uint32_t kp_s,ki_s,kd_s;
	bool valid = read_n(4,address,READM2VELPID,&kp_s,&ki_s,&kd_s, &qpps);
	kp = ((float)kp_s)/65536;
	ki = ((float)ki_s)/65536;
	kd = ((float)kd_s)/65536;
	return valid;
}

/************************************************************************************************************************************************************/
/****** Encoders ********************************************************************************************************************************************/
//SET
bool MCP_Advanced::Set_Enconder1_Count(uint8_t address, uint32_t value){
	 return write_n(6,address,SETM1ENCCOUNT,SetDWORDval(value));
}
bool MCP_Advanced::Set_Enconder2_Count(uint8_t address, uint32_t value){
	 return write_n(6,address,SETM2ENCCOUNT,SetDWORDval(value));
}
bool MCP_Advanced::Reset_Encoders(uint8_t address){
	return write_n(2,address,RESETENC);
}

//GET
bool MCP_Advanced::Get_Encoder1_Count(uint8_t address, uint32_t &enc, uint8_t &status){
	 uint32_t count;
	 bool valid=false;
	 count = Read4bytes_with_Status(address,GETM1ENC,&status,&valid);
	 if(valid){
		 enc = count;
	 }
	 return valid;
}

bool MCP_Advanced::Get_Encoder2_Count(uint8_t address, uint32_t &enc, uint8_t &status){
	 uint32_t count;
	 bool valid=false;
	 count = Read4bytes_with_Status(address,GETM2ENC,&status,&valid);
	 if(valid){
		 enc = count;
	 }
	 return valid;
}

bool MCP_Advanced::Get_Both_Encoder_Counts(uint8_t address,uint32_t &enc1,uint32_t &enc2){
	bool valid = read_n(2,address,GETENCODERS,&enc1,&enc2);
	return valid;
}

bool MCP_Advanced::Get_Encoder1_Speed(uint8_t address, uint32_t &speed, uint8_t &status){
		uint32_t count;
	 bool valid=false;
	 count = Read4bytes_with_Status(address,GETM1SPEED,&status,&valid);
	 if(valid){
		speed = count;
	 }
	 return valid;
}

bool MCP_Advanced::Get_Encoder2_Speed(uint8_t address, uint32_t &speed, uint8_t &status){
		uint32_t count;
	 bool valid=false;
	 count = Read4bytes_with_Status(address,GETM2SPEED,&status,&valid);
	 if(valid){
		speed = count;
	 }
	 return valid;
}

bool MCP_Advanced::Get_Encoder1_Raw_Speed(uint8_t address, uint32_t &speed, uint8_t &status){
	 uint32_t count;
	 bool valid=false;
	 count = Read4bytes_with_Status(address,GETM1ISPEED,&status,&valid);
	 if(valid){
		speed = count;
	 }
	 return valid;
}

bool MCP_Advanced::Get_Encoder2_Raw_Speed(uint8_t address, uint32_t &speed, uint8_t &status){
	 uint32_t count;
	 bool valid=false;
	 count = Read4bytes_with_Status(address,GETM2ISPEED,&status,&valid);
	 if(valid){
		speed = count;
	 }
	 return valid;
}

bool MCP_Advanced::Get_Both_Instantaneous_Speeds(uint8_t address, uint32_t &ispeed1, uint32_t &ispeed2){
	bool valid = read_n(2,address,GETISPEEDS,&ispeed1,&ispeed2);
	return valid;
}




/****** Motor Movements *************************************************************************************************************************************/
