#include <ArduinoJson.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <Wire.h> 
#include <WiFi.h>
#include <WiFiUdp.h>
#include "HardwareSerial.h"

HardwareSerial FPGA_UART(2);

const char* ssid     = "RTAC3200";
const char* password = "365365365a";

IPAddress local_IP(192, 168, 1, 228);
IPAddress gateway(192, 168, 1, 1);
IPAddress subnet(255, 255, 255, 0);

volatile int speed = 0;
volatile int position = 0;
volatile int turn = 0;
volatile double voltage = 25.4;
unsigned int Port = 1500;

SemaphoreHandle_t UDP_Semaphore;

WiFiUDP Udp;

byte packetBuffer[256]; //buffer to hold incoming and outgoing packets

byte *send_buffer[256];

String readString;
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
  FPGA_UART.begin(1000000,SERIAL_8N1);
  Wire.begin(SDA,SCL);
  Wire.setClock(400000);

  delay(500);
  if (!WiFi.config(local_IP, gateway, subnet)) {
    Serial.println("STA Failed to configure");
  }

  Serial.println();
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  int tries = 0;
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    tries++;
    if (tries > 30) {
      break;
    }
  }
  Serial.println();
  Serial.println("Connected to wifi");
  IPAddress ip = WiFi.localIP();
  Serial.print("IP Address: ");
  Serial.println(ip);
  delay(500);
  Serial.print("Udp server started at port ");
  Serial.println(Port);
  Udp.begin(Port);
  //Create Semaphore for UDP port
  if ( UDP_Semaphore == NULL )  // Check to confirm that the UDP Semaphore has not already been created.
  {
    UDP_Semaphore = xSemaphoreCreateMutex();  // Create a mutex semaphore we will use to manage the UDP Port
    if ( ( UDP_Semaphore ) != NULL )
      xSemaphoreGive( ( UDP_Semaphore ) );  // Make the UDP Port available for use, by "Giving" the Semaphore.
  }
  //Listenning incoming packets from Tablet
  xTaskCreate(
    UDP_Listen,          /* Task function. */
    "UDP_Listen",        /* String with name of task. */
    10000,            /* Stack size in words. */
    NULL,             /* Parameter passed as input of the task */
    4,                /* Priority of the task. */
    &UDPListenTask_Handle);            /* Task handle. */
  //Listen incoming packets from FPGA_UART
  xTaskCreate(
    FPGA_Listen,          /* Task function. */
    "FPGA_UART_Listen",        /* String with name of task. */
    10000,            /* Stack size in words. */
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
    10000,            /* Stack size in words. */
    NULL,             /* Parameter passed as input of the task */
    1,                /* Priority of the task. */
    &MovementUDPSendTask_Handle);            /* Task handle. */
}

void loop() {
  //idle
}

void FPGA_Listen( void * parameter )
{
  boolean forward = true;
  for ( ;;) {

    position=position+5;
    
    if (position > 32767){
      position = 0;
    }
    if(position>32765){
      turn++;
    }
  
    if (speed == 500){
     forward = false; 
    }
    else if(speed == -500){
      forward = true;
    }

    if (forward){
      speed=speed+1;
    }
    else{
      speed=speed-1;
    }
    //Serial.println("task 1");
    delay(5);
  }
}

void UDP_Listen( void * parameter)
{
  for (;;)
  {
    int noBytes = Udp.parsePacket();
  if ( noBytes ) {
      Serial.print(millis() / 1000);
      Serial.print(":Packet of ");
      Serial.print(noBytes);
      Serial.print(" received from ");
      Serial.print(Udp.remoteIP());
      Serial.print(":");
      Serial.println(Udp.remotePort());
      Udp.read(packetBuffer, noBytes); // read the packet into the buffer
      // display the packet contents
      for (int i = 1; i <= noBytes; i++) {
        Serial.write(packetBuffer[i-1]);
        //Serial.print(packetBuffer[i - 1], HEX);
        //if (i % 32 == 0) {
        //  Serial.println();
        //}
        //else Serial.print(' ');
      } // end for
      Serial.println();
      /*Start Json Packet Parser Task*/
      xTaskCreate(IncomingJsonParser,"Incoming_Packet_Json_Parser",5000,(void *) packetBuffer,5,&IncomingJsonParser_Handle);
      delay(5);
    } // end if
    if (packetBuffer[2] = *"1") {
      /*Start sending Utility*/
    }
    delay(12);
  }
}

