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

#include "lwip/err.h"
//#include "lwip/sockets.h"
#include "lwip/sys.h"
//#include <lwip/netdb.h>
//#include <sys/time.h>

using namespace std;

//for unmangling
extern "C"{
void app_main();
}

struct Motor_data{
      uint8_t Motor_Number = 0;
      uint8_t Type = 0;
      long Value = 0;
    };
struct UDP_send_data{
      int Motor_Number = 0;
      char *Type = " ";
      int Value = 0;
    };

//#define DEBUG_FPGA_Listen_Task
#define DEBUG_WIFI_INIT
#define FPGA_SERIAL_RTS   UART_PIN_NO_CHANGE
#define FPGA_SERIAL_CTS   UART_PIN_NO_CHANGE
//------------------FPGA RELATED--------------------------------------------
                                      //FPGA Definitions        | PIN
#define MCU_Ready         GPIO_NUM_12 //MCU_READY_FOR_UART_TX---->102
#define FPGA_SERIAL_TX    GPIO_NUM_17 //MCU_SERIAL_RX------------>100
#define FPGA_SERIAL_RX    GPIO_NUM_16 //MCU_SERIAL_TX------------>101
#define UART_ACK          GPIO_NUM_21 //UART_RX_RESET------------>34
#define FPGA_Reset        GPIO_NUM_14 //RESET-------------------->40
#define Motor1_Reset      GPIO_NUM_15 //MOTOR1_DECODER_RESET----->11
#define Motor2_Reset      GPIO_NUM_32 //MOTOR2_DECODER_RESET----->12

//-------------------WIFI RELATED---------------------------------------------
#define Smart_Connect     GPIO_NUM_33
#define IP_Blink          GPIO_NUM_13
#define GPIO_INPUT_PIN_SEL  (1ULL<<Smart_Connect)
#define UDP_PORT 1500 //port number for UDP server
//------------------------------------------------------------------------------
#define RX_BUF_SIZE 1024 //UART Read Buffer
#define TX_BUF_SIZE 1024 //UART Write Buffer
#define BUFLEN 2048 //UDP Recieve Buffer

#define ESP_INTR_FLAG_DEFAULT 0

/*****************************GLOBALS********************************************/
//Motor related
short Motor1_speed = 0;
short Motor2_speed = 0;
short Motor1_position = 0;
short Motor2_position = 0;
int Motor1_turn = 0;
int Motor2_turn = 0;
short Motor1_voltage = 0;
short Motor2_voltage = 0;
int ip_broadcast_delay = 200;
uint8_t motor1_register =1; //FPGA register
uint8_t motor2_register =2; //FPGA register

//UDP related
struct sockaddr_in BroadcastAddr,ESP_Addr;
unsigned int send_len;
int UDP_Socket; //One
int Receiver_Socket;
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
static SemaphoreHandle_t UDP_Semaphore = NULL;
static SemaphoreHandle_t FPGA_Serial_Semaphore = NULL;
static SemaphoreHandle_t UDP_Send_Semaphore = NULL;
//Task Handle
void start_tasks();
void kill_tasks();
TaskHandle_t FPGAListenTask_Handle;
TaskHandle_t UDPListenTask_Handle;
TaskHandle_t IpBroadcastTask_Handle;
TaskHandle_t VordtSmartConnectTask_Hanlde;
//Queue
static QueueHandle_t UART_queue; //for future use
static QueueHandle_t gpio_evt_queue = NULL;
//Tags
static const char *VSMART_TAG = "VORDT_SMART_CONNECT";
static const char *SOCKET_TAG = "UDP_SOCKET";
static const char *WIFI_TAG = "WiFi_INIT";
static const char *INTR_TAG = "ISR";

/****************************************** TASKS ****************************************/

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
  BroadcastAddr.sin_port = htons(1600);
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

