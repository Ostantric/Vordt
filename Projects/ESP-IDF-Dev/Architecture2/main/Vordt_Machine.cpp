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
#include "driver/i2c.h"
#include "sdkconfig.h"
#include "soc/timer_group_struct.h"
#include "soc/i2c_struct.h"
#include "soc/i2c_reg.h"
//#include "soc.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "freertos/queue.h"

//#include "I2C.h"

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
//--------------------I2C------------------------------------------------------
#define I2C_SLAVE_RX_BUFFER_LEN 256
#define I2C_SLAVE_TX_BUFFER_LEN 256
#define ESP32_SLAVE_ADDRESS 0x0A
#define I2C_SLAVE_SCL GPIO_NUM_22
#define I2C_SLAVE_SDA GPIO_NUM_23
#define SSID_REGISTER (uint8_t ) 0x01
#define PASSWORD_REGISTER (uint8_t ) 0x02
#define I2C_ENTER_CRITICAL(mux)        portENTER_CRITICAL(mux)
#define I2C_EXIT_CRITICAL(mux)         portEXIT_CRITICAL(mux)
#define I2C_ENTER_CRITICAL_ISR(mux)    portENTER_CRITICAL_ISR(mux)
#define I2C_EXIT_CRITICAL_ISR(mux)     portEXIT_CRITICAL_ISR(mux)
static portMUX_TYPE i2c_spinlock[I2C_NUM_MAX] = {portMUX_INITIALIZER_UNLOCKED, portMUX_INITIALIZER_UNLOCKED};
static DRAM_ATTR i2c_dev_t* const I2C[I2C_NUM_MAX] = { &I2C0, &I2C1 };
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
static const char *SMART_INTR_TAG = "SMARTCONNET_ISR";
static const char *I2C_INTR_TAG = "I2C_ISR";
static const char *I2C_TAG = "I2C_TASK";
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
esp_err_t i2c_err;
wifi_config_t *wifi_config;
WiFi wifi; //wifi object
uint8_t nvs_ssid[32] = { 0 };
uint8_t nvs_password[64] = { 0 };
uint8_t nvs_test[64] = { 0 };
static EventGroupHandle_t wifi_event_group; //wifi events group
//static const int CONNECTED_BIT = BIT0; //smart_wifi connected
const int WIFI_CONNECTED_BIT = BIT0;//wifi connected
static const int ESPTOUCH_DONE_BIT = BIT1; //smartconfig done bit
bool Wifi_ready = false; //smart connect flag
//Semaphores
//For future use
static SemaphoreHandle_t UDP_Semaphore = NULL;
static SemaphoreHandle_t MotorDriver_Serial_Semaphore = NULL;
static SemaphoreHandle_t I2C_Semaphore = NULL;
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
static QueueHandle_t I2C_evt_queue = NULL;
intr_handle_t i2c_handle;
i2c_obj_t i2c_obj;
static void i2c_isr_handler(void* arg);



/****************************************** TASKS ****************************************/

