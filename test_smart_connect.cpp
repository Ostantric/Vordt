#include <iostream>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <unistd.h>
#include <ifaddrs.h>
#include "include/smartconnect.h"

using namespace std;
int main(void){
    SmartConnect *smarconnect = new SmartConnect();
    bool error = smarconnect->openSmartConnect();
    //cout<<error<<endl;
    if (!error){
        cout<<"error :"<<smarconnect->error<<endl;
    }else{
        
        //sleep(1);
       error = smarconnect->getSSID();
        if (!error){
            cout<<"error :"<<smarconnect->error<<endl;
            return -1;
        }else{
         cout<<"SSID: "<<smarconnect->SSID<<endl;
        }
        error = smarconnect->getPASS();
        if (!error){
            cout<<"error :"<<smarconnect->error<<endl;
            return -1;
        }else{
         cout<<"PASS: "<<smarconnect->PASS<<endl;
        }
    }
    smarconnect->closeSmartConnect();
}

