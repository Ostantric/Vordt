/*
  FreeRTOS.org V5.0.4 - Copyright (C) 2003-2008 Richard Barry.

  This file is part of the FreeRTOS.org distribution.

  FreeRTOS.org is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  FreeRTOS.org is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with FreeRTOS.org; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

  A special exception to the GPL can be applied should you wish to distribute
  a combined work that includes FreeRTOS.org, without being obliged to provide
  the source code for any proprietary components.  See the licensing section
  of http://www.FreeRTOS.org for full details of how and when the exception
  can be applied.

    ***************************************************************************
    ***************************************************************************
    *                                                                         *
      SAVE TIME AND MONEY!  We can port FreeRTOS.org to your own hardware,
      and even write all or part of your application on your behalf.
      See http://www.OpenRTOS.com for details of the services we provide to
      expedite your project.
    *                                                                         *
    ***************************************************************************
    ***************************************************************************

  Please ensure to read the configuration and relevant port sections of the
  online documentation.

  http://www.FreeRTOS.org - Documentation, latest information, license and
  contact details.

  http://www.SafeRTOS.com - A version that is certified for use in safety
  critical systems.

  http://www.OpenRTOS.com - Commercial support, development, porting,
  licensing and training services.
*/

/* FreeRTOS.org includes. */
#include "FreeRTOS_AVR.h"
//#include "task.h"
//#include "semphr.h"
//#include "portasm.h"

/* Demo includes. */
#include "basic_io_avr.h"

/* Compiler includes. */
//#include <dos.h>

/* The tasks to be created. */
static void vHandlerTask( void *pvParameters );
static void vPeriodicTask( void *pvParameters );

/* The service routine for the interrupt.  This is the interrupt that the task
  will be synchronized with. */
static void vExampleInterruptHandler( void );

/*-----------------------------------------------------------*/

/* Declare a variable of type SemaphoreHandle_t.  This is used to reference the
  semaphore that is used to synchronize a task with an interrupt. */
SemaphoreHandle_t xBinarySemaphore;
/*
  // pin to generate interrupts
  #if defined(CORE_TEENSY)
  const uint8_t interruptPin = 0;
  #elfif defined(__AVR_ATmega32U4__)
  const uint8_t interruptPin = 3;
  #else  // interruptPin
  const uint8_t interruptPin = 2;
  #endif  // interruptPin
*/
#include <Sabertooth.h>
#include <PID_v1.h>
#define NO_NEWLINE false
volatile long count = 0;
volatile byte portCval, index, state, statep;
volatile int QEM[16] = {0, -1, 0, 1, 1, 0, -1, 0, 0, 1, 0, -1, -1, 0, 1, 0};
double kp = 0.68 , ki = 3.1  , kd = 0.0048 , input = 0, output = 0, setpoint = 0;  // velocity PID
double kp2 = 0.00000065 , ki2 = 0.00075  , kd2 = 0.0000055 , input2 = 0, output2 = 0, setpoint2 = 0;  // position PID
double kp3 = 0.000065, ki3=0.001, kd3=0.05;
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
float circum, velocity, target_velocity, target_position, distance;
int p = 0;
long previousMillis = 0;        // will store last time LED was updated
long interval = 500;           // interval at which to blink (milliseconds)
Sabertooth ST1(128, Serial1); // Address 128, and use Serial1 as the serial port.
PID PID_Veloctiy(&input, &output, &setpoint, kp, ki, kd, DIRECT);  // if motor will only run at full speed try 'REVERSE' instead of 'DIRECT'
PID PID_Position(&input2, &output2, &setpoint2, kp2, ki2, kd2, DIRECT);  // if motor will only run at full speed try 'REVERSE' instead of 'DIRECT'

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

  PID_Veloctiy.SetMode(AUTOMATIC);
  PID_Veloctiy.SetSampleTime(0.1);
  PID_Veloctiy.SetOutputLimits(0 , 127);

  PID_Position.SetMode(AUTOMATIC);
  PID_Position.SetSampleTime(0.01);
  PID_Position.SetOutputLimits(0 , 40);


  //FreeRTOS creation
  xTaskCreate( vPID_Velocity, "PID Velocity Control", 200, NULL, 1, NULL );
  xTaskCreate( vSpeedCalc, "Speed Calculation", 200, NULL, 2, NULL );
  xTaskCreate( vPID_Position, "PID Position Control", 200, NULL, 2, NULL );

  vTaskStartScheduler();

  //go to endless loop if fails
  for ( ;; );
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
    circum = 2 * PI * 18; //wheel diameter 18"
    distance = (ticks * circum) / 32768;
    velocity = distance / 0.01; //inches/second
    ticks_old = count;
    vTaskDelayUntil( &xLastWakeTime, ( 10 / portTICK_PERIOD_MS ) );
  }
}

static void vPID_Velocity( void *pvParameters )
{
  TickType_t xLastWakeTime;
  xLastWakeTime = xTaskGetTickCount();
  for ( ;; )
  {
    setpoint = target_velocity;
    if ((target_velocity - velocity_error_tolerance < velocity) && (velocity < target_velocity + velocity_error_tolerance))
    {
      velocity = target_velocity;
    }
    input = velocity;
    PID_Veloctiy.Compute();
    if (target_velocity == 0)
    {
      output=0;
    }
    ST1.motor(1, output);   
    vPrintStringAndFloat( " Veloctiy ", velocity, NO_NEWLINE);
    vPrintStringAndFloat( " Target_velocity ", target_velocity, NO_NEWLINE);
    vPrintStringAndFloat( " Ticks/second ", ticks, NO_NEWLINE);
    vPrintStringAndFloat( " Output ", output, NO_NEWLINE);
    vPrintStringAndFloat( " Position ", count);
    vTaskDelayUntil( &xLastWakeTime, ( 10 / portTICK_PERIOD_MS ) );
  }
}

static void vPID_Position( void *pvParameters )
{
  TickType_t xLastWakeTime;
  xLastWakeTime = xTaskGetTickCount();
  for ( ;; )
  {
    target_position = 680;
    setpoint2 = target_position;
    input2 = count;
    difference = abs(target_position - count);
    if (target_position > 5000)
    {
      if ( difference < 5000)
      {
        PID_Position.SetTunings(kp3, ki3, kd3);
      }
    }
    else
    {
      PID_Position.SetTunings(kp3, ki3, kd3);
    }


    PID_Position.Compute();

    target_velocity = output2;



    vTaskDelayUntil( &xLastWakeTime, ( 10 / portTICK_PERIOD_MS ) );
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







