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
#include "json/ArduinoJson.h"
#include "ros/ros.h"
#include "std_msgs/String.h"

#define BUFLEN 2048
#define PORT 1700

using namespace std;
int main(int argc, char **argv){
    struct sockaddr_in local_addr, send_addr;
    struct sockaddr_in *roscore_ip;
    int sock, opt,send_len=sizeof(send_addr);
    int broadcast_opt_enable = 1;
    struct ifaddrs *networkadapters, *local_adapter;
    char *broadcast_ip = "255.255.255.255";
    char sendbuf[BUFLEN];
    char *roscore_ip_char;
    char *adapter_name;
    
    std_msgs::String msg;
    stringstream ss,master_ip;
    
    StaticJsonBuffer<128> JSONbuffer;
    JsonObject& JSONencoder = JSONbuffer.createObject();

    if (getifaddrs(&networkadapters) == -1) {
               perror("getifaddrs");
               exit(EXIT_FAILURE);
           }
    if((sock=socket(AF_INET, SOCK_DGRAM, 0))<0){
        perror("socket error");
        return 0;
    }
    opt = setsockopt(sock,SOL_SOCKET, SO_BROADCAST,&broadcast_opt_enable, sizeof(broadcast_opt_enable));
    local_addr.sin_family = AF_INET;
    local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    local_addr.sin_port = htonl(0);
    if(bind(sock,(struct sockaddr *) &local_addr, sizeof(local_addr))<0){
        perror("bind error");
        return 0;
    }
    send_addr.sin_port=htons(PORT);
    send_addr.sin_family=AF_INET;
    inet_aton(broadcast_ip, &send_addr.sin_addr);
    for(local_adapter = networkadapters; local_adapter; local_adapter = local_adapter->ifa_next){
        if(local_adapter->ifa_addr->sa_family==AF_INET){
            roscore_ip = (struct sockaddr_in *) local_adapter->ifa_addr;
            adapter_name=local_adapter->ifa_name;
            if(strcmp(adapter_name,"lo")){
                roscore_ip_char = inet_ntoa(roscore_ip->sin_addr);
                //cout<<roscore_ip_char<<endl;
                break;
            }
        }
    }
    master_ip<<"http://"<<roscore_ip_char<<":11311";
    //cout<<master_ip.str()<<endl;
    vector<pair<string,string>> mapping;
    mapping = { 
        {"__master",master_ip.str()},{"__ip",roscore_ip_char}
    };
    ros::init(mapping,"broadcast");
    ros::NodeHandle broadcast_handle;
    ros::Publisher broad_pub = broadcast_handle.advertise<std_msgs::String>("roscore_ip_broadcast",1);
    ros::Rate loop_rate(1);
    string parameter;
    freeifaddrs(networkadapters);
    ss<<"Broadcasting at "<<broadcast_ip<< "port "<< PORT;
    JSONencoder ["ID"] = "Roscore";
    JSONencoder ["IP"] = roscore_ip_char;
    JSONencoder ["PORT"] = "11311";
    JSONencoder.printTo(sendbuf,sizeof(sendbuf));
    while(ros::ok()){
        if(sendto(sock,sendbuf,strlen(sendbuf),0,(struct sockaddr *)&send_addr,send_len)<0){
            perror("sendto error");
            exit(1);
        }
        //ROS_INFO("%s",roscore_ip_char);
        msg.data = ss.str();
        broad_pub.publish(msg);
        ros::spinOnce();
        loop_rate.sleep();
    }
    return 0;
}
