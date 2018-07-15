#include <stdio.h>
#include <iostream>
#include <string.h>
#include <errno.h>
#include "sys/socket.h"
#include "nvs_flash.h"
#include "nvs.h"
#include "rom/ets_sys.h"
#include "driver/uart.h"
#include "driver/gpio.h"
#include "sdkconfig.h"
#include "soc/timer_group_struct.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "freertos/queue.h"

#include "esp_log.h"
#include "esp_types.h"
#include "esp_smartconfig.h"
#include "esp_wifi.h"
#include "esp_wpa2.h"
#include "esp_event_loop.h"
#include "esp_system.h"

#include "driver/gpio.h"
#include "driver/periph_ctrl.h"
#include "driver/timer.h"

#include <WiFi.h> //cpp purposes
#include <WiFiEventHandler.h> //cpp purposes
#include "ArduinoJson.h"//Not bad, but temporary
#include "MCP263.h"

#include "lwip/err.h"
//#include "lwip/sockets.h"
#include "lwip/sys.h"
//#include <lwip/netdb.h>
//#include <sys/time.h>

using namespace std;
//#define DEBUG_MotorListen
#define DEBUG_WIFI_INIT
#define ESP_INTR_FLAG_DEFAULT 0
//-------------------WIFI RELATED---------------------------------------------
#define Smart_Connect     GPIO_NUM_33
#define IP_Blink          GPIO_NUM_13
#define GPIO_INPUT_PIN_SEL  (1ULL<<Smart_Connect)
#define UDP_PORT 1500 //port number for UDP com server -- listenning and talking
#define ESP32_IP_BROADCAST_PORT 1600 //port number for UDP ESP32 IP Broadcast --talking
#define ROS_IP_BROADCAST_PORT 1700 // port number for UDP ROS IP Broadcast --listenning
#define BUFLEN 2048 //UDP Recieve Buffer
#define MCP_Addr 0x80 //address


//for unmangling
extern "C"{
void app_main();
}
struct UDP_send_data{
      int Motor_Number = 0;
      char *Type = " ";
      int Value = 0;
    };


/*****************************GLOBALS********************************************/
//Motor related
//current
uint32_t Motor1_current_velocity = 0;
uint32_t Motor2_current_velocity = 0;
uint32_t Motor1_current_position = 0;
uint32_t Motor2_current_position = 0;
int Motor1_current_turn = 0;
int Motor2_current_turn = 0;
int Motor1_voltage = 0;
int Motor2_voltage = 0;
int16_t Motor1_amper = 0;
int16_t Motor2_amper = 0;
int16_t PWM_M1 = 0;
int16_t PWM_M2 = 0;
int16_t MotorDriver_Temp = 0;
uint16_t BatteryVoltage = 0;
//desired
int Motor1_desired_velocity = 1500;
int Motor2_desired_velocity = 1500;
int Motor1_desired_position = 0;
int Motor2_desired_position = 0;
int Motor1_desired_turn = 0;
int Motor2_desired_turn = 0;
//Position PID
float p1_kp = 1000.0; 
float p1_ki = 10.0;
float p1_kd = 2000.0;
uint32_t p1_deadzone=75;
uint32_t p1_maxi=8;
uint32_t p1_min_pos=-3000000;
uint32_t p1_max_pos=3000000;
float p2_kp = 1000.0; 
float p2_ki = 10.0;
float p2_kd = 2000.0;
uint32_t p2_deadzone=75;
uint32_t p2_maxi=8;
uint32_t p2_min_pos=-3000000;
uint32_t p2_max_pos=3000000;
//Velocity PID
float v1_kp = 2.0; 
float v1_ki = 5.0;
float v1_kd = 20.0;
uint32_t v1_qpps = 42175;
float v2_kp = 2.0; 
float v2_ki = 5.0;
float v2_kd = 20.0;
uint32_t v2_qpps = 42175;
//broadcast period
int ip_broadcast_delay = 1000; //1 seconds
//MotorDriver
MCP_Advanced MotorDriver(UART_NUM_2,5);
//Tags
static const char *MOTOR_TAG = "MOTOR_DRIVER";
static const char *VSMART_TAG = "VORDT_SMART_CONNECT";
static const char *SOCKET_TAG = "UDP_SOCKET";
static const char *WIFI_TAG = "WiFi_INIT";
static const char *INTR_TAG = "ISR";
static const char *TEST_TAG = "Test";
//UDP related
struct sockaddr_in BroadcastAddr,ESP_Addr, ROS_IP_Addr;
unsigned int send_len;
int UDP_Socket; //One
int Receiver_Socket;
int ROS_IP_receiver_Socket;
int s_len= sizeof(BroadcastAddr);
struct sockaddr_in ClientAddr;
unsigned int sa_len = sizeof(ClientAddr),recv_len;
//Wifi related
esp_err_t nvs_err;
wifi_config_t *wifi_config;
WiFi wifi; //wifi object
static EventGroupHandle_t wifi_event_group; //wifi events group
//static const int CONNECTED_BIT = BIT0; //smart_wifi connected
const int WIFI_CONNECTED_BIT = BIT0;//wifi connected
static const int ESPTOUCH_DONE_BIT = BIT1; //smartconfig done bit
bool Wifi_ready = false; //smart connect flag
//Semaphores
//For future use
static SemaphoreHandle_t UDP_Semaphore = NULL;
static SemaphoreHandle_t MotorDriver_Serial_Semaphore = NULL;
//Task Handle
void start_tasks();
void kill_tasks();
TaskHandle_t MotorDriverListenTask_Handle;
TaskHandle_t UDPListenTask_Handle;
TaskHandle_t IpBroadcastTask_Handle;
TaskHandle_t VordtSmartConnectTask_Hanlde;
TaskHandle_t BoardInfoTask_Handle;
TaskHandle_t Test_Task_Handle;
TaskHandle_t TEST_ROS_HANDLE;
static QueueHandle_t gpio_evt_queue = NULL;

