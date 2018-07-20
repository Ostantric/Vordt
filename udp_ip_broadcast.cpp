/* Jetson TX1 - UDP socket Ip Broadcast */
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
#include "include/ArduinoJson.h" //lightweight
#include "include/smartconnect.h"

#define BUFLEN 1024 //send buffer length
#define PORT 1200 //broadcasting port

using namespace std;

int main(void){
    struct sockaddr_in local_addr, send_addr; //internet IPv4 socket address
    struct sockaddr_in *wifi_ip;
    int sock,option,len = sizeof(send_addr); //socket and addr length
    struct ifaddrs *all_adapters, *wifi_adapter; //network interface structure
    int broadcast_enable = 1;
    char *ff_ip="255.255.255.255"; //FFs for broadcasting
    char sendbuf[BUFLEN]; //send buffer
    char *jetson_ip;
    StaticJsonBuffer<128> JSONbuffer; //Json buffer for broadcasting
    //create socket
    if((sock=socket(AF_INET, SOCK_DGRAM, 0))== -1){
        perror("socket error");
        exit(EXIT_FAILURE);
    }   
    //set broadcasting option and enable it
    if(option = setsockopt(sock,SOL_SOCKET, SO_BROADCAST, &broadcast_enable, sizeof(broadcast_enable)) == -1 ){
        perror("setsockopt");
        exit(EXIT_FAILURE);
    }
    //incoming init
    local_addr.sin_family = AF_INET;
    local_addr.sin_addr.s_addr=htonl(INADDR_ANY);
    local_addr.sin_port = htonl(0);
    //bind socket and address
    if(bind(sock,(struct sockaddr *) &local_addr, sizeof(local_addr))== -1){
        perror("bind");
        exit(EXIT_FAILURE);
    }
    //send address init
    send_addr.sin_port=htons(PORT);
    send_addr.sin_family=AF_INET;
    inet_aton(ff_ip, &send_addr.sin_addr);
    while(1){
        JsonObject& JSONencoder = JSONbuffer.createObject(); //Json object
        //fill all_adapters with existing network interfaces
        if (getifaddrs(&all_adapters) == -1){ 
            perror("getifaddrs");
            exit(EXIT_FAILURE);
        }
        //find wifi adapter and get network ip
        for(wifi_adapter = all_adapters; wifi_adapter; wifi_adapter = wifi_adapter->ifa_next){
            if(wifi_adapter->ifa_addr->sa_family==AF_INET){ //check for ipv4 address family
                if(strcmp(wifi_adapter->ifa_name,"wlan0")==0){ //check for "wlan0"
                    wifi_ip = (struct sockaddr_in *) wifi_adapter->ifa_addr; // get network ip
                    jetson_ip = inet_ntoa(wifi_ip->sin_addr); //put into char
                }
            }
        }
        JSONencoder ["ID"] = "Jetson_TX1"; //machine name
        JSONencoder ["IP"] = jetson_ip; //network ip
        JSONencoder.printTo(sendbuf,sizeof(sendbuf)); //put json object in sendbuf
        //send to FF
        if((sendto(sock,sendbuf,strlen(sendbuf),0,(struct sockaddr *) &send_addr,len))==-1){
            perror("sendto error");
            exit(EXIT_FAILURE);
        }
        sleep(5);
        JSONbuffer.clear(); //clear Json buffer
        freeifaddrs(all_adapters); //Reclaim the storage allocated by a previous `getifaddrs' call.
    }
}
