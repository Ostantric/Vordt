#include <ArduinoJson.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <Wire.h> 
#include <WiFi.h>
#include <WiFiUdp.h>
#include "HardwareSerial.h"

#define MCU_Ready 12
#define DEBUG_SETUP
//#define DEBUG_FPGA_Listen_Task
//#define DEBUG_UDP_Listen_Task
//#define DEBUG_Movement_UDP_Send_Task //pos,vel,turn
//#define DEBUG_Utility_UDP_Send_Task
#define DEBUG_Send_MaxVel_Task
#define DEBUG_Send_Turn_Task
#define DEBUG_Send_Position_Task

HardwareSerial FPGA_Serial(2);

const char* ssid     = "RTAC3200";
const char* password = "365365365a";
char i_max_vel[20] ="60";

IPAddress local_IP(192, 168, 1, 228);
IPAddress gateway(192, 168, 1, 1);
IPAddress subnet(255, 255, 255, 0);

volatile short speed = 0;
volatile short position = 0;
volatile int turn = 0;
volatile double voltage = 25.4;

unsigned int Port = 1500;

SemaphoreHandle_t UDP_Semaphore = NULL;
SemaphoreHandle_t FPGA_Serial_Semaphore = NULL;
SemaphoreHandle_t PacketBuffer_Semaphore = NULL;

WiFiUDP Udp;


byte packetBuffer[50]; //buffer to hold incoming and outgoing packets

byte *send_buffer[256];

byte address_velocity = 16;
int  value = 0;

/*FPGA Related Task Handle*/
TaskHandle_t SendPositionToFPGA_Task_Handle;
TaskHandle_t SendMaxVelocityToFPGA_Task_Handle;
TaskHandle_t SendTurnToFPGA_Task_Handle;;


/*Wifi-Tablet Related Task Handle*/
TaskHandle_t FPGAListenTask_Handle;
TaskHandle_t UDPListenTask_Handle;
TaskHandle_t Position_UDP_Send_Handle;
TaskHandle_t Turn_UDP_Send_Handle;
TaskHandle_t Velocity_UDP_Send_Handle;
TaskHandle_t MovementUDPSendTask_Handle;
TaskHandle_t UtilityUDPSendTask_Handle;
TaskHandle_t IncomingJsonParser_Handle;


void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  pinMode(MCU_Ready,OUTPUT);
  
  //Wire.begin(SDA,SCL);
  //Wire.setClock(400000);
  FPGA_Serial.begin(4000000);
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
  if ( PacketBuffer_Semaphore == NULL )  // Check to confirm that the PacketBuffer Semaphore has not already been created.
  {
    PacketBuffer_Semaphore = xSemaphoreCreateMutex();  // Create a mutex semaphore we will use to manage the incoming packet buffer
    if ( ( PacketBuffer_Semaphore ) != NULL )
      xSemaphoreGive( ( PacketBuffer_Semaphore ) );  // Make the PacketBuffer available for use, by "Giving" the Semaphore.
  }
  
  //Listenning incoming packets from Tablet
  xTaskCreate(
    UDP_Listen,          /* Task function. */
    "UDP_Listen",        /* String with name of task. */
    5000,            /* Stack size in words. */
    NULL,             /* Parameter passed as input of the task */
    4,                /* Priority of the task. */
    &UDPListenTask_Handle);            /* Task handle. */
  //Listen incoming packets from FPGA_Serial
  xTaskCreate(
    FPGA_Listen,          /* Task function. */
    "FPGA_Serial_Listen",        /* String with name of task. */
    30000,            /* Stack size in words. */
    NULL,             /* Parameter passed as input of the task */
    2,                /* Priority of the task. */
    &FPGAListenTask_Handle);            /* Task handle. */
  //Send utility info to tablet
  xTaskCreate(
    Utility_UDP_Send,          /* Task function. */
    "Utility_UDP_Send",        /* String with name of task. */
    2000,            /* Stack size in words. */
    NULL,             /* Parameter passed as input of the task */
    1,                /* Priority of the task. */
    &UtilityUDPSendTask_Handle);            /* Task handle. */
  //Send movement info to tablet
  
}

void loop() {
  //idle
  //priority = 0
}