void FPGA_Listen(void *pvParameter)//FPGA UART, Current speed: 2Mbits, FPGA MAX is 50Mbits, ESP32 MAX is 4Mbits. Higher speeds are possible with UART-pipeline architecture
{
    UDP_Socket = socket(AF_INET, SOCK_DGRAM, 0);
    struct UDP_send_data UDP_Data;
    uint8_t *read_data = (uint8_t *) malloc(RX_BUF_SIZE);

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
    char incoming_byte[20];
    memset(incoming_byte,0,sizeof(incoming_byte));

    uint8_t incomingbyte0=0;
    uint8_t incomingbyte1=0;
    uint8_t incomingbyte2=0;
    uint8_t incomingbyte3=0;
    uint8_t incomingbyte4=0;
    uint8_t incomingbyte5=0;

    while(1) {

    if(xSemaphoreTake(FPGA_Serial_Semaphore, (TickType_t) 5) == pdTRUE){
        ets_delay_us(250);
        vTaskPrioritySet(FPGAListenTask_Handle, 7);
        ets_delay_us(250);
        gpio_set_level((gpio_num_t)MCU_Ready, 1);
	    ets_delay_us(15);//critical delay
        gpio_set_level((gpio_num_t)MCU_Ready, 0);
        ets_delay_us(250);
        vTaskPrioritySet(FPGAListenTask_Handle, 3);
        ets_delay_us(500);
        int length = uart_read_bytes(UART_NUM_2, read_data, RX_BUF_SIZE, 0);
        ets_delay_us(500);//critical delay
         uart_flush(UART_NUM_2);
          for (int i=0;i<length;i++){
              incoming_byte[i]=read_data[i];
          }
          ets_delay_us(250); //critical delay
          //Parse incoming packet
          incomingbyte0 = read_data[0]; //Motor notation
          incomingbyte1 = read_data[1]; //Type notation
          incomingbyte2 = read_data[2]; //byte1
          incomingbyte3 = read_data[3]; //byte2
          incomingbyte4 = read_data[4]; //byte3
          incomingbyte5 = read_data[5]; //byte4
         ets_delay_us(250); //critical delay
         uart_flush(UART_NUM_2);

        char readytosend[4];
        
        if(incomingbyte0==1){
                UDP_Data.Motor_Number=1;
                if(incomingbyte1 == 1){
                    Motor1_position= (incomingbyte3 << 8) | (incomingbyte2);
                    #ifdef DEBUG_FPGA_Listen_Task
                        cout<<"Motor1_Position:"<<Motor1_position<<endl;
                    #endif
                    UDP_Data.Type="Position";
                    UDP_Data.Value=Motor1_position;
                    xTaskCreatePinnedToCore(&UDP_Send,"Motor1_Position_Send",2048,&UDP_Data,4,NULL,1);
                }
                else if (incomingbyte1 == 2){
                    Motor1_speed=(incomingbyte3 << 8) | (incomingbyte2);
                    #ifdef DEBUG_FPGA_Listen_Task
                        cout<<"Motor1_Velocity:"<<Motor1_speed<<endl;
                    #endif
                    UDP_Data.Type="Velocity";
                    UDP_Data.Value=Motor1_speed;
                    xTaskCreatePinnedToCore(&UDP_Send,"Motor1_Velocity_Send",2048,&UDP_Data,4,NULL,1);
                }
                else if (incomingbyte1 == 3){
                    Motor1_turn = (incomingbyte5 << 24) | (incomingbyte4 << 16) | (incomingbyte3 << 8) | (incomingbyte2);
                    #ifdef DEBUG_FPGA_Listen_Task
                        cout<<"Motor1_Turn:"<<Motor1_turn<<endl;
                    #endif
                    UDP_Data.Type="Turn";
                    UDP_Data.Value=Motor1_turn;
                    xTaskCreatePinnedToCore(&UDP_Send,"Motor1_Turn_Send",2048,&UDP_Data,4,NULL,1);
                }
                else if (incomingbyte1 == 4){
                    Motor1_voltage=incomingbyte2;
                    #ifdef DEBUG_FPGA_Listen_Task
                        cout<<"Motor1_Voltage:"<<Motor1_voltage<<endl;
                    #endif
                    UDP_Data.Type="MotorV";
                    UDP_Data.Value=Motor1_voltage;
                    xTaskCreatePinnedToCore(&UDP_Send,"Motor1_Voltage_Send",2048,&UDP_Data,4,NULL,1);
                }
        }
        else if( incomingbyte0 == 2){
                UDP_Data.Motor_Number=2;
                if(incomingbyte1 == 1){
                    Motor2_position= (incomingbyte3 << 8) | (incomingbyte2);
                    #ifdef DEBUG_FPGA_Listen_Task
                        cout<<"Motor2_Position:"<<Motor2_position<<endl;
                    #endif
                    UDP_Data.Type="Position";
                    UDP_Data.Value=Motor2_position;
                    xTaskCreatePinnedToCore(&UDP_Send,"Motor2_Position_Send",2048,&UDP_Data,4,NULL,1);
                }
                else if (incomingbyte1 == 2){
                    Motor2_speed=(incomingbyte3 << 8) | (incomingbyte2);
                    #ifdef DEBUG_FPGA_Listen_Task
                        cout<<"Motor2_Velocity:"<<Motor2_speed<<endl;
                    #endif
                    UDP_Data.Type="Velocity";
                    UDP_Data.Value=Motor2_speed;
                    xTaskCreatePinnedToCore(&UDP_Send,"Motor2_Velocity_Send",2048,&UDP_Data,4,NULL,1);
                }
                else if (incomingbyte1 == 3){
                    Motor2_turn = (incomingbyte5 << 24) | (incomingbyte4 << 16) | (incomingbyte3 << 8) | (incomingbyte2);
                    #ifdef DEBUG_FPGA_Listen_Task
                        cout<<"Motor2_Turn:"<<Motor2_turn<<endl;
                    #endif
                    UDP_Data.Type="Turn";
                    UDP_Data.Value=Motor2_turn;
                    xTaskCreatePinnedToCore(&UDP_Send,"Motor2_Turn_Send",2048,&UDP_Data,4,NULL,1);
                }
                else if (incomingbyte1 == 4){
                    Motor2_voltage=incomingbyte2;
                    #ifdef DEBUG_FPGA_Listen_Task
                        cout<<"Motor2_Voltage:"<<Motor2_voltage<<endl;
                    #endif
                    UDP_Data.Type="MotorV";
                    UDP_Data.Value=Motor2_voltage;
                    xTaskCreatePinnedToCore(&UDP_Send,"Motor2_Voltage_Send",2048,&UDP_Data,4,NULL,1);
                }
        }
         if ( ( FPGA_Serial_Semaphore ) != NULL ){
            xSemaphoreGive( ( FPGA_Serial_Semaphore ) );  // Make the FPGA_Serial Port available for use, by "Giving" the Semaphore.
            }
            memset(incoming_byte,0,sizeof(incoming_byte));
        }
    vTaskDelay( 3 / portTICK_PERIOD_MS ); //critical delay
    }
}