/****************************************** TASKS ****************************************/
void ROS_IP_Listen( void * parameter){
    char buf[BUFLEN];
    StaticJsonBuffer<128> JSONbuffer;
    JsonObject& JSONencoder = JSONbuffer.createObject();
    char JSONmessageBuffer[128];
    int roscore_port;
    const char *roscore_ip;
    const char *roscore_id;
    ROS_IP_receiver_Socket = socket(AF_INET,SOCK_DGRAM,0);
    ROS_IP_Addr.sin_family=AF_INET;
    ROS_IP_Addr.sin_addr.s_addr = htonl(INADDR_ANY);
    ROS_IP_Addr.sin_port=htons(ROS_IP_BROADCAST_PORT);
    
    if (ROS_IP_receiver_Socket < 0) {
	    ESP_LOGE(SOCKET_TAG, "socket: %d %s", ROS_IP_receiver_Socket, strerror(errno));
	    vTaskDelete(NULL);
	   }
    int rc = bind(ROS_IP_receiver_Socket, (struct sockaddr *) &ROS_IP_Addr, sizeof(ROS_IP_Addr));
    if (rc < 0) {
	    ESP_LOGE(SOCKET_TAG, "bind: %d %s", rc, strerror(errno));
	    vTaskDelete(NULL);
	}
    ESP_LOGI(SOCKET_TAG,"ROS_IP_Receiver socket created without errors");
    while(1){
        memset(buf,0,BUFLEN);
        recv_len = recvfrom(ROS_IP_receiver_Socket, buf, BUFLEN, 0,(struct sockaddr *)&ClientAddr,&sa_len); // wait until incoming packet
        ets_delay_us(250);
        if(recv_len>0){
            JsonObject& root = JSONbuffer.parseObject(buf);
            roscore_id = root["ID"];
            roscore_ip = root["IP"];
            roscore_port = root ["PORT"];
            ESP_LOGI(SOCKET_TAG,"Data: %s %s %d\n" , roscore_id, roscore_ip, roscore_port);
        }
        JSONbuffer.clear();//reset buffer for next incoming packet
        vTaskDelay(7/portTICK_PERIOD_MS);
    }
}
void UDP_Send( void * parameter) //UDP Server - Publish Realtime Position,Turn,Velocity,Motor_Voltage
{
  UDP_send_data* incoming_char;
  incoming_char = ( UDP_send_data * ) parameter;
  int M_Number = incoming_char->Motor_Number;
  int value = incoming_char->Value; 
  char *Type = incoming_char->Type;
  StaticJsonBuffer<128> JSONbuffer;
  JsonObject& JSONencoder = JSONbuffer.createObject();
  char JSONmessageBuffer[128];
  JSONencoder["Motor"] = M_Number;
  JSONencoder["Type"] = Type;
  JSONencoder["Value"] = value;
  JSONencoder.printTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
  sendto(UDP_Socket, JSONmessageBuffer,sizeof(JSONmessageBuffer),0, (struct sockaddr *) &ClientAddr, sa_len );
  vTaskDelete(NULL);
}

