#include <ArduinoJson.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <Wire.h> 
#include <WiFi.h>
#include <WiFiUdp.h>
#include "HardwareSerial.h"

#define MCU_Ready 12
#define DEBUG_SETUP
//define DEBUG_FPGA_Listen_Task
//#define DEBUG_UDP_Listen_Task
//#define DEBUG_Movement_UDP_Send_Task
//#define DEBUG_Utility_UDP_Send_Task
#define DEBUG_Send_MaxVel_Task
#define DEBUG_Send_Turn_Task
#define DEBUG_Send_Position_Task

HardwareSerial FPGA_Serial(2);

const char* ssid     = "RTAC3200";
const char* password = "365365365a";

IPAddress local_IP(192, 168, 1, 228);
IPAddress gateway(192, 168, 1, 1);
IPAddress subnet(255, 255, 255, 0);

volatile short speed = 0;
volatile short position = 0;
volatile int turn = 0;

volatile double voltage = 25.4;
unsigned int Port = 1500;

SemaphoreHandle_t UDP_Semaphore;
SemaphoreHandle_t FPGA_Serial_Semaphore;

WiFiUDP Udp;


byte packetBuffer[256]; //buffer to hold incoming and outgoing packets

byte *send_buffer[256];

byte address_velocity = 16;
int  value = 0;

/*FPGA Related Task Handle*/
TaskHandle_t SendPositionTask_Handle;
TaskHandle_t SendMaxVelocityTask_Handle;
TaskHandle_t SendTurnTask_Handle;;


/*Wifi-Tablet Related Task Handle*/
TaskHandle_t FPGAListenTask_Handle;
TaskHandle_t UDPListenTask_Handle;
TaskHandle_t MovementUDPSendTask_Handle;
TaskHandle_t UtilityUDPSendTask_Handle;
TaskHandle_t IncomingJsonParser_Handle;


void setup() {
  // put your setup code here, to run once:
  Serial.begin(112500);
  pinMode(MCU_Ready,OUTPUT);
  
  Wire.begin(SDA,SCL);
  Wire.setClock(400000);
  FPGA_Serial.begin(2000000);
  digitalWrite(MCU_Ready,LOW);
  delay(500);
  if (!WiFi.config(local_IP, gateway, subnet)) {
    Serial.println("STA Failed to configure");
  }
  #ifdef DEBUG_SETUP
  Serial.println();
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  #endif
  WiFi.begin(ssid, password);

  int tries = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    #ifdef DEBUG_SETUP
    Serial.print(".");
    #endif
    tries++;
    if (tries > 30) {
      break;
    }
  }
  #ifdef DEBUG_SETUP
  Serial.println();
  Serial.println("Connected to wifi");
  #endif
  IPAddress ip = WiFi.localIP();
  #ifdef DEBUG_SETUP
  Serial.print("IP Address: ");
  Serial.println(ip);
  #endif
  delay(500);
  #ifdef DEBUG_SETUP
  Serial.print("Udp server started at port ");
  Serial.println(Port);
  #endif
  Udp.begin(Port);
  //Create Semaphore for UDP port
  if ( UDP_Semaphore == NULL )  // Check to confirm that the UDP Semaphore has not already been created.
  {
    UDP_Semaphore = xSemaphoreCreateMutex();  // Create a mutex semaphore we will use to manage the UDP Port
    if ( ( UDP_Semaphore ) != NULL )
      xSemaphoreGive( ( UDP_Semaphore ) );  // Make the UDP Port available for use, by "Giving" the Semaphore.
  }
  //Create Semaphore for FPGA_Serial port
  if ( FPGA_Serial_Semaphore == NULL )  // Check to confirm that the FPGA_Serial Semaphore has not already been created.
  {
    FPGA_Serial_Semaphore = xSemaphoreCreateMutex();  // Create a mutex semaphore we will use to manage the FPGA_Serial Port
    if ( ( FPGA_Serial_Semaphore ) != NULL )
      xSemaphoreGive( ( FPGA_Serial_Semaphore ) );  // Make the FPGA_Serial Port available for use, by "Giving" the Semaphore.
  }
  
  //Listenning incoming packets from Tablet
  xTaskCreate(
    UDP_Listen,          /* Task function. */
    "UDP_Listen",        /* String with name of task. */
    20000,            /* Stack size in words. */
    NULL,             /* Parameter passed as input of the task */
    4,                /* Priority of the task. */
    &UDPListenTask_Handle);            /* Task handle. */
  //Listen incoming packets from FPGA_Serial
  xTaskCreate(
    FPGA_Listen,          /* Task function. */
    "FPGA_Serial_Listen",        /* String with name of task. */
    20000,            /* Stack size in words. */
    NULL,             /* Parameter passed as input of the task */
    3,                /* Priority of the task. */
    &FPGAListenTask_Handle);            /* Task handle. */
  //Send utility info to tablet
  xTaskCreate(
    Utility_UDP_Send,          /* Task function. */
    "Utility_UDP_Send",        /* String with name of task. */
    10000,            /* Stack size in words. */
    NULL,             /* Parameter passed as input of the task */
    2,                /* Priority of the task. */
    &UtilityUDPSendTask_Handle);            /* Task handle. */
  //Send movement info to tablet
  xTaskCreate(
    Movement_UDP_Send,          /* Task function. */
    "Movement_UDP_Send",        /* String with name of task. */
    30000,            /* Stack size in words. */
    NULL,             /* Parameter passed as input of the task */
    1,                /* Priority of the task. */
    &MovementUDPSendTask_Handle);            /* Task handle. */
}