void Send_16bits_To_FPGA ( void * parameter) //16 bits, Velocity, Position, Motor Voltage
{
 if(xSemaphoreTake(UDP_Semaphore, portMAX_DELAY) == pdTRUE){
  Motor_data* incoming_char;
  incoming_char = ( Motor_data * ) parameter;
  uint8_t M_Number = incoming_char->Motor_Number;
  uint8_t Type = incoming_char->Type;
  int Data_16bit = incoming_char->Value;
  //int Data_16bit = 4660; //0x1234
  char readytosend[4];
  readytosend[0] = M_Number; //Motor Notation
  readytosend[1] = Type; //Type Notation
  /*****Little ENDIAN******/
  readytosend[2] = (int) ((Data_16bit >> 8) & 0xFF); //byte 2
  readytosend[3] = (int) (Data_16bit & 0xFF); //byte 1
  ets_delay_us(100);
  //for extra noise safety, reset FPGA's UART RX
  gpio_set_level((gpio_num_t)UART_ACK, 1);
  ets_delay_us(250);
  uart_write_bytes(UART_NUM_2,readytosend, 4);
  ets_delay_us(250);
  uart_flush_input(UART_NUM_2);
  ets_delay_us(250);
  gpio_set_level((gpio_num_t)UART_ACK, 0); //reset FPGA's UART RX
  ets_delay_us(250);
   if ( ( UDP_Semaphore ) != NULL ){
             xSemaphoreGive(UDP_Semaphore);
         }
  }
    vTaskDelete(NULL);
}

