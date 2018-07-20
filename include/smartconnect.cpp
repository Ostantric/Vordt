#include "smartconnect.h"
SmartConnect::SmartConnect()
{
    I2CBUS=0;
    error=0;
}
SmartConnect::~SmartConnect()
{
    closeSmartConnect();
}

bool SmartConnect::openSmartConnect()
{
    char buffer[64];
    sprintf(buffer,"/dev/i2c-%d", I2CBUS);
    i2cfd = open(buffer, O_RDWR);
    if(i2cfd<0){
        error = errno;
        return false;
    }
    if(ioctl(i2cfd, I2C_SLAVE,esp32address)<0){
        error =errno;
        return false;
    }
    
    return true;
}

void SmartConnect::closeSmartConnect()
{
    if(i2cfd>0){
        close(i2cfd);
    }
}
//Get password
bool SmartConnect::getPASS()
{
    int result;
    result = i2c_smbus_read_i2c_block_data(i2cfd,PASSWORD_REGISTER,64,(u_int8_t *)PASS);
    char buffer[64];
    buffer[0]=2;
    //write(i2cfd, buffer, 1);
	//read(i2cfd, buffer, 30);
    //std::cout<<buffer<<std::endl;
    if(result<0){
        error = errno;
        result = -1;
        //std::cout<<"result: "<<result<<std::endl;
        return false;
    }
    return true;
}
//Get SSID
bool SmartConnect::getSSID()
{
    int result;
    result = i2c_smbus_read_i2c_block_data(i2cfd,SSID_REGISTER,32,(u_int8_t *)SSID);
    char buffer[64] = { 0 };
    //7bit address , 1 bit READ = HIGH bit
	buffer[0]=1;
    buffer[1]=2;
    buffer[2]=3;
    buffer[3]=4;
    //write(i2cfd, buffer, 1);
	//read(i2cfd, buffer, 32);
    //write(i2cfd,buffer,1);
    //std::cout<<buffer<<std::endl;
    if(result<0){
        error = errno;
        result = -1;
        //std::cout<<"result: "<<result<<std::endl;
        return false;
    }
    return true;
}