void loop() {
  //idle
  //priority = 0
}

void FPGA_Listen( void * parameter )
{
  boolean forward = true;
  String readIncoming;
  int incomingbyte1;
  int incomingbyte2;
  int incomingbyte3;
  int incomingbyte4;
  int incomingbyte5;
  
  
  for ( ;;) {
    delay(2);
    digitalWrite(MCU_Ready,HIGH);
    delay(0.01);
    digitalWrite(MCU_Ready,LOW);

    if (FPGA_Serial.available()>0){
      delay(1);
      if(xSemaphoreTake(FPGA_Serial_Semaphore, (TickType_t) 15) == pdTRUE){
        incomingbyte1 = FPGA_Serial.read();
        xSemaphoreGive(FPGA_Serial_Semaphore);
      }
      delay(0.1);
      switch(incomingbyte1){
        case 1:
          delay(0.1);
          incomingbyte2 = FPGA_Serial.read();
          delay(0.1);
          incomingbyte3 = FPGA_Serial.read();
          delay(1);
          position= ((byte)incomingbyte3 << 8) | ((byte)incomingbyte2);
          #ifdef DEBUG_FPGA_Listen_Task
          Serial.print("Position:");
          //Serial.println(incomingbyte1,HEX);
          Serial.print(incomingbyte3,HEX);
          Serial.print(incomingbyte2,HEX);
          Serial.print(" ");
          Serial.println(position);
          #endif
          delay(0.1);
          break;
        case 2:
          delay(0.1);
          incomingbyte2 = FPGA_Serial.read();
          delay(0.1);
          incomingbyte3 = FPGA_Serial.read();
          delay(1);
          speed=((byte)incomingbyte3 << 8) | ((byte)incomingbyte2);
          #ifdef DEBUG_FPGA_Listen_Task
          Serial.print(" Velocity:");
          //Serial.println(incomingbyte1,HEX);
          Serial.print(incomingbyte3,HEX);
          Serial.print(incomingbyte2,HEX);
          Serial.print(" ");
          Serial.print(speed);
          #endif
          delay(0.1);
          break;
        case 3:
          delay(0.1);
          incomingbyte2 = FPGA_Serial.read();
          delay(0.1);
          incomingbyte3 = FPGA_Serial.read();
          delay(0.1);
          incomingbyte4 = FPGA_Serial.read();
          delay(0.1);
          incomingbyte5 = FPGA_Serial.read();
          delay(1);
          turn = ((byte)incomingbyte5 << 24) | ((byte)incomingbyte4 << 16) | ((byte)incomingbyte3 << 8) | ((byte)incomingbyte2);
          #ifdef DEBUG_FPGA_Listen_Task
          Serial.print(" Turn:");
          //Serial.println(incomingbyte1,HEX);
          Serial.print(incomingbyte5,HEX);
          Serial.print(incomingbyte4,HEX);
          Serial.print(incomingbyte3,HEX);
          Serial.print(incomingbyte2,HEX);
          Serial.print(" ");
          Serial.println(turn);
         
          #endif
          //Serial.println(turn);
          delay(0.1);
          break;
          default:
          
          break;
        
      }     
    
    }
    delay(10);

//    position=position+5;
//    
//    if (position > 32767){
//      position = 0;
//    }
//    if(position>32765){
//      turn++;
//    }
//  
//    if (speed == 500){
//     forward = false; 
//    }
//    else if(speed == -500){
//      forward = true;
//    }
//
//    if (forward){
//      speed=speed+1;
//    }
//    else{
//      speed=speed-1;
//    }
    //int n_bytes = .available();
    //delay(5);
  }
}

