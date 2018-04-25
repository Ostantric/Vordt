# ESP32

### TODO

* ~~Implement UDP server~~

* ~~Implement FreeRTOS~~

* ~~Test sending fake values to Android app using arduino ide~~

* ~~Wire.h library is not good find a better one or write one~~

* ~~Implement Unique FPGA communication with UART~~

* ~~Adjust UART speed for future add-ons~~

* Move to ESP-IDF

### RTOS Tasks Architecture

* Utility_UDP_send - Priority = 1

* FPGA_Listen - Priority = 2

* Position_UDP_Send - Priority = 3

* Velocity_UDP_Send - Priority = 3

* Turn_UDP_Send - Priority = 3

* UDP_Listen - Priority = 4

* IncomingJsonParser - Priority = 5

* Send_Position_To_FPGA - Priority = 6

* Send_Turn_To_FPGA - Priority = 6

* Send_MaxVel_To_FPGA - Priority = 6