void Send_24bits_To_FPGA ( void * parameter) //24 bits, PID_Parameters-Kp,Ki,Kd
{
    if(xSemaphoreTake(UDP_Semaphore, portMAX_DELAY) == pdTRUE){
    Motor_data* incoming_char;
    incoming_char = ( Motor_data * ) parameter;
    uint8_t M_Number = incoming_char->Motor_Number;
    uint8_t Type = incoming_char->Type;
    int Data_24bit = incoming_char->Value;
    //long Data_32bit = 1500000002; //0x59682F01
    char readytosend[5];
    ets_delay_us(100);//critical delay
    readytosend[0] = M_Number; //Motor notation
    readytosend[1] = Type; //Type notation
    /*****Little ENDIAN******/
    readytosend[2] = (int) ((Data_24bit >> 16) & 0xFF); //byte 3
    readytosend[3] = (int) ((Data_24bit >> 8) & 0xFF); //byte 2
    readytosend[4] = (int) (Data_24bit & 0xFF); //byte 1
    ets_delay_us(100);//critical delay
    //for extra noise safety, reset FPGA's UART RX
    gpio_set_level((gpio_num_t)UART_ACK, 1); 
    ets_delay_us(250);
    uart_write_bytes(UART_NUM_2,readytosend, 5);
    ets_delay_us(250);
    uart_flush_input(UART_NUM_2);
    ets_delay_us(250);
    gpio_set_level((gpio_num_t)UART_ACK, 0);//reset FPGA's UART RX
    ets_delay_us(250);
    if ( ( UDP_Semaphore ) != NULL ){
                xSemaphoreGive(UDP_Semaphore);
            }
    }
        vTaskDelete(NULL);
}

void Send_32bits_To_FPGA ( void * parameter) //32 bits, TURN
{
    if(xSemaphoreTake(UDP_Semaphore, portMAX_DELAY) == pdTRUE){
    Motor_data* incoming_char;
    incoming_char = ( Motor_data * ) parameter;
    uint8_t M_Number = incoming_char->Motor_Number;
    uint8_t Type = incoming_char->Type;
    int Data_32bit = incoming_char->Value;
    //long Data_32bit = 1500000002; //0x59682F01
    char readytosend[6];
    ets_delay_us(100);//critical delay
    readytosend[0] = M_Number; //Motor notation
    readytosend[1] = Type; //Type notation
    /*****Little ENDIAN******/
    readytosend[2] = (int) ((Data_32bit >> 24) & 0xFF); //byte 4
    readytosend[3] = (int) ((Data_32bit >> 16) & 0xFF); //byte 3
    readytosend[4] = (int) ((Data_32bit >> 8) & 0xFF); //byte 2
    readytosend[5] = (int) (Data_32bit & 0xFF); //byte 1
    ets_delay_us(100);//critical delay
    //for extra noise safety, reset FPGA's UART RX
    gpio_set_level((gpio_num_t)UART_ACK, 1); 
    ets_delay_us(250);
    uart_write_bytes(UART_NUM_2,readytosend, 6);
    ets_delay_us(250);
    uart_flush_input(UART_NUM_2);
    ets_delay_us(250);
    gpio_set_level((gpio_num_t)UART_ACK, 0);//reset FPGA's UART RX
    ets_delay_us(250);
    if ( ( UDP_Semaphore ) != NULL ){
                xSemaphoreGive(UDP_Semaphore);
            }
    }
        vTaskDelete(NULL);
}