void UDP_Listen( void * parameter)
{
  for (;;)
  {
    int noBytes = Udp.parsePacket();
  if ( noBytes ) {
      #ifdef DEBUG_UDP_Listen_Task
      Serial.print(millis() / 1000);
      Serial.print(":Packet of ");
      Serial.print(noBytes);
      Serial.print(" received from ");
      Serial.print(Udp.remoteIP());
      Serial.print(":");
      Serial.println(Udp.remotePort());
      #endif
      Udp.read(packetBuffer, noBytes); // read the packet into the buffer
      // display the packet contents
      for (int i = 1; i <= noBytes; i++) {
        #ifdef DEBUG_UDP_Listen_Task
        Serial.write(packetBuffer[i-1]);
        #endif
        //Serial.print(packetBuffer[i - 1], HEX);
        //if (i % 32 == 0) {
        //  Serial.println();
        //}
        //else Serial.print(' ');
      } // end for
      #ifdef DEBUG_UDP_Listen_Task
      Serial.println();
      #endif
      /*Start Json Packet Parser Task*/
      xTaskCreate(IncomingJsonParser,"Incoming_Packet_Json_Parser",15000,(void *) packetBuffer,5,&IncomingJsonParser_Handle);
      delay(5);
    } // end if
    //Serial.println("udp_listen");
    
    delay(10);
  }
}

void Movement_UDP_Send( void * parameter)
{
  for (;;) {
    StaticJsonBuffer<100> JSONbuffer;
    JsonObject& JSONencoder = JSONbuffer.createObject();
    JSONencoder["Type"] = "Movement";
    JSONencoder["Position"] = position;
    JSONencoder["Velocity"] = speed;
    JSONencoder["Turn"]= turn;
    //JSONencoder["Voltage"] = voltage;
    char JSONmessageBuffer[128];
    JSONencoder.printTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
    delay(5);
    if(xSemaphoreTake(UDP_Semaphore, (TickType_t) 2) == pdTRUE)
    {
    Udp.beginPacket();
    Udp.println(JSONmessageBuffer);
    Udp.endPacket();
    #ifdef DEBUG_Movement_UDP_Send_Task
    Serial.println("M_Send");
    #endif
    xSemaphoreGive( UDP_Semaphore);
    }
    //Serial.println(position);

    delay(5);
    
  }
}
void Utility_UDP_Send( void * parameter)
{
for (;;) {
    StaticJsonBuffer<300> JSONbuffer;
    JsonObject& JSONencoder = JSONbuffer.createObject();
    JSONencoder["Type"] = "Utility";
    JSONencoder["Voltage"] = voltage;
    char JSONmessageBuffer[256];
    JSONencoder.printTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
    if(xSemaphoreTake(UDP_Semaphore, (TickType_t) 15) == pdTRUE)
    {
    Udp.beginPacket();
    Udp.println(JSONmessageBuffer);
    Udp.endPacket();
    //Serial.println("task3 task3 task3");
    xSemaphoreGive( UDP_Semaphore);
    #ifdef DEBUG_Utility_UDP_Send_Task
    Serial.println("U_Send");
    #endif
    }
    voltage++;
    
    delay(15000);
  }
}

void TaskFour ( void * parameter)
{
  String readString;
  for (;;) {
  while (Serial.available()) {
      delay(2);  //delay to allow byte to arrive in input buffer
      char c = Serial.read();
      readString += c;
    }
    if(readString != '\0'){
    value =readString.toInt();
      
      Wire.beginTransmission(0x40); // transmit to device #8
      
      //Wire.write(address_velocity);
      Wire.write(value);
      //Wire.write(value);

      Wire.endTransmission(true);
      delay(50);
    }
    //Serial.println("task4 task4 task4 task4");
    readString="";
  }
}

