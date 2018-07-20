#ifndef smartconnecti2c_h
#define smartconnecti2c_h
/*              
    I2C PROTOCOL
    SCL -> clock line 400khz
    SDA -> data line  (0x0A)(8.bit = W/R)-(0x0R)-(8byte*32)=SSID,(8byte*64)=PASSWORD
*/
#include <iostream>
#include <stdio.h>
#include <cstdio>
#include <cstdlib>
#include <cstddef>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <stdlib.h>
#include <string.h>
#include <linux/i2c-dev.h>

#define esp32address 0x0A  
#define SSID_REGISTER 0x01
#define PASSWORD_REGISTER 0x02
class  SmartConnect
{
public:
    int I2CBUS; //i2c bus of the smartconnect
    int i2cfd; //file descriptor
    int error;
    char SSID[32];
    char PASS[64];
    SmartConnect();
    ~SmartConnect();
    bool openSmartConnect();
    void closeSmartConnect();
    bool getSSID();
    bool getPASS();
};

#endif