void UDP_Listen(void *pvParameter)//UDP Server - Listen for incoming Commands
{
    struct sockaddr_in UdpServerAddr;
    char buf[BUFLEN];
    StaticJsonBuffer<128> packet_JSON;
    const char* types = "";
    int mno = 0;
    long value = 0;
    struct Motor_data Command_Data;
    char c_value[20];
    char c_motor[3];
    int i = 0;
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
        //ip_broadcast_delay = 2000;//User connected so lower the IP broadcast frequency
        ets_delay_us(250);
            if(types != '\0'){
                Command_Data.Value=value;
                Command_Data.Motor_Number=mno;
                if (strcmp(types,"dpos") == 0 ){
                    ESP_LOGI(SOCKET_TAG,"position came");
                    Command_Data.Type=1;
                    xTaskCreate(Send_16bits_To_FPGA,"FPGA_Position_Send", 2048, &Command_Data, 6, NULL);
                }
                if (strcmp(types,"dvel") == 0 ){
                    ESP_LOGI(SOCKET_TAG,"velocity came");
                    Command_Data.Type=2;
                    xTaskCreate(Send_16bits_To_FPGA,"FPGA_Velocity_Send", 2048, &Command_Data, 6, NULL);
                }
                if (strcmp(types,"dturn") == 0 ){
                    ESP_LOGI(SOCKET_TAG,"turn came");
                    Command_Data.Type=3;
                    xTaskCreate(Send_32bits_To_FPGA,"FPGA_Turn_Send", 2048, &Command_Data, 6, NULL);
                }
                if (strcmp(types,"pidpos") == 0){
                    ESP_LOGI(SOCKET_TAG,"PID Velocity Parameters came");
                    Command_Data.Type=4;
                    xTaskCreate(Send_24bits_To_FPGA,"FPGA_PID_Pos_Par_Send", 2048, &Command_Data, 6, NULL);
                }
                if (strcmp(types,"pidvel") == 0){
                    ESP_LOGI(SOCKET_TAG,"PID Position Parameters came");
                    Command_Data.Type=5;
                    xTaskCreate(Send_24bits_To_FPGA,"FPGA_PID_Vel_Par_Send", 2048, &Command_Data, 6, NULL);
                }
                if (strcmp(types,"reset") == 0) {
                    ESP_LOGI(SOCKET_TAG,"reset came");
                    i=0;
                    while(i<5){
                        Command_Data.Motor_Number=mno;
                        Command_Data.Type=1;
                        if(mno==1) gpio_set_level((gpio_num_t)Motor1_Reset, 0); else gpio_set_level((gpio_num_t)Motor2_Reset, 0);
                        xTaskCreate(Send_16bits_To_FPGA,"FPGA_Position_Send", 2048, &Command_Data, 6, NULL);
                        vTaskDelay( 20 / portTICK_PERIOD_MS );
                        Command_Data.Type=3;
                        xTaskCreate(Send_32bits_To_FPGA,"FPGA_Position_Send", 2048, &Command_Data, 6, NULL);
                        if(mno==1) gpio_set_level((gpio_num_t)Motor1_Reset, 1); else gpio_set_level((gpio_num_t)Motor2_Reset, 1);
                        i++;
                        vTaskDelay( 150 / portTICK_PERIOD_MS );
                    }
                }
            }
            packet_JSON.clear();//reset buffer for next incoming packet
        }
        vTaskDelay( 5 / portTICK_PERIOD_MS ); //this can be lowered
    }
}

/******************************* FUNCTIONS ***************************************************/
void Motors_Reset() // Startup Reset
{
    int i=0;
    int mno=1;
    struct Motor_data Command_Data;
        while(i<5){
                            Command_Data.Motor_Number=mno;
                            Command_Data.Type=1;
                            if(mno==1) gpio_set_level((gpio_num_t)Motor1_Reset, 0); else gpio_set_level((gpio_num_t)Motor2_Reset, 0);
                            xTaskCreate(Send_16bits_To_FPGA,"FPGA_Position_Send", 2048, &Command_Data, 6, NULL);
                            vTaskDelay( 20 / portTICK_PERIOD_MS );
                            Command_Data.Type=3;
                            xTaskCreate(Send_32bits_To_FPGA,"FPGA_Position_Send", 2048, &Command_Data, 6, NULL);
                            if(mno==1) gpio_set_level((gpio_num_t)Motor1_Reset, 1); else gpio_set_level((gpio_num_t)Motor2_Reset, 1);
                            i++;
                            vTaskDelay( 20 / portTICK_PERIOD_MS );
        }
    mno=2;
        while(i<5){
                            Command_Data.Motor_Number=mno;
                            Command_Data.Type=1;
                            if(mno==1) gpio_set_level((gpio_num_t)Motor1_Reset, 0); else gpio_set_level((gpio_num_t)Motor2_Reset, 0);
                            xTaskCreate(Send_16bits_To_FPGA,"FPGA_Position_Send", 2048, &Command_Data, 6, NULL);
                            vTaskDelay( 20 / portTICK_PERIOD_MS );
                            Command_Data.Type=3;
                            xTaskCreate(Send_32bits_To_FPGA,"FPGA_Position_Send", 2048, &Command_Data, 6, NULL);
                            if(mno==1) gpio_set_level((gpio_num_t)Motor1_Reset, 1); else gpio_set_level((gpio_num_t)Motor2_Reset, 1);
                            i++;
                            vTaskDelay( 20 / portTICK_PERIOD_MS );
        }
}