void IncomingJsonParser( void * parameter)
{
  char *packet;
  packet = ( char * ) parameter;   
  StaticJsonBuffer<200> packet_JSON;
  JsonObject& root = packet_JSON.parseObject(packet);
  const char* types = root["type"];
  long value = root["value"];
  char sendtotask[12];
  
  itoa(value, sendtotask,10);
  #ifdef DEBUG_IncomingJsonParser_Task 
  Serial.println("parsed");
  Serial.println(types);
  Serial.println(packet);
  Serial.println(value);
  #endif
  delay(5);
  if (types != '\0') //check if its empty
  {
   if (strcmp(types,"dpos") == 0 ){
        xTaskCreate(Send_Position,"Send_Position_Task",10000,(void *) sendtotask,6,&SendPositionTask_Handle);
        delay(5);
      }
   if (strcmp(types,"dturn") == 0 ){
        xTaskCreate(Send_Turn,"Send_Turn_Task",10000,(void *) sendtotask,6,&SendTurnTask_Handle);
        delay(5);
      }
   if (strcmp(types,"dvel") == 0 ){
        xTaskCreate(Send_MaxVel,"Send_MaxVel_Task",10000,(void *) sendtotask,6,&SendMaxVelocityTask_Handle);
        delay(5);
      }
 
  }
  delay(10); 
  vTaskDelete(IncomingJsonParser_Handle);
  
}

void Send_Position ( void * parameter) //16 bits
{
  char *char_pos;
  char_pos = ( char * ) parameter;
  int desired_position = atoi(char_pos);
  byte readytosend[2] = { highByte(desired_position),lowByte(desired_position)};
  #ifdef DEBUG_Send_Position_Task
  Serial.print("position sent: ");
  Serial.println(desired_position);
  #endif
  if(xSemaphoreTake(FPGA_Serial_Semaphore, (TickType_t) 15) == pdTRUE){
    FPGA_Serial.write(0x01);
    FPGA_Serial.write(readytosend[0]);
    FPGA_Serial.write(readytosend[1]);
    xSemaphoreGive(FPGA_Serial_Semaphore);
  }
  vTaskDelete(SendPositionTask_Handle);
}

void Send_Turn ( void * parameter) //32bits
{
  char *char_turn;
  char_turn = ( char * ) parameter;
  long desired_turn = atol(char_turn);
  //long desired_turn = 1500000000; //0x59682F00
  delay(5);
  byte readytosend[4] = { (byte) (desired_turn >> 24) & 0xFF ,(byte) (desired_turn >> 16) & 0xFF, (byte) (desired_turn >> 8) & 0xFF , (byte) desired_turn};
  delay(5);
  #ifdef DEBUG_Send_Turn_Task
  Serial.print("turn sent: ");
  Serial.println(desired_turn);
  #endif
  if(xSemaphoreTake(FPGA_Serial_Semaphore, (TickType_t) 15) == pdTRUE){
    FPGA_Serial.write(0x03);
    FPGA_Serial.write(readytosend[0]);
    FPGA_Serial.write(readytosend[1]);
    FPGA_Serial.write(readytosend[2]);
    FPGA_Serial.write(readytosend[3]);
    xSemaphoreGive(FPGA_Serial_Semaphore);
  }
  vTaskDelete(SendTurnTask_Handle);  
  
}

void Send_MaxVel ( void * parameter) //16bits
{
  char *char_vel;
  char_vel = ( char * ) parameter;
  int max_velocity = atoi(char_vel);
  byte readytosend[2] = { highByte(max_velocity),lowByte(max_velocity)};
  #ifdef DEBUG_Send_MaxVel_Task
  Serial.print("maxvel sent: ");
  Serial.println(max_velocity);
  #endif
  if(xSemaphoreTake(FPGA_Serial_Semaphore, (TickType_t) 15) == pdTRUE){
    FPGA_Serial.write(0x02);
    FPGA_Serial.write(readytosend[0]);
    FPGA_Serial.write(readytosend[1]);
    xSemaphoreGive(FPGA_Serial_Semaphore);
  }
  vTaskDelete(SendMaxVelocityTask_Handle);
}