void FPGA_Listen( void * parameter )
{
  byte ibyte[10];
  byte b;
  byte c;
  int l;
  int i=0;
  byte incomingbyte1=0;
  byte incomingbyte2=0;
  byte incomingbyte3=0;
  byte incomingbyte4=0;
  byte incomingbyte5=0;
  String readString;
  for ( ;;) {
    //delay(5);
    //delay(10);
    digitalWrite(MCU_Ready,HIGH); //ugly, fix this using port register
    delay(0.01);
    digitalWrite(MCU_Ready,LOW); //ugly, fix this using port register
    
    delay(1);//This is critical
    if(xSemaphoreTake(FPGA_Serial_Semaphore, (TickType_t) 10) == pdTRUE){
    #ifdef DEBUG_FPGA_Listen_Task
      Serial.println("start");
      l = FPGA_Serial.available();
      Serial.println(l);
    #endif
        
    while (FPGA_Serial.available()>0){
        //delay(0.5);
        //incomingbyte1=FPGA_Serial.read();
        ibyte[i]=FPGA_Serial.read();
        #ifdef DEBUG_FPGA_Listen_Task
          readString += ibyte[i];
           Serial.println(ibyte[i],HEX);
        #endif
        i++;
      }
      #ifdef DEBUG_FPGA_Listen_Task
        Serial.println("end");
      #endif
      
      incomingbyte1 = ibyte[0];
      incomingbyte2 = ibyte[1];
      incomingbyte3 = ibyte[2];
      incomingbyte4 = ibyte[3];
      incomingbyte5 = ibyte[4];
      i=0;
      
        //xSemaphoreGive(FPGA_Serial_Semaphore);
      if (incomingbyte1 == 1) {
          position= (incomingbyte3 << 8) | (incomingbyte2);
          #ifdef DEBUG_FPGA_Listen_Task
          Serial.println();
          Serial.print("Position:");
          Serial.print(incomingbyte1);
          Serial.print(" "); 
          //Serial.println(incomingbyte1,HEX);
          Serial.print(incomingbyte3,HEX);
          Serial.print(incomingbyte2,HEX);
          Serial.print(" ");
          Serial.print(position);
          #endif
          xTaskCreate(Position_UDP_Send,"Position_UDP_Send",5000,NULL,3,&Position_UDP_Send_Handle);
      }
      else if (incomingbyte1 == 2){
          speed=(incomingbyte3 << 8) | (incomingbyte2);
          #ifdef DEBUG_FPGA_Listen_Task
          Serial.print(" Velocity: ");
          Serial.print(incomingbyte1);
          Serial.print(" "); 
          //Serial.println(incomingbyte1,HEX);
          Serial.print(incomingbyte3,HEX);
          Serial.print(incomingbyte2,HEX);
          Serial.print(" ");
          Serial.print(speed);
          #endif
          xTaskCreate(Velocity_UDP_Send,"Velocity_UDP_Send",5000,NULL,3,&Velocity_UDP_Send_Handle);
      }
      else if (incomingbyte1 == 3){
          //delay(1);
          turn = (incomingbyte5 << 24) | (incomingbyte4 << 16) | (incomingbyte3 << 8) | (incomingbyte2);
          #ifdef DEBUG_FPGA_Listen_Task
          Serial.print(" Turn: ");
          Serial.print(incomingbyte1);
          Serial.print(" "); 
          //Serial.println(incomingbyte1,HEX);
          Serial.print(incomingbyte5,HEX);
          Serial.print(incomingbyte4,HEX);
          Serial.print(incomingbyte3,HEX);
          Serial.print(incomingbyte2,HEX);
          Serial.print(" ");
          Serial.println(turn);
          #endif
          xTaskCreate(Turn_UDP_Send,"Turn_UDP_Send",5000,NULL,3,&Turn_UDP_Send_Handle);
      }
      else{
                  xSemaphoreGive(FPGA_Serial_Semaphore);
      } 
    }
    //memset(ibyte,0,sizeof(ibyte));
    b='\0';
    readString="";
    delay(10);
  }
}

void UDP_Listen( void * parameter)
{
  for (;;)
  {
    int noBytes;
    if(xSemaphoreTake(UDP_Semaphore, (TickType_t) 10) == pdTRUE){
      noBytes= Udp.parsePacket();
      
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
      xSemaphoreGive( UDP_Semaphore);
      // display the packet contents
      #ifdef DEBUG_UDP_Listen_Task
      for (int i = 1; i <= noBytes; i++) {
        Serial.write(packetBuffer[i-1]);
        //Serial.print(packetBuffer[i - 1], HEX);
        //if (i % 32 == 0) {
        //  Serial.println();
        //}
        //else Serial.print(' ');
      } // end for
      #endif
      Udp.flush();
      #ifdef DEBUG_UDP_Listen_Task
      Serial.println();
      #endif
      delay(1);
      
      /*Start Json Packet Parser Task*/
      //It is important that serial semaphore is given.(Commands from fpga is set and in order, if MCU loses track, we will have problem)
      //It is also imporatnt that incoming user commands need to be handled, so it is okay to wait for long time. 
      if(xSemaphoreTake(FPGA_Serial_Semaphore, (TickType_t) 1500) == pdTRUE){
        if(xSemaphoreTake(PacketBuffer_Semaphore, (TickType_t) 1500) == pdTRUE){
        xTaskCreate(IncomingJsonParser,"Incoming_Packet_Json_Parser",5000,(void *) packetBuffer,5,&IncomingJsonParser_Handle);
        }
      }
      delay(1);
    } // end if
  }
    //Serial.println("udp_listen");
    if(xSemaphoreTake(PacketBuffer_Semaphore, (TickType_t) 1500) == pdTRUE){
      memset(packetBuffer, 0, sizeof(packetBuffer));
      xSemaphoreGive(PacketBuffer_Semaphore);
    }

    Udp.flush();
    xSemaphoreGive(UDP_Semaphore);
    delay(12);
  }
}

