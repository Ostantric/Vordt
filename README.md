# ESP32

Arduino development stopped. C++ development continues with ESP-IDF. 

### TODO

* ~~Implement UDP server~~

* ~~Implement FreeRTOS~~

* ~~Test sending fake values to Android app using arduino ide~~

* ~~Wire.h library is not good find a better one or write one~~

* ~~Implement Unique FPGA communication with UART~~

* ~~Adjust UART speed for future add-ons~~

* ~~Move to ESP-IDF~~

* ~~Smart Wifi Connect~~

* Second M-System Architecture


## Architecture 1
* FPGA, ESP32 and Sabertooth
### RTOS Tasks for Architecture 1
Higher the number the higher the priority

* Send_32bits_To_FPGA	- Priority = 6

* Send_16bits_To_FPGA	- Priority = 6

* UDP_Listen 		- Priority = 5

* UDP_Send 		- Priority = 4

* FPGA_Listen   	- Priority = 3

* IP_Broadcast  	- Priority = 2

## Architecture 2
* ESP32 and MCP263
### RTOS Tasks for Architecture 1
Higher the number the higher the priority