void IP_Broadcast( void * parameter) //IP Broadcast, Port:1600
{
  BroadcastAddr.sin_family = AF_INET;
  BroadcastAddr.sin_addr.s_addr = inet_addr("255.255.255.255");
  BroadcastAddr.sin_port = htons(ESP32_IP_BROADCAST_PORT);
  StaticJsonBuffer<256> JSONbuffer;
  JsonObject& JSONencoder = JSONbuffer.createObject();
  char JSONmessageBuffer[256];
  JSONencoder["Model"] = "Vordt-2";
  JSONencoder["IP"] = wifi.getStaIp();
  JSONencoder["Port"] = UDP_PORT;
  JSONencoder["MAC"] = wifi.getStaMac();
  JSONencoder.printTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
  bool state=true;
  while(1){
  sendto(UDP_Socket, JSONmessageBuffer,sizeof(JSONmessageBuffer),0, (struct sockaddr *) &BroadcastAddr, sizeof(BroadcastAddr) );
  gpio_set_level((gpio_num_t)IP_Blink,state);
  vTaskDelay( ip_broadcast_delay / portTICK_PERIOD_MS );
  state=!state;
  }
}
void Board_Info( void *parameter){
    struct UDP_send_data UDP_Data;
    bool valid;
    while(1){
        UDP_Data.Motor_Number=1;
        BatteryVoltage = MotorDriver.Get_Board_Temperature(MCP_Addr,&valid);
        MotorDriver_Temp = MotorDriver.Get_Board_Temperature(MCP_Addr,&valid);
        if(valid){
            UDP_Data.Type="Btemp";
            UDP_Data.Value=MotorDriver_Temp;
            xTaskCreatePinnedToCore(&UDP_Send,"MotorDriverBoard_Temp_Send",2048,&UDP_Data,6,NULL,1);
            #ifdef DEBUG_BoardInfo
                ESP_LOGI(MOTOR_TAG,"MotorDriverBoard_Temp :%d", MotorDriver_Temp);
            #endif
        }
        if(valid){
            UDP_Data.Type="Mvolt";
            UDP_Data.Value=BatteryVoltage;
            xTaskCreatePinnedToCore(&UDP_Send,"Main(Battery)_Voltage_Send",2048,&UDP_Data,6,NULL,1);
            #ifdef DEBUG_BoardInfo
                ESP_LOGI(MOTOR_TAG,"Main (Battery) Voltage : %d",BatteryVoltage);
            #endif
        }
        vTaskDelay(5000 / portTICK_PERIOD_MS);//every 5 seconds
    }
}
void MotorDriver_Listen(void *parameter){
    UDP_Socket = socket(AF_INET,SOCK_DGRAM,0);
    struct UDP_send_data UDP_Data;
    bool valid;
    uint8_t status;
    if (UDP_Socket < 0) {
	    ESP_LOGE(SOCKET_TAG, "socket: %d %s", UDP_Socket, strerror(errno));
	    vTaskDelete(NULL);
	   }
    ESP_Addr.sin_family = AF_INET;
    ESP_Addr.sin_addr.s_addr = htonl(INADDR_ANY);
    ESP_Addr.sin_port = htons(0);
    int rc = bind(UDP_Socket, (struct sockaddr *) &ESP_Addr, sizeof(ESP_Addr));
    if (rc < 0) {
	    ESP_LOGE(SOCKET_TAG, "bind: %d %s", rc, strerror(errno));
	    vTaskDelete(NULL);
	}
    ESP_LOGI(SOCKET_TAG,"Send socket created without errors");
    xTaskCreatePinnedToCore(&Board_Info,"IP Broadcast Task",2048,NULL,5,&IpBroadcastTask_Handle,1);
    xTaskCreatePinnedToCore(&IP_Broadcast,"IP Broadcast Task",2048,NULL,2,&IpBroadcastTask_Handle,0);
    while(1){
        //Motor 1
        UDP_Data.Motor_Number=1;
        valid = MotorDriver.Get_Encoder1_Count(MCP_Addr,Motor1_current_position,status);
        if(valid){
            UDP_Data.Type="Position";
            UDP_Data.Value=int(Motor1_current_position)%32768;
            xTaskCreatePinnedToCore(&UDP_Send,"Motor1_Position_Send",2048,&UDP_Data,4,NULL,1);
            Motor1_current_turn=int(Motor1_current_position)/32768;
            UDP_Data.Type="Turn";
            UDP_Data.Value=Motor1_current_turn;
            xTaskCreatePinnedToCore(&UDP_Send,"Motor1_Turn_Send",2048,&UDP_Data,4,NULL,1);
            #ifdef DEBUG_MotorListen
                ESP_LOGI(MOTOR_TAG,"Motor1 Turn : %d , Position: %d",Motor1_current_turn,int(Motor1_current_position)%32768);
            #endif
        }
        vTaskDelay( 1 / portTICK_PERIOD_MS ); //critical delay
        valid = MotorDriver.Get_Encoder1_Speed(MCP_Addr,Motor1_current_velocity,status);
        if(valid){
            UDP_Data.Type="Velocity";
            UDP_Data.Value=Motor1_current_velocity;
            xTaskCreatePinnedToCore(&UDP_Send,"Motor1_Velocity_Send",2048,&UDP_Data,4,NULL,1);
            #ifdef DEBUG_MotorListen
                ESP_LOGI(MOTOR_TAG,"Motor1 Velocity: %d",Motor1_current_velocity);
            #endif
        }
        //Motor 2
        vTaskDelay( 1 / portTICK_PERIOD_MS ); //critical delay
        UDP_Data.Motor_Number=2;
        valid = MotorDriver.Get_Encoder2_Count(MCP_Addr,Motor2_current_position,status);
        if(valid){
            UDP_Data.Type="Position";
            UDP_Data.Value=int(Motor2_current_position)%32768;
            xTaskCreatePinnedToCore(&UDP_Send,"Motor2_Position_Send",2048,&UDP_Data,4,NULL,1);
            Motor2_current_turn=int(Motor2_current_position)/32768;
            UDP_Data.Type="Turn";
            UDP_Data.Value=Motor2_current_turn;
            xTaskCreatePinnedToCore(&UDP_Send,"Motor2_Turn_Send",2048,&UDP_Data,4,NULL,1);
            #ifdef DEBUG_MotorListen
                ESP_LOGI(MOTOR_TAG,"Motor2 Turn: %d , Position: %d",Motor2_current_turn,int(Motor2_current_position)%32768);
            #endif
        }
        vTaskDelay( 1 / portTICK_PERIOD_MS ); //critical delay
        valid = MotorDriver.Get_Encoder2_Speed(MCP_Addr,Motor2_current_velocity,status);
        if(valid){
            UDP_Data.Type="Velocity";
            UDP_Data.Value=Motor2_current_velocity;
            xTaskCreatePinnedToCore(&UDP_Send,"Motor2_Velocity_Send",2048,&UDP_Data,4,NULL,1);
            #ifdef DEBUG_MotorListen
                ESP_LOGI(MOTOR_TAG,"Motor2 Velocity: %d",Motor2_current_velocity);
            #endif
        }
        vTaskDelay( 1 / portTICK_PERIOD_MS ); //critical delay
        valid = MotorDriver.Get_Both_PWMs(MCP_Addr,PWM_M1,PWM_M2);
        if(valid){
            UDP_Data.Motor_Number=1;
            UDP_Data.Type="MotorV";//PWM value
            UDP_Data.Value=PWM_M1;
            xTaskCreatePinnedToCore(&UDP_Send,"Motor1_Voltage_Send",2048,&UDP_Data,4,NULL,1);
            UDP_Data.Motor_Number=2;
            UDP_Data.Value=PWM_M2;
            xTaskCreatePinnedToCore(&UDP_Send,"Motor2_Voltage_Send",2048,&UDP_Data,4,NULL,1);
            #ifdef DEBUG_MotorListen
                ESP_LOGI(MOTOR_TAG,"Motor1 PWM: %d, Motor2 PWM: %d",PWM_M1,PWM_M2);
            #endif
        }
        vTaskDelay( 1 / portTICK_PERIOD_MS ); //critical delay
        valid = MotorDriver.Get_Both_Currents(MCP_Addr, Motor1_amper, Motor2_amper);
        if(valid){
            UDP_Data.Motor_Number=1;
            UDP_Data.Type="MotorA";
            UDP_Data.Value=Motor1_amper;
            xTaskCreatePinnedToCore(&UDP_Send,"Motor1_Amper_Send",2048,&UDP_Data,4,NULL,1);
            UDP_Data.Motor_Number=2;
            UDP_Data.Value=Motor2_amper;
            xTaskCreatePinnedToCore(&UDP_Send,"Motor2_Amper_Send",2048,&UDP_Data,4,NULL,1);
            #ifdef DEBUG_MotorListen
                ESP_LOGI(MOTOR_TAG,"Motor1 Amper: %d, Motor2 Amper: %d",Motor1_amper,Motor2_amper);
            #endif
        }
        vTaskDelay( 1 / portTICK_PERIOD_MS ); //critical delay
    }
}
void UDP_Listen(void *pvParameter)//UDP Server - Listen for incoming Commands
{
    struct sockaddr_in UdpServerAddr;
    char buf[BUFLEN];
    StaticJsonBuffer<128> packet_JSON;
    const char* types = "";
    int mno = 0;
    long value = 0;
    char c_value[20];
    char c_motor[3];
    int i = 0;
    bool valid=false;
    Receiver_Socket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (Receiver_Socket < 0) {
		ESP_LOGE(SOCKET_TAG, "socket: %d %s", Receiver_Socket, strerror(errno));
		vTaskDelete(NULL);
	}
    memset((char *)&UdpServerAddr, 0, sizeof(UdpServerAddr));
    UdpServerAddr.sin_family = AF_INET;
	UdpServerAddr.sin_addr.s_addr = htonl(INADDR_ANY);
    UdpServerAddr.sin_port = htons(UDP_PORT);
    int rc  = bind(Receiver_Socket, (struct sockaddr *)&UdpServerAddr, sizeof(UdpServerAddr));
    if (rc < 0) {
		ESP_LOGE(SOCKET_TAG, "bind: %d %s", rc, strerror(errno));
		vTaskDelete(NULL);
	}
    ESP_LOGI(SOCKET_TAG,"Receive socket created without errors");
    while(1) {
        ESP_LOGI(SOCKET_TAG,"Waiting for incoming data");
        memset(buf,0,BUFLEN);
        //vTaskDelay( 50 / portTICK_PERIOD_MS );
        recv_len = recvfrom(Receiver_Socket, buf, BUFLEN, 0,(struct sockaddr *)&ClientAddr,&sa_len); // wait until incoming packet
        ets_delay_us(250);
        if(recv_len>0){
        //if(xSemaphoreTake(UDP_Semaphore, (TickType_t) 500) == pdTRUE){
        ESP_LOGI(SOCKET_TAG,"Received packet from %s:%d\n", inet_ntoa(ClientAddr.sin_addr), ntohs(ClientAddr.sin_port));
        ESP_LOGI(SOCKET_TAG,"Data: %s -- %d\n" , buf, recv_len);
        ets_delay_us(250);
        JsonObject& root = packet_JSON.parseObject(buf);
        ets_delay_us(250);
        types = root["type"];
        mno = root["mno"];
        value = root["value"];
        //ip_broadcast_delay = 2000;//User connected so lower the IP broadcast period
        ets_delay_us(250);
            if(types != '\0'){
                if (strcmp(types,"dpos") == 0 ){
                    ESP_LOGI(SOCKET_TAG,"position came");
                    if(mno == 1){
                        Motor1_desired_position=value;
                    }else if (mno == 2){
                        Motor2_desired_position=value;
                    }
                }
                if (strcmp(types,"dvel") == 0 ){
                    ESP_LOGI(SOCKET_TAG,"velocity came");
                    if(mno == 1){
                        Motor1_desired_velocity=value;
                    }else if (mno == 2){
                        Motor2_desired_velocity=value;
                    }
                }
                if (strcmp(types,"dturn") == 0 ){
                    ESP_LOGI(SOCKET_TAG,"turn came");
                    if(mno == 1){
                        Motor1_desired_turn=value;
                        MotorDriver.Buffered_Drive_M1_to_Position_with_Vel_and_AccDecc(MCP_Addr, 0, Motor1_desired_velocity, 0, (Motor1_desired_position+(Motor1_desired_turn*32768)),1);
                    }else if (mno == 2){
                        Motor2_desired_turn=value;
                        MotorDriver.Buffered_Drive_M2_to_Position_with_Vel_and_AccDecc(MCP_Addr, 0, Motor2_desired_velocity, 0, (Motor2_desired_position+(Motor2_desired_turn*32768)),1);
                    }
                }
                if (strcmp(types,"pidpos") == 0){
                    ESP_LOGI(SOCKET_TAG,"PID Velocity Parameters came");
                    if(mno == 1){
                        valid = MotorDriver.Set_M1_PID_Velocity(MCP_Addr, v1_kp, v1_ki, v1_kd, v1_qpps);
                        if(valid){
                            ESP_LOGI(TEST_TAG,"success, position PID parameters sent");
                        }
                    }else if( mno == 2){
                        MotorDriver.Set_M2_PID_Velocity(MCP_Addr, v2_kp, v2_ki, v2_kd, v2_qpps);
                    }
                }
                if (strcmp(types,"pidvel") == 0){
                    ESP_LOGI(SOCKET_TAG,"PID Position Parameters came");
                    if(mno == 1){
                        valid=MotorDriver.Set_M1_PID_Position(MCP_Addr, p1_kp,p1_ki,p1_kd,p1_maxi,p1_deadzone,p1_min_pos,p1_max_pos);
                        if(valid){
                            ESP_LOGI(TEST_TAG,"success, velocity PID parameters sent");
                        }
                    }else if( mno == 2){
                        MotorDriver.Set_M2_PID_Position(MCP_Addr, p2_kp,p2_ki,p2_kd,p2_maxi,p2_deadzone,p2_min_pos,p2_max_pos);
                    }

                }
                if (strcmp(types,"reset") == 0) {
                    ESP_LOGI(SOCKET_TAG,"reset came");
                    if(mno == 1){
                        MotorDriver.Drive_M1_Duty_Cycle(MCP_Addr, 0);
                        vTaskDelay( 150 / portTICK_PERIOD_MS ); //150ms
                        MotorDriver.Set_Enconder1_Count(MCP_Addr,0);
                    }else if (mno == 2){
                        MotorDriver.Drive_M2_Duty_Cycle(MCP_Addr,0);
                        vTaskDelay( 150 / portTICK_PERIOD_MS ); //150ms
                        MotorDriver.Set_Enconder1_Count(MCP_Addr,0);
                    }
                }
            }
            packet_JSON.clear();//reset buffer for next incoming packet
        }
        vTaskDelay( 8 / portTICK_PERIOD_MS ); //period can be lowered
    }
}
void Test_ROS (void * parameter){
    while(1){

    }
}