/******************************* WIFI-INIT ********************************************************/
/*STUFF TO FIX
-Wifi connection check(periodically)
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
            
            ESP_ERROR_CHECK( esp_wifi_disconnect() );
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
    ESP_ERROR_CHECK( esp_wifi_stop() );
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
    ESP_ERROR_CHECK(esp_wifi_start() );
    ESP_LOGI(WIFI_TAG, "wifi_init_sta finished.");
    }else{
    initialize_smart_connect();
    ESP_LOGI(WIFI_TAG, "Smart Connect Activated");
    }
    //ESP_LOGI(TAG, "connect to ap SSID:%s password:%s",
    //         EXAMPLE_ESP_WIFI_SSID, EXAMPLE_ESP_WIFI_PASS);
}
static void IRAM_ATTR gpio_isr_handler(void* arg)
{
    uint32_t gpio_num = (uint32_t) arg;
    xQueueSendFromISR(gpio_evt_queue, &gpio_num, NULL);
                //ESP_LOGI(INTR_TAG,"Interrupt");

    //initialize_smart_connect();
}
void gpio_task_example(void* arg)
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
    xTaskCreatePinnedToCore(&FPGA_Listen, "FPGA_Serial_Listen", 15000, NULL, 3, &FPGAListenTask_Handle,1);
    xTaskCreatePinnedToCore(&UDP_Listen, "UDP_Listen", 15000, NULL, 5, &UDPListenTask_Handle,0);
    xTaskCreatePinnedToCore(&IP_Broadcast, "IP_Broadcast", 15000, NULL, 2, &IpBroadcastTask_Handle,0);
}
void kill_tasks(){
    //if(&FPGAListenTask_Handle!=NULL){
        vTaskDelete(FPGAListenTask_Handle);
    //}
    //if(&UDPListenTask_Handle!=NULL){
        vTaskDelete(UDPListenTask_Handle);
    //}
    //if(&IpBroadcastTask_Handle!=NULL){
        vTaskDelete(IpBroadcastTask_Handle);
    //}
}
/****************************** MAIN *********************************************************/
void app_main(void)//Starting point
{
    //ESP_ERROR_CHECK(nvs_flash_erase());
    nvs_err = nvs_flash_init();
        
    vTaskDelay( 100 / portTICK_PERIOD_MS );
    
    gpio_pad_select_gpio(MCU_Ready);
    gpio_pad_select_gpio(UART_ACK);
    gpio_pad_select_gpio(Motor1_Reset);
    gpio_pad_select_gpio(Motor2_Reset);
    gpio_pad_select_gpio(FPGA_Reset);
    gpio_pad_select_gpio(IP_Blink);
    gpio_set_direction((gpio_num_t)Motor1_Reset, GPIO_MODE_OUTPUT);
    gpio_set_direction((gpio_num_t)Motor2_Reset, GPIO_MODE_OUTPUT);
    gpio_set_direction((gpio_num_t)MCU_Ready, GPIO_MODE_OUTPUT);
    gpio_set_direction((gpio_num_t)UART_ACK, GPIO_MODE_OUTPUT);
    gpio_set_direction((gpio_num_t)FPGA_Reset, GPIO_MODE_OUTPUT);
    gpio_set_direction((gpio_num_t)IP_Blink, GPIO_MODE_OUTPUT);
       //Create Semaphore for FPGA_Serial port
  if ( FPGA_Serial_Semaphore == NULL )  // Check to confirm that the FPGA_Serial Semaphore has not already been created.
  {
    FPGA_Serial_Semaphore = xSemaphoreCreateMutex();  // Create a mutex semaphore we will use to manage the FPGA_Serial Port
    if ( ( FPGA_Serial_Semaphore ) != NULL )
      xSemaphoreGive( ( FPGA_Serial_Semaphore ) );  // Make the FPGA_Serial Port available for use, by "Giving" the Semaphore.
  }
  if ( UDP_Semaphore == NULL )  // Check to confirm that the FPGA_Serial Semaphore has not already been created.
  {
    UDP_Semaphore = xSemaphoreCreateMutex();  // Create a mutex semaphore we will use to manage the FPGA_Serial Port
    if ( ( UDP_Semaphore ) != NULL )
      xSemaphoreGive( ( UDP_Semaphore ) );  // Make the FPGA_Serial Port available for use, by "Giving" the Semaphore.
  }
  if ( UDP_Send_Semaphore == NULL )  // Check to confirm that the FPGA_Serial Semaphore has not already been created.
  {
    UDP_Send_Semaphore = xSemaphoreCreateMutex();  // Create a mutex semaphore we will use to manage the FPGA_Serial Port
    if ( ( UDP_Send_Semaphore ) != NULL )
      xSemaphoreGive( ( UDP_Send_Semaphore ) );  // Make the FPGA_Serial Port available for use, by "Giving" the Semaphore.
  }
    uart_config_t uart_config = {
        .baud_rate = 2000000,
        .data_bits = UART_DATA_8_BITS,
        .parity    = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE
    };

    gpio_config_t io_conf;
    //interrupt of rising edge or falling edge
    io_conf.intr_type = (gpio_int_type_t) GPIO_PIN_INTR_POSEDGE;
    //bit mask of the pins, use GPIO4/5 here
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

    gpio_set_level((gpio_num_t)FPGA_Reset, 0);
    gpio_set_level((gpio_num_t)UART_ACK, 0);
    gpio_set_level((gpio_num_t)Motor1_Reset, 0);
    gpio_set_level((gpio_num_t)Motor2_Reset, 0);
    vTaskDelay( 20 / portTICK_PERIOD_MS );
    gpio_set_level((gpio_num_t)FPGA_Reset, 1);
    vTaskDelay( 20 / portTICK_PERIOD_MS );

    uart_param_config(UART_NUM_2, &uart_config);
    uart_set_pin(UART_NUM_2, FPGA_SERIAL_TX, FPGA_SERIAL_RX, FPGA_SERIAL_RTS, FPGA_SERIAL_CTS);
    uart_driver_install(UART_NUM_2, RX_BUF_SIZE , TX_BUF_SIZE, 0, NULL, 0);
    vTaskDelay( 20 / portTICK_PERIOD_MS );
    Motors_Reset();
    vTaskDelay( 500 / portTICK_PERIOD_MS );
    gpio_set_level((gpio_num_t)Motor1_Reset, 1);
    gpio_set_level((gpio_num_t)Motor2_Reset, 1);

    xTaskCreate(gpio_task_example, "gpio_task_example", 2048, NULL, 10, NULL);

    wifi_init_sta();
    while(1){
        if(Wifi_ready == true){ //check if wifi is connected
        //xTaskCreatePinnedToCore(&FPGA_Listen, "FPGA_Serial_Listen", 15000, NULL, 3, &FPGAListenTask_Handle,1);
        //xTaskCreatePinnedToCore(&UDP_Listen, "UDP_Listen", 15000, NULL, 5, &UDPListenTask_Handle,0);
        //xTaskCreatePinnedToCore(&IP_Broadcast, "IP_Broadcast", 15000, NULL, 2, &IpBroadcastTask_Handle,0);
        //xTaskCreate(gpio_task_example, "gpio_task_example", 2048, NULL, 10, NULL);
        break;
        }
    }
}
