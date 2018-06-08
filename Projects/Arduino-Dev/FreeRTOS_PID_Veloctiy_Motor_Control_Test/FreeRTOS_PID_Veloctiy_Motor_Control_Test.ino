#include "FreeRTOS_AVR.h"
#include "basic_io_avr.h"
#include <Sabertooth.h>
#include <PID_v1.h>

#define NO_NEWLINE false

volatile long count = 0;
volatile byte portCval, index, state, statep;
volatile int QEM[16] = {0, -1, 0, 1, 1, 0, -1, 0, 0, 1, 0, -1, -1, 0, 1, 0};
double kp = 0.35 , ki = 0.85  , kd = 0.0025 , input = 0, output = 0, setpoint = 0;  // velocity PID
long temp;
float velocity_error_tolerance = 1.0;
long ticks_old = 0 ;
long ticks = 0 ;
String readString;
long target = 0;
long target_org = 0;
long error = 0;
long difference = 0;
bool flag = false;
float circum, velocity, target_velocity, distance;
int p = 0;
long previousMillis = 0;        // will store last time LED was updated
long interval = 500;           // interval at which to blink (milliseconds)
Sabertooth ST1(128, Serial1); // Address 128, and use Serial1 as the serial port.
PID myPID(&input, &output, &setpoint, kp, ki, kd, DIRECT);  // if motor will only run at full speed try 'REVERSE' instead of 'DIRECT'

void setup( void )
{
  Serial.begin(9600);
  Serial1.begin(9600);
  ST1.autobaud();
  DDRJ = 0x00; // all inputs
  PORTJ = 0x00;
  //check current encoder state
  portCval = PINJ & 0b00000011; // masking analog pin 14 and 15
  //4x encoding
  if (portCval == 0b00000011) state = 0;
  if (portCval == 0b00000010) state = 1;
  if (portCval == 0b00000000) state = 2;
  if (portCval == 0b00000001) state = 3;
  
  //pin change interrupt
  PCICR |= (1 << PCIE1); //set Interrupt Vector 1
  PCMSK1 |= (1 << PCINT9) | (1 << PCINT10); //mask digital pin 14 and 15
  
  myPID.SetMode(AUTOMATIC);
  myPID.SetSampleTime(0.1);
  myPID.SetOutputLimits(0 , 127);

  //FreeRTOS creation
  //xTaskCreate( vPID, "PID Control", 200, NULL, 1, NULL );
  xTaskCreate( vSpeedCalc, "Speed Calculation", 2000, NULL, 2, NULL );
  vTaskStartScheduler();

  //go to endless loop if fails
  for ( ;; );
}
static void vPID( void *pvParameters )
{
  TickType_t xLastWakeTime;
  xLastWakeTime = xTaskGetTickCount();
  for ( ;; )
  {
    target_velocity = 5;
    setpoint = target_velocity;
    if ((target_velocity - velocity_error_tolerance < velocity) && (velocity < target_velocity + velocity_error_tolerance))
    {
      velocity = target_velocity;
    }
    input = velocity;
    myPID.Compute();
    ST1.motor(1,15);

    //ST1.motor(1, output);
    vPrintStringAndFloat( " Output ", output, NO_NEWLINE);
    vPrintStringAndFloat( " Target ", target_velocity, NO_NEWLINE);
    vPrintStringAndFloat( " Ticks/second ", ticks, NO_NEWLINE);
    vPrintStringAndFloat( " Veloctiy ", velocity);
    vTaskDelayUntil( &xLastWakeTime, ( 35 / portTICK_PERIOD_MS ) );
  }
}

static void vSpeedCalc( void *pvParameters )
{
  TickType_t xLastWakeTime;
  xLastWakeTime = xTaskGetTickCount();
  /*Calculate speed at 100ms rate*/
  for ( ;; )
  {
    /*encoder properties
    Quadrature - CPR 8192
    logic set to 4x encoding
    Resolution Highest - one full turn equals 32768 ticks
    */
    
    ticks = abs(count - ticks_old);
    /*
    circum = 2 * PI * 18; //wheel diameter 18"
    distance = (ticks * circum) / 32768; 
    velocity = distance / 1; //inches/second
    */
    ticks_old = count;
    vPrintStringAndFloat( "", ticks);
    vTaskDelayUntil( &xLastWakeTime, ( 50 / portTICK_PERIOD_MS ) );
  }
}

ISR (PCINT1_vect) //Interrupt service routine - Interrupt vector 1 for portC
{
  //Although by default avr doesn't let you interrupt an interrupt, its a good practice to disable it anyways.
  cli(); //disable global interrupts
  statep = state; //save original state
  portCval = PINJ & 0b00000011; // masking analog pin 3 & 4
  //4x encoding
  if (portCval == 0b00000011) state = 0;
  if (portCval == 0b00000010) state = 1;
  if (portCval == 0b00000000) state = 2;
  if (portCval == 0b00000001) state = 3;
  index = 4 * state + statep;
  count = count + QEM[index];
  sei();//enable global interrupts
}

void loop() {}