void Test( void * parameter){
    bool valid = false;
    while(1){
            valid = MotorDriver.Get_M2_PID_Velocity(MCP_Addr, v1_kp, v1_ki, v1_kd, v1_qpps);
            if(valid){
                ESP_LOGI(TEST_TAG,"kp: %0.5f, ki:%0.5f, kd: %0.5f, qpps: %d\n" , v1_kp, v1_ki, v1_kd,v1_qpps);
            }
         vTaskDelay( 600 / portTICK_PERIOD_MS );
    }


}
static void IRAM_ATTR gpio_isr_handler(void* arg)
{
    uint32_t gpio_num = (uint32_t) arg;
    xQueueSendFromISR(gpio_evt_queue, &gpio_num, NULL);
                //ESP_LOGI(INTR_TAG,"Interrupt");

    //initialize_smart_connect();
}

/******************************* WIFI-INIT ********************************************************/
/*STUFF TO FIX
-Restart Smart connect event if password or ssid is invalid
*/
static void sc_callback(smartconfig_status_t status, void *pdata) //smart config callback
{
    switch (status) {
        case SC_STATUS_WAIT:
        {
            ESP_LOGI(VSMART_TAG, "SC_STATUS_WAIT");
            break;
        }
        case SC_STATUS_FIND_CHANNEL:
        { 
            ESP_LOGI(VSMART_TAG, "SC_STATUS_FINDING_CHANNEL");
            break;
        }
        case SC_STATUS_GETTING_SSID_PSWD:
        {
            ESP_LOGI(VSMART_TAG, "SC_STATUS_GETTING_SSID_PSWD");
            break;
        }
        case SC_STATUS_LINK:
        {
            
            ESP_LOGI(VSMART_TAG, "SC_STATUS_LINK");
            wifi_config = (wifi_config_t *) pdata;
            ESP_LOGI(VSMART_TAG, "SSID:%s", wifi_config->sta.ssid);
            ESP_LOGI(VSMART_TAG, "PASSWORD:%s", wifi_config->sta.password);
            ESP_ERROR_CHECK( esp_wifi_disconnect());
            ESP_ERROR_CHECK( esp_wifi_set_config(ESP_IF_WIFI_STA, wifi_config) );
            ESP_ERROR_CHECK( esp_wifi_connect() );
            
            break;
        }
        case SC_STATUS_LINK_OVER:
        {
            ESP_LOGI(VSMART_TAG, "SC_STATUS_LINK_OVER");
            if (pdata != NULL) {
                uint8_t phone_ip[4] = { 0 };
                memcpy(phone_ip, (uint8_t* )pdata, 4);
                ESP_LOGI(VSMART_TAG, "Phone ip: %d.%d.%d.%d\n", phone_ip[0], phone_ip[1], phone_ip[2], phone_ip[3]);
            }
            xEventGroupSetBits(wifi_event_group, ESPTOUCH_DONE_BIT);
            break;
        }
        default:
            break;
    }
}