void Movement_UDP_Send( void * parameter)
{
  for (;;) {
    StaticJsonBuffer<300> JSONbuffer;
    JsonObject& JSONencoder = JSONbuffer.createObject();
    JSONencoder["Type"] = "Movement";
    JSONencoder["Position"] = position;
    JSONencoder["Velocity"] = speed;
    JSONencoder["Turn"]= turn;
    //JSONencoder["Voltage"] = voltage;
    char JSONmessageBuffer[256];
    JSONencoder.printTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
    //delay(5);
    if(xSemaphoreTake(UDP_Semaphore, (TickType_t) 15) == pdTRUE)
    {
    Udp.beginPacket();
    Udp.println(JSONmessageBuffer);
    Udp.endPacket();
    //Serial.println("task2 task2");
    xSemaphoreGive( UDP_Semaphore);
    }
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
    }
    voltage++;   
    delay(15000);
  }
}

void TaskFour ( void * parameter)
{
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
   
  //Serial.println("parsed");
  //Serial.println(types);
  //Serial.println(packet);
  //Serial.println(value);
  delay(5);
  if (types != '\0') //check if its empty
  {
   if (strcmp(types,"dpos") == 0 )
      {
        xTaskCreate(Send_Position,"Send_Position_Task",1000,(void *) sendtotask,6,&SendPositionTask_Handle);
        delay(5);
      }
   if (strcmp(types,"dturn") == 0 )
      {
        xTaskCreate(Send_Turn,"Send_Turn_Task",1000,(void *) sendtotask,6,&SendTurnTask_Handle);
        delay(5);
      }
   if (strcmp(types,"dvel") == 0 )
      {
        xTaskCreate(Send_MaxVel,"Send_MaxVel_Task",1000,(void *) sendtotask,6,&SendMaxVelocityTask_Handle);
        delay(5);
      }
 
  }
  //Serial.print();
  
//    delay(5);
//    if (strcmp(types,"dturn")){
//    }
//    delay(5);
//    if (strcmp(types,"dvel")){
//    }
    delay(20);
    
    
  vTaskDelete(IncomingJsonParser_Handle);
  
}

void Send_Position ( void * parameter) //16 bits
{
  char *char_pos;
  char_pos = ( char * ) parameter;
  int desired_position = atoi(char_pos);
  byte readytosend[2] = { highByte(desired_position),lowByte(desired_position)};
  Serial.print("position sent: ");
  Serial.println(desired_position);
  FPGA_UART.write(readytosend[0]);
  FPGA_UART.write(readytosend[1]);
  vTaskDelete(SendPositionTask_Handle);
}

void Send_Turn ( void * parameter) //32bits
{
  char *char_turn;
  char_turn = ( char * ) parameter;
  long desired_turn = atol(char_turn);
  //long desired_turn = 1500000000; //0x59682F00
  delay(5);
  //Serial.println(((byte) (desired_turn >> 24) & 0xFF),HEX);
  //Serial.println(((byte) (desired_turn >> 16) & 0xFF),HEX);
  //Serial.println(((byte) (desired_turn >> 8) & 0xFF),HEX);
  //Serial.println(((byte) desired_turn),HEX);

  byte readytosend[4] = { (byte) (desired_turn >> 24) & 0xFF ,(byte) (desired_turn >> 16) & 0xFF, (byte) (desired_turn >> 8) & 0xFF , (byte) desired_turn};
  delay(5);
  Serial.print("turn sent: ");
  Serial.println(desired_turn);
  FPGA_UART.write(readytosend[0]);
  FPGA_UART.write(readytosend[1]);
  FPGA_UART.write(readytosend[2]);
  FPGA_UART.write(readytosend[3]);
  
  
  vTaskDelete(SendTurnTask_Handle);  
  
}

void Send_MaxVel ( void * parameter) //16bits
{
  char *char_vel;
  char_vel = ( char * ) parameter;
  int max_velocity = atoi(char_vel);
  byte readytosend[2] = { highByte(max_velocity),lowByte(max_velocity)};
  Serial.print("maxvel sent: ");
  Serial.println(max_velocity);
  FPGA_UART.write(readytosend[0]);
  FPGA_UART.write(readytosend[1]);
  vTaskDelete(SendMaxVelocityTask_Handle);
}