void Movement_UDP_Send( void * parameter)
{
  for (;;) {
    StaticJsonBuffer<200> JSONbuffer;
    JsonObject& JSONencoder = JSONbuffer.createObject();
    JSONencoder["Type"] = "Movement";
    JSONencoder["Position"] = position;
    JSONencoder["Velocity"] = speed;
    JSONencoder["Turn"]= turn;
    //JSONencoder["Voltage"] = voltage;
    char JSONmessageBuffer[256];
    JSONencoder.printTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
    delay(5);
    if(xSemaphoreTake(UDP_Semaphore, (TickType_t) 10) == pdTRUE)
    {
    Udp.beginPacket();
    Udp.println(JSONmessageBuffer);
    Udp.endPacket();
    #ifdef DEBUG_Movement_UDP_Send_Task
    Serial.println("M_Send");
    #endif
    xSemaphoreGive( UDP_Semaphore);
    }
  }
}

void Position_UDP_Send( void * parameter)
{
  StaticJsonBuffer<40> JSONbuffer;
  JsonObject& JSONencoder = JSONbuffer.createObject();
  JSONencoder["Type"] = "Position";
  JSONencoder["Value"] = position;
  char JSONmessageBuffer[40];
  JSONencoder.printTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
  //delay(1);
  if(xSemaphoreTake(UDP_Semaphore, (TickType_t) 10) == pdTRUE){
    Udp.beginPacket();
    Udp.println(JSONmessageBuffer);
    Udp.endPacket();
    Udp.flush();
    #ifdef DEBUG_Movement_UDP_Send_Task
      Serial.println("Current_Position_Sent");
    #endif
    xSemaphoreGive(UDP_Semaphore);
  }
  xSemaphoreGive(FPGA_Serial_Semaphore);
  vTaskDelete(Position_UDP_Send_Handle);
}

void Turn_UDP_Send(void * parameter)
{
  StaticJsonBuffer<64> JSONbuffer;
  JsonObject& JSONencoder = JSONbuffer.createObject();
  JSONencoder["Type"] = "Turn";
  JSONencoder["Value"]= turn;
  char JSONmessageBuffer[64];
  JSONencoder.printTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
  //delay(1);
  if(xSemaphoreTake(UDP_Semaphore, (TickType_t) 10) == pdTRUE){
    Udp.beginPacket();
    Udp.println(JSONmessageBuffer);
    Udp.endPacket();
    Udp.flush();
    #ifdef DEBUG_Movement_UDP_Send_Task
      Serial.println("Current_Turn_Sent");
    #endif
    xSemaphoreGive(UDP_Semaphore);
  }
  xSemaphoreGive(FPGA_Serial_Semaphore);
  vTaskDelete(Turn_UDP_Send_Handle);
}

void Velocity_UDP_Send( void * parameter)
{
  StaticJsonBuffer<40> JSONbuffer;
  JsonObject& JSONencoder = JSONbuffer.createObject();
  JSONencoder["Type"] = "Velocity";
  JSONencoder["Value"] = speed;
  char JSONmessageBuffer[40];
  JSONencoder.printTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
  //delay(1);
  if(xSemaphoreTake(UDP_Semaphore, (TickType_t) 10) == pdTRUE){
    Udp.beginPacket();
    Udp.println(JSONmessageBuffer);
    Udp.endPacket();
    Udp.flush();
    #ifdef DEBUG_Movement_UDP_Send_Task
      Serial.println("Current_Velocity_Sent");
    #endif
    xSemaphoreGive(UDP_Semaphore);
  }
  xSemaphoreGive(FPGA_Serial_Semaphore);
  vTaskDelete(Velocity_UDP_Send_Handle);
}