void Vordt_Smart_Connect(void * parm) //Smart Connect Task
{
    EventBits_t uxBits;
    ESP_ERROR_CHECK( esp_smartconfig_set_type(SC_TYPE_ESPTOUCH) );
    ESP_ERROR_CHECK( esp_smartconfig_start(sc_callback) );
    while (1) {
        uxBits = xEventGroupWaitBits(wifi_event_group, WIFI_CONNECTED_BIT | ESPTOUCH_DONE_BIT, true, false, portMAX_DELAY); 
        if(uxBits & WIFI_CONNECTED_BIT) {
            ESP_LOGI(VSMART_TAG, "WiFi Connected to ap");
        }        
        if(uxBits & ESPTOUCH_DONE_BIT) {
            ESP_LOGI(VSMART_TAG, "smartconfig over");
            esp_smartconfig_stop();
            vTaskDelete(NULL);
        }
    }
}

static esp_err_t Smart_Connect_event_handler(void *ctx, system_event_t *event) //wifi event handler
{
    switch(event->event_id) {
    case SYSTEM_EVENT_STA_START:
    {
        xTaskCreate(Vordt_Smart_Connect, "smartconfig_example_task", 4096, NULL, 3, &VordtSmartConnectTask_Hanlde);
        break;
    }
    case SYSTEM_EVENT_STA_GOT_IP:
    {
        xEventGroupSetBits(wifi_event_group, WIFI_CONNECTED_BIT);
        Wifi_ready=true;
        uint8_t ssid_bytearray[32] = { 0 };
        memcpy(ssid_bytearray,(uint8_t*) wifi_config->sta.ssid, 32);
        uint8_t password_bytearray[64] = { 0 };
        memcpy(password_bytearray,(uint8_t*) wifi_config->sta.password, 64);
        ESP_LOGI(VSMART_TAG,"Wifi SSID= %s\n", ssid_bytearray);
        ESP_LOGI(VSMART_TAG,"Wifi Pass= %s\n", password_bytearray);
        ESP_LOGI(VSMART_TAG,"GOT IP, openning NVS");
        nvs_handle my_handle;
            nvs_err = nvs_open("storage", NVS_READWRITE, &my_handle);
            if (nvs_err != ESP_OK) {
                ESP_LOGI(VSMART_TAG,"Error (%s) opening NVS handle!\n", esp_err_to_name(nvs_err));
            } else {
                    ESP_LOGI(VSMART_TAG,"NVS opened");
                    for(int a=0; a<32;a++){
                    nvs_err = nvs_set_u8(my_handle, "Wifi_SSID"+a, ssid_bytearray[a]);
                    nvs_err = nvs_commit(my_handle);
                    ets_delay_us(250);
                    }
                    ESP_LOGI(VSMART_TAG,"Write1 Successfull");
                    ets_delay_us(5000);
                    for(int i=0; i<64;i++){
                    nvs_err = nvs_set_u8(my_handle, "Wifi_Password"+i, password_bytearray[i]);
                    nvs_err = nvs_commit(my_handle);
                    ets_delay_us(250);
                    }
                    nvs_close(my_handle);
                    ESP_LOGI(VSMART_TAG,"Write2 Successfull");
            }
            start_tasks();
        break;
    }
    case SYSTEM_EVENT_STA_DISCONNECTED:
    {
        esp_wifi_connect();
        xEventGroupClearBits(wifi_event_group, WIFI_CONNECTED_BIT);
        kill_tasks();
        break;
    }
    default:
        break;
    }
    return ESP_OK;
}
static esp_err_t wifi_event_handler(void *ctx, system_event_t *event)
{
    switch(event->event_id) {
    case SYSTEM_EVENT_STA_START:
        esp_wifi_connect();
        break;
    case SYSTEM_EVENT_STA_GOT_IP:
        Wifi_ready=true;
        ESP_LOGI(WIFI_TAG, "got ip:%s",
                 ip4addr_ntoa(&event->event_info.got_ip.ip_info.ip));
        xEventGroupSetBits(wifi_event_group, WIFI_CONNECTED_BIT);
        start_tasks();
        break;
    case SYSTEM_EVENT_STA_DISCONNECTED:
        esp_wifi_connect();
        xEventGroupClearBits(wifi_event_group, WIFI_CONNECTED_BIT);
        kill_tasks();
        break;
    default:
        break;
    }
    return ESP_OK;
}

