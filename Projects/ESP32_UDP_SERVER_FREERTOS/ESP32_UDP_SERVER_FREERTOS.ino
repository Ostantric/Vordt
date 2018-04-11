#include <ArduinoJson.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <Wire.h> 
#include <WiFi.h>
#include <WiFiUdp.h>


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

String readString;
byte address_velocity = 16;
int  value = 0;
void setup() {
  // put your setup code here, to run once:
  Serial.begin(112500);
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

  if ( UDP_Semaphore == NULL )  // Check to confirm that the Serial Semaphore has not already been created.
  {
    UDP_Semaphore = xSemaphoreCreateMutex();  // Create a mutex semaphore we will use to manage the Serial Port
    if ( ( UDP_Semaphore ) != NULL )
      xSemaphoreGive( ( UDP_Semaphore ) );  // Make the Serial Port available for use, by "Giving" the Semaphore.
  }

  xTaskCreate(
    taskOne,          /* Task function. */
    "TaskOne",        /* String with name of task. */
    10000,            /* Stack size in words. */
    NULL,             /* Parameter passed as input of the task */
    2,                /* Priority of the task. */
    NULL);            /* Task handle. */

  xTaskCreate(
    taskTwo,          /* Task function. */
    "TaskTwo",        /* String with name of task. */
    10000,            /* Stack size in words. */
    NULL,             /* Parameter passed as input of the task */
    3,                /* Priority of the task. */
    NULL);            /* Task handle. */
   xTaskCreate(
    taskThree,          /* Task function. */
    "TaskThree",        /* String with name of task. */
    10000,            /* Stack size in words. */
    NULL,             /* Parameter passed as input of the task */
    4,                /* Priority of the task. */
    NULL);            /* Task handle. */
    xTaskCreate(
    TaskFour,          /* Task function. */
    "TaskFour",        /* String with name of task. */
    10000,            /* Stack size in words. */
    NULL,             /* Parameter passed as input of the task */
    1,                /* Priority of the task. */
    NULL);            /* Task handle. */




}

void loop() {
}

void taskOne( void * parameter )
{
  boolean forward = true;
  for ( ;;) {

    position=position+5;
    
    
    
    if (position > 32767)
    {
      position = 0;
    }
    if(position==32760)
    {
      turn++;
    }
  
    if (speed == 500)
    {
     forward = false; 
    }
    else if(speed == -500)
    {
      forward = true;
    }


    if (forward)
    {
      speed=speed+1;
    }
    else
    {
      speed=speed-1;
    }
    
      
    
    
    //Serial.println("task 1");



    delay(5);
  }
}

void taskTwo( void * parameter)
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

        int noBytes = Udp.parsePacket();
 if ( noBytes ) {
      Serial.print(millis() / 1000);
      Serial.print(":Packet of ");
      Serial.print(noBytes);
      Serial.print(" received from ");
      Serial.print(Udp.remoteIP());
      Serial.print(":");
      Serial.println(Udp.remotePort());
  // We've received a packet, read the data from it
      Udp.read(packetBuffer, noBytes); // read the packet into the buffer

      // display the packet contents in HEX
      for (int i = 1; i <= noBytes; i++) {
        Serial.print(packetBuffer[i - 1], HEX);
        if (i % 32 == 0) {
          Serial.println();
        }
        else Serial.print(' ');
      } // end for
      Serial.println();
    } // end if
    //delay(5);
    if(xSemaphoreTake(UDP_Semaphore, (TickType_t) 5) == pdTRUE)
    {
    Udp.beginPacket();
    Udp.println(JSONmessageBuffer);
    Udp.endPacket();
    //Serial.println("task2 task2");
    xSemaphoreGive( UDP_Semaphore);
    }
    
    delay(20);
    
  }
}
void taskThree( void * parameter)
{
for (;;) {
    StaticJsonBuffer<300> JSONbuffer;
    JsonObject& JSONencoder = JSONbuffer.createObject();
    JSONencoder["Type"] = "Utility";
    JSONencoder["Voltage"] = voltage;
    char JSONmessageBuffer[256];
    JSONencoder.printTo(JSONmessageBuffer, sizeof(JSONmessageBuffer));
    if(xSemaphoreTake(UDP_Semaphore, (TickType_t) 5) == pdTRUE)
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