void Utility_UDP_Send( void * parameter)
{
for (;;) {
    StaticJsonBuffer<40> JSONbuffer;
    JsonObject& JSONencoder = JSONbuffer.createObject();
    JSONencoder["Type"] = "Utility";
    JSONencoder["Voltage"] = voltage;
    char JSONmessageBuffer[40];
    JSONencoder.printTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
    if(xSemaphoreTake(UDP_Semaphore, (TickType_t) 10) == pdTRUE)
    {
    Udp.beginPacket();
    Udp.println(JSONmessageBuffer);
    Udp.endPacket();
    Udp.flush();
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
  xSemaphoreGive(PacketBuffer_Semaphore);
  if (packet != '\0')
  {   
    StaticJsonBuffer<40> packet_JSON;
    JsonObject& root = packet_JSON.parseObject(packet);
    const char* types = root["type"];
    long value = root["value"];
    char sendtotask[20];
    
    itoa(value, sendtotask,10);//decimal
    #ifdef DEBUG_IncomingJsonParser_Task 
    Serial.println("parsed");
    Serial.println(types);
    Serial.println(packet);
    Serial.println(value);
    #endif
    delay(1);
    //Do not miss this. It is okay to wait for semaphore
    if (types != '\0') //check if its empty
    {
     if (strcmp(types,"dpos") == 0 ){
          xTaskCreate(Send_Position_To_FPGA,"Send_Position_To_FPGA_Task",5000,(void *) sendtotask,6,&SendPositionToFPGA_Task_Handle);
          //delay(1);
        }
     if (strcmp(types,"dturn") == 0 ){
          xTaskCreate(Send_Turn_To_FPGA,"Send_Turn_To_FPGA_Task",5000,(void *) sendtotask,6,&SendTurnToFPGA_Task_Handle);
          //delay(1);
        }
     if (strcmp(types,"dvel") == 0 ){
          xTaskCreate(Send_MaxVel_To_FPGA,"Send_MaxVel_To_FPGA_Task",5000,(void *) sendtotask,6,&SendMaxVelocityToFPGA_Task_Handle);
          //delay(1);
        }
    }
    else
    {
      if (strcmp(packet,"1") == 0){
        xTaskCreate(Send_MaxVel_To_FPGA,"Send_MaxVel_To_FPGA_Task",5000,(void *) i_max_vel,6,&SendMaxVelocityToFPGA_Task_Handle);
      }
      else{
        xSemaphoreGive(FPGA_Serial_Semaphore);
      }
    }
  }
  xSemaphoreGive(FPGA_Serial_Semaphore);
  vTaskDelete(IncomingJsonParser_Handle);
}

void Send_Position_To_FPGA ( void * parameter) //16 bits
{
  char *char_pos;
  char_pos = ( char * ) parameter;
  int desired_position = atoi(char_pos);
  byte readytosend[2] = { highByte(desired_position),lowByte(desired_position)};
  #ifdef DEBUG_Send_Position_Task
  Serial.print("position sent: ");
  Serial.println(desired_position);
  #endif
  FPGA_Serial.write(0x01);
  FPGA_Serial.write(readytosend[0]);
  FPGA_Serial.write(readytosend[1]);
  xSemaphoreGive(FPGA_Serial_Semaphore);
  vTaskDelete(SendPositionToFPGA_Task_Handle);
}

void Send_Turn_To_FPGA ( void * parameter) //32bits
{
  char *char_turn;
  char_turn = ( char * ) parameter;
  long desired_turn = atol(char_turn);
  //long desired_turn = 1500000000; //0x59682F00
  byte readytosend[4] = {(byte) (desired_turn >> 24) & 0xFF ,(byte) (desired_turn >> 16) & 0xFF, (byte) (desired_turn >> 8) & 0xFF , (byte) desired_turn};
  #ifdef DEBUG_Send_Turn_Task
  Serial.print("turn sent: ");
  Serial.println(desired_turn);
  #endif
  FPGA_Serial.write(0x03);
  FPGA_Serial.write(readytosend[0]);
  FPGA_Serial.write(readytosend[1]);
  FPGA_Serial.write(readytosend[2]);
  FPGA_Serial.write(readytosend[3]);
  xSemaphoreGive(FPGA_Serial_Semaphore);
  vTaskDelete(SendTurnToFPGA_Task_Handle);  
  
}

void Send_MaxVel_To_FPGA ( void * parameter) //16bits
{
  char *char_vel;
  char_vel = ( char * ) parameter;
  int max_velocity = atoi(char_vel);
  byte readytosend[2] = { highByte(max_velocity),lowByte(max_velocity)};
  #ifdef DEBUG_Send_MaxVel_Task
  Serial.print("maxvel sent: ");
  Serial.println(max_velocity);
  #endif
  FPGA_Serial.write(0x02);
  FPGA_Serial.write(readytosend[0]);
  FPGA_Serial.write(readytosend[1]);
  xSemaphoreGive(FPGA_Serial_Semaphore);
  vTaskDelete(SendMaxVelocityToFPGA_Task_Handle);
}