static void initialize_smart_connect(void)
{
    tcpip_adapter_init();
    wifi_event_group = xEventGroupCreate();
    
    //ESP_ERROR_CHECK( esp_event_loop_init(Smart_Connect_event_handler, NULL) );
    ESP_ERROR_CHECK( esp_wifi_stop());
    esp_event_loop_set_cb(Smart_Connect_event_handler, NULL);
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK( esp_wifi_init(&cfg) );
    ESP_ERROR_CHECK( esp_wifi_set_mode(WIFI_MODE_STA) );
    ESP_ERROR_CHECK( esp_wifi_start() );
}

void wifi_init_sta()
{   
    tcpip_adapter_init();
    wifi_event_group = xEventGroupCreate();
    ESP_ERROR_CHECK(esp_event_loop_init(wifi_event_handler, NULL) );
    //esp_event_loop_set_cb(wifi_event_handler, NULL);
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));
    /*wifi_config_t wifi_config = {
        .sta = {
            .ssid = EXAMPLE_ESP_WIFI_SSID,
            .password = EXAMPLE_ESP_WIFI_PASS
        },
    };*/
    uint8_t nvs_ssid[32] = { 0 };
    uint8_t nvs_password[64] = { 0 };
    
    nvs_handle my_handle;
    nvs_err = nvs_open("storage", NVS_READWRITE, &my_handle);
    if (nvs_err != ESP_OK) {
                ESP_LOGI(WIFI_TAG,"Error (%s) opening NVS handle!\n", esp_err_to_name(nvs_err));
            } else {
                    ESP_LOGI(WIFI_TAG,"NVS opened");
                    for(int a = 0;a<32;a++){
                    nvs_err = nvs_get_u8(my_handle, "Wifi_SSID"+a, &nvs_ssid[a]);
                    }
                    ESP_LOGI(WIFI_TAG,"Reading SSID finished");
                    ets_delay_us(5000);
                    for(int i = 0;i<64;i++){
                    nvs_err = nvs_get_u8(my_handle, "Wifi_Password"+i, &nvs_password[i]);
                    }
                    ESP_LOGI(WIFI_TAG,"Reading Password finished");
                    ESP_LOGI(WIFI_TAG,"Wifi SSID= %s\n", nvs_ssid);
                    ESP_LOGI(WIFI_TAG,"Wifi Pass= %s\n", nvs_password);
            }
    wifi_config_t wifi_setup = { };

    memcpy(wifi_setup.sta.ssid, nvs_ssid,sizeof(nvs_ssid));
    memcpy(wifi_setup.sta.password, nvs_password,sizeof(nvs_password));
    if(nvs_ssid[0] != NULL){
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(ESP_IF_WIFI_STA, &wifi_setup) );
    ESP_ERROR_CHECK(esp_wifi_start());
    ESP_LOGI(WIFI_TAG, "wifi_init_sta finished.");
    }else{
    initialize_smart_connect();
    ESP_LOGI(WIFI_TAG, "Smart Connect Activated");//smart config
    }
    //ESP_LOGI(TAG, "connect to ap SSID:%s password:%s",
    //         EXAMPLE_ESP_WIFI_SSID, EXAMPLE_ESP_WIFI_PASS);
}
void Smart_Connect_Interrupt(void* arg)//fix this task
{
    uint32_t io_num;
    while(1) {
        if(xQueueReceive(gpio_evt_queue, &io_num, portMAX_DELAY)) {
            ESP_LOGI(INTR_TAG,"GPIO[%d] intr, val: %d\n", io_num, gpio_get_level((gpio_num_t)io_num));
                //xTaskCreate(gpio_task_example, "gpio_task_example", 2048, NULL, 10, NULL);
            xEventGroupClearBits(wifi_event_group, WIFI_CONNECTED_BIT);
            ESP_ERROR_CHECK( esp_wifi_stop());
            initialize_smart_connect();
            close(Receiver_Socket);
            close(UDP_Socket);
            vTaskDelete(NULL);
            //initialize_smart_connect();
        }
    }
}

