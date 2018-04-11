#include <Sabertooth.h>
#include <PID_v1.h>
volatile long count = 0;
unsigned long timep, time , etime;
volatile byte portCval, index, state, statep;
volatile int QEM[16] = {0, -1, 0, 1, 1, 0, -1, 0, 0, 1, 0, -1, -1, 0, 1, 0};
double kp = 0.65 , ki = 3.1  , kd = 0.0085 , input = 0, output = 0, setpoint = 0;  // modify kp, ki and kd for optimal performance
long temp;
long ticks_old=0 ;
long ticks=0 ;
String readString;
long target = 0;
long target_org = 0;
long error = 0;
long difference = 0;
bool flag = false;
float circum, velocity,target_velocity, distance;

int p = 0;
long previousMillis = 0;        // will store last time LED was updated
long interval = 500;           // interval at which to blink (milliseconds)
Sabertooth ST1(128, Serial1); // Address 128, and use Serial1 as the serial port.
PID myPID(&input, &output, &setpoint, kp, ki, kd, DIRECT);  // if motor will only run at full speed try 'REVERSE' instead of 'DIRECT'
//PID p_PID(&input2, &output2, &setpoint2, kp, ki, kd, DIRECT);  // if motor will only run at full speed try 'REVERSE' instead of 'DIRECT'

/* ONE ISR(VECTOR) FOR EACH PORT !!
    Interrup service routine
*/
ISR (PCINT1_vect) //Interrupt vector 1 for portC
{
  //Although by default avr doesn't let you interrupt an interrupt, its a good practice to disable it anyways.
  cli(); //disable global interrupts
  statep = state; //save original state
  portCval = PINJ & 0b00000011; // masking analog pin 3 & 4
  if (portCval == 0b00000011) state = 0;
  if (portCval == 0b00000010) state = 1;
  if (portCval == 0b00000000) state = 2;
  if (portCval == 0b00000001) state = 3;
  index = 4 * state + statep;
  count = count + QEM[index];
  sei();//enable global interrupts
}
void setup() {
  Serial.begin(9600);
  Serial1.begin(9600);
  ST1.autobaud();
  DDRJ = 0x00; // all inputs
  PORTJ = 0x00;
  timep = micros(); //initial time
  portCval = PINJ & 0b00000011; // masking analog pin 3 & 4
  if (portCval == 0b00000011) state = 0;
  if (portCval == 0b00000010) state = 1;
  if (portCval == 0b00000000) state = 2;
  if (portCval == 0b00000001) state = 3;
  //pin change interrupt
  PCICR |= (1 << PCIE1); //set Interrupt Vector 1
  PCMSK1 |= (1 << PCINT9) | (1 << PCINT10); //mask analog pin 3 and 4
  myPID.SetMode(AUTOMATIC);
  myPID.SetSampleTime(0.1);
  myPID.SetOutputLimits(0 , 127);

}
void loop() {
  while (Serial.available()) {
    delay(2);  //delay to allow byte to arrive in input buffer
    char c = Serial.read();
    if (isDigit(c))
    {
      readString += c;
    }
  }
  if (readString.length() > 0) {
    Serial.print("target : ");
    target_velocity = readString.toInt();
    Serial.println(target);
    //flag = true;
    readString = "";
  }
  time = micros();
  etime = time - timep;
  if (etime > 100000) //0.1 sec
  {
    ticks=abs(count - ticks_old);
    circum = 2 * PI * 18; //wheel diameter 18"
    distance = (ticks*circum)/32768;
    velocity = distance/0.1;
    //Serial.println(velocity);
    timep = time;
    ticks_old=count;
  }
  setpoint=target_velocity;
  if ((target_velocity-0.5<velocity) && (velocity<target_velocity+0.5))
  {
  velocity=target_velocity;
  }
  input=velocity;
  myPID.Compute();

  Serial.print("Current velocity: ");
  Serial.print(ticks);
  Serial.print(" Taget velocity: ");
  Serial.print(target_velocity);
  Serial.print(" PWM signal: ");
  Serial.println(output);
  ST1.motor(1,15);
  //ST1.motor(1, output);

}