void I2C_Interrupt(void* arg)//fix this task
{
    while(1){
        vTaskDelay(100/portTICK_PERIOD_MS);
    }
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
            ESP_LOGI(SMART_INTR_TAG,"GPIO[%d] intr, val: %d\n", io_num, gpio_get_level((gpio_num_t)io_num));
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



static void IRAM_ATTR gpio_isr_handler(void* arg)
{
    uint32_t gpio_num = (uint32_t) arg;
    xQueueSendFromISR(gpio_evt_queue, &gpio_num, NULL);
                //ESP_LOGI(SMART_INTR_TAG,"Interrupt");
    //initialize_smart_connect();
}

static void IRAM_ATTR i2c_isr_handler(void* arg)
{
    uint32_t port_num = (uint32_t) arg;
    uint32_t stats = I2C[port_num]->int_status.val;
    uint32_t command;
    uint32_t slave_rw = I2C[port_num]->status_reg.slave_rw;
    if(stats & I2C_SLAVE_TRAN_COMP_INT_RAW_M){
        if(slave_rw == 0){
            command =I2C[port_num]->fifo_data.data;
            //I2C[port_num]->fifo_conf.tx_fifo_rst=0;
            if(command == 1){
                //I2C[port_num]->int_ena.tx_send_empty=0;
                for(int i =0; i<32; i++){
                    I2C[port_num]->fifo_data.data=nvs_ssid[i];
                }

                //xQueueSendFromISR(I2C_evt_queue,)
            }else if (command == 2){
                //I2C[port_num]->int_ena.tx_send_empty=1;
                for(int i =0; i<32; i++){
                    I2C[port_num]->fifo_data.data=nvs_password[i];
                }
            }
            I2C[port_num]->ctr.trans_start = 1;
        }
        else if( slave_rw == 1){//fix this
            I2C[port_num]->ctr.trans_start = 0;
        }
    }
    /*if(stats & I2C_TX_SEND_EMPTY_INT_ST_M){
        if(slave_rw == 1){
            I2C[port_num]->int_ena.tx_send_empty=0;
            for(int i=32; i<64; i++){
                I2C[port_num]->fifo_data.data=nvs_password[i];
            }
            I2C[port_num]->fifo_conf.tx_fifo_rst=1;
        }
    }*/
    I2C[I2C_NUM_0]->int_clr.val = 0xFFFF;
}

void start_tasks(){
    //xTaskCreatePinnedToCore(&Test_ROS, "ROS Test", 5000, NULL, 2, &TEST_ROS_HANDLE,0);
    //xTaskCreate(&ROS_IP_Listen, "Listen Roscore IP", 15000, NULL, 1, NULL);
    //xTaskCreate(&I2C_Slave, "I2C Slave", 15000, NULL, 2, NULL);
    //xTaskCreate(&Test,"Test deadzone", 2048, NULL, 5, NULL);
}
void kill_tasks(){
    //vTaskDelete(MotorDriverListenTask_Handle);
}
//reset smart connect
void smartconnect_button_init(){
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
}
//i2c slave init(Jetson TX1 is the master)
void i2c_slave_init(){
    static i2c_obj_t *p_i2c_obj[3] = {0};
    i2c_config_t conf_slave;
    conf_slave.sda_pullup_en = GPIO_PULLUP_ENABLE; //pullups
    conf_slave.scl_pullup_en = GPIO_PULLUP_ENABLE;
    conf_slave.mode = I2C_MODE_SLAVE; //slave mode
    conf_slave.slave.addr_10bit_en = 0;//7bit address enabled
    conf_slave.slave.slave_addr=ESP32_SLAVE_ADDRESS;//Set slave address
    conf_slave.scl_io_num = I2C_SLAVE_SCL; //double check this
    conf_slave.sda_io_num = I2C_SLAVE_SDA; // double check this
    //conf_slave.master.clk_speed = 100000;
    I2C_evt_queue = xQueueCreate(50, sizeof(uint32_t));
    uint32_t flag = ESP_INTR_FLAG_LOWMED | ESP_INTR_FLAG_EDGE | ESP_INTR_FLAG_IRAM;
    ESP_ERROR_CHECK(i2c_param_config(I2C_NUM_0, &conf_slave));
    
    //i2c_isr_register(I2C0,&i2c_isr_handler, (void *) I2C_NUM_0,flags,&i2c_handle);
    ESP_ERROR_CHECK(i2c_driver_install(I2C_NUM_0, conf_slave.mode,I2C_SLAVE_RX_BUFFER_LEN, I2C_SLAVE_TX_BUFFER_LEN,0,&i2c_obj));
    //I2C[I2C_NUM_0]->int_clr.val = 255;
    esp_intr_alloc(ETS_I2C_EXT0_INTR_SOURCE, flag, &i2c_isr_handler, (void *) I2C_NUM_0, &i2c_handle);
    I2C[I2C_NUM_0]->int_ena.val = I2C_SLAVE_TRAN_COMP_INT_ENA_M;//| I2C_TRANS_COMPLETE_INT_ENA_M ;//| I2C_TX_SEND_EMPTY_INT_ENA_M | I2C_TRANS_START_INT_ENA |I2C_TRANS_COMPLETE_INT_ENA |I2C_RX_REC_FULL_INT_ENA_M ;
    I2C[I2C_NUM_0]->int_clr.val = 0xFFFF;
    //esp_intr_alloc(ETS_I2C_EXT1_INTR_SOURCE, intr_alloc_flags, fn, arg, handle);
    //i2c_isr_register(I2C_NUM_0,i2c_isr_handler,p_i2c_obj[I2C_NUM_0],flags,&i2c_handle);    
    //i2c_isr_free()
}

/****************************** MAIN *********************************************************/
void app_main(void)//Starting point
{
    //ESP_ERROR_CHECK(nvs_flash_erase());
    nvs_err = nvs_flash_init();
    ESP_ERROR_CHECK(nvs_err);
    i2c_slave_init();
    /*
    #define I2C_SDA_IO_ERR_STR             "sda gpio number error"
    #define I2C_SCL_IO_ERR_STR             "scl gpio number error"
    */
    vTaskDelay( 100 / portTICK_PERIOD_MS );
    gpio_pad_select_gpio(IP_Blink);
    
    gpio_set_direction((gpio_num_t)IP_Blink, GPIO_MODE_OUTPUT);

    smartconnect_button_init();
    
    vTaskDelay( 20 / portTICK_PERIOD_MS );
  if ( UDP_Semaphore == NULL )  // Check to confirm that the UDP_Semaphore has not already been created.
  {
    UDP_Semaphore = xSemaphoreCreateMutex();  // Create a mutex semaphore we will use to manage the UDP Socket
    if ( ( UDP_Semaphore ) != NULL )
      xSemaphoreGive( ( UDP_Semaphore ) );  // Make the UDP Socket available for use, by "Giving" the Semaphore.
  }
  if ( I2C_Semaphore == NULL )  // Check to confirm that the UDP_Semaphore has not already been created.
  {
    I2C_Semaphore = xSemaphoreCreateMutex();  // Create a mutex semaphore we will use to manage the UDP Socket
    if ( ( I2C_Semaphore ) != NULL )
      xSemaphoreGive( ( I2C_Semaphore ) );  // Make the UDP Socket available for use, by "Giving" the Semaphore.
  }

    
    for(int i = 0; i<64; i++){
        nvs_test[i]=0x31;
    }
        //xTaskCreate(Smart_Connect_Interrupt, "Smart_Connect_Reset", 2048, NULL, 10, NULL);
    xTaskCreate(I2C_Interrupt, "I2C interrupt", 8192, NULL, 18, NULL);

    MotorDriver.start(1000000);
    wifi_init_sta();
    vTaskDelay( 100 / portTICK_PERIOD_MS );
    
    //stay here until connected to wifi
    while(1){
        if(Wifi_ready == true){ //check if wifi is connected
        break;
        }
    }  
}