void start_tasks(){
    //xTaskCreatePinnedToCore(&Test_ROS, "ROS Test", 5000, NULL, 2, &TEST_ROS_HANDLE,0);
    xTaskCreate(&ROS_IP_Listen, "Listen Roscore IP", 15000, NULL, 1, NULL);
    //xTaskCreate(&Test,"Test deadzone", 2048, NULL, 5, NULL);
}
void kill_tasks(){
    //vTaskDelete(MotorDriverListenTask_Handle);
}

/****************************** MAIN *********************************************************/
void app_main(void)//Starting point
{
    //ESP_ERROR_CHECK(nvs_flash_erase());
    nvs_err = nvs_flash_init();
    
    vTaskDelay( 100 / portTICK_PERIOD_MS );
    gpio_pad_select_gpio(IP_Blink);
    
    gpio_set_direction((gpio_num_t)IP_Blink, GPIO_MODE_OUTPUT);

     gpio_config_t io_conf;
    //interrupt of rising edge or falling edge
    io_conf.intr_type = (gpio_int_type_t) GPIO_PIN_INTR_POSEDGE;
    //bit mask of the pins, use GPIO33 here
    io_conf.pin_bit_mask = GPIO_INPUT_PIN_SEL;
    //set as input mode    
    io_conf.mode = GPIO_MODE_INPUT;
    //enable pull-up mode
    io_conf.pull_up_en = (gpio_pullup_t)1;
    gpio_config(&io_conf);
    //create a queue to handle gpio event from isr
    gpio_evt_queue = xQueueCreate(10, sizeof(uint32_t));

    gpio_install_isr_service(ESP_INTR_FLAG_DEFAULT);
    gpio_isr_handler_add(Smart_Connect, gpio_isr_handler, (void*) Smart_Connect);

    vTaskDelay( 20 / portTICK_PERIOD_MS );
  if ( UDP_Semaphore == NULL )  // Check to confirm that the UDP_Semaphore has not already been created.
  {
    UDP_Semaphore = xSemaphoreCreateMutex();  // Create a mutex semaphore we will use to manage the UDP Socket
    if ( ( UDP_Semaphore ) != NULL )
      xSemaphoreGive( ( UDP_Semaphore ) );  // Make the UDP Socket available for use, by "Giving" the Semaphore.
  }
    xTaskCreate(Smart_Connect_Interrupt, "Smart_Connect_Reset", 2048, NULL, 10, NULL);
    MotorDriver.start(1000000);
    wifi_init_sta();
    //stay here until connected to wifi
    while(1){
        if(Wifi_ready == true){ //check if wifi is connected
        break;
        }
    }   
}
