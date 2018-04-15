import React, { Component } from 'react';
import { Text, StyleSheet, View, Slider, Dimensions, BackHandler, Button, Platform } from 'react-native';
import  dgram from 'react-native-udp';
import Toast, {DURATION} from 'react-native-easy-toast'
import * as Progress from 'react-native-progress';

const toByteArray = (obj) => {
  var uint = new Uint8Array(obj.length);
  for (var i = 0, l = obj.length; i < l; i++){
    uint[i] = obj.charCodeAt(i);
  }

  return new Uint8Array(uint);
}
const bin2String = (array) => {
  return String.fromCharCode.apply(String, array);
}

const randomPort = () => {
    return Math.random() * 60536 | 0 + 5000 // 60536-65536
}
class Controller extends Component {
    constructor(props){
        super(props);
        this.state = {
            message: '',
            dataTime: 0,
            position: 0,
            turn: 0,
            position: 0,
            velocity: 0,
            voltage: 'Waiting',
            windowWidth: Dimensions.get('window').width,
            socket: dgram.createSocket('udp4'),
        }
        this.sendData = this.sendData.bind(this);
        this.disconnectButton = this.disconnectButton.bind(this);
    }

    componentWillMount(){
        const { socket } = this.state;
        let port = randomPort();
        socket.bind(port);
        socket.once('listening', (err) => {
            socket.setBroadcast(true);
            socket.addMembership("192.168.1.100")
        });
        const data = toByteArray("1");
        socket.send(data, 0, data.length, parseInt(this.props.navigation.state.params.port), this.props.navigation.state.params.ip, (err) => {
            if (err) throw err
            console.log(socket.address());
        });
        socket.on('message', (data, rinfo) => {
            if(data){
                if (this.state.dataTime === 0){
                    this.refs.toast.show('Connection Succesfull');
                }
                const jsonData = JSON.parse(String.fromCharCode.apply(null, new Uint8Array(data)));
                if(jsonData.Type==='Utility'){
                    this.setState({ voltage: jsonData.Voltage, dataTime: Date.now()});
                } else {
                    console.log(jsonData);
                    this.setState({ position: jsonData.Position, turn: jsonData.Turn, velocity: jsonData.Velocity+500, dataTime: Date.now()});
                }  
            }
        });
        const checkConnectionInverval = setInterval(checkConnection = () =>{
            this.setState({ checkConnectionInverval: checkConnectionInverval })
            const distance  = Date.now() - this.state.dataTime; 
            console.log(distance);
            if(distance > 5000 && this.state.dataTime!==0){
                this.refs.toast.show('Connection Lost!');
                this.setState({ dataTime: 0})
            } 
        },500);
        BackHandler.addEventListener('hardwareBackPress', () => {
            if(Platform.OS === 'android'){
                clearInterval(this.state.checkConnectionInverval);
                socket.close(() => {
                    this.refs.toast.show('Disconnected!');
                    setTimeout(this.props.navigation.goBack,500);
                })
            }
        });  
    }
    sendData(){
        const { socket } = this.state;
        const { positionToOrigin, turn, velocity } = this.state;
        const jsonData = JSON.stringify({
            "Position": positionToOrigin,
            "Turn": turn,
            "Velocity": velocity
        });
        const data = toByteArray(jsonData);
        socket.send(data, 0, data.length, parseInt(this.props.navigation.state.params.port), this.props.navigation.state.params.ip, (err) => {
            if (err) throw err
            console.log(socket.address());
        });
    }
    disconnectButton(){
        if(Platform.OS === 'ios'){
            const { socket } = this.state;
            return(
                <View style={{ marginTop: 20}}>
                    <Button
                        title="Disconnect"
                        color='red'
                        onPress={() => {
                            socket.close(() => {
                                clearInterval(this.state.checkConnectionInverval);
                                this.refs.toast.show('Disconnected!');
                                setTimeout(this.props.navigation.goBack,500);
                            })
                        }}
                    />
                </View>
            )
        }
        return null;
    }
    render(){
        return(
            <View style={styles.container}>
                <View style={{ flex: 2, justifyContent: 'center', alignItems: 'center'}}>
                    <View style={{ height: 200, justifyContent: 'space-around', alignItems: 'center'}}>
                        <Progress.Pie progress={this.state.position/36000} size={100} color="#ff9f1a"/>
                        <View style={{ flexDirection: 'row'}}>
                            <Text style={{ color: '#fff' }}>Desired Position: </Text>
                            <Text style={{ color: '#ff9f1a' }}>{this.state.position}</Text>
                        </View>
                        <View style={{ flexDirection: 'row'}}>
                            <Text style={{ color: '#fff' }}>Desired Turn: </Text>
                            <Text style={{ color: '#ff9f1a' }}>{this.state.turn}</Text>
                        </View>
                    </View>
                    <View style={{ flexDirection: 'column', width: 300}}>
                        <Text style={{ color: '#fff' }}>Desired Position</Text>
                        <Slider onValueChange={(value)=>{
                            this.setState({ positionToOrigin: (value*36000).toFixed()},()=>{
                                this.sendData();
                            })
                        }}
                        />
                    </View>
                    <View style={{ flexDirection: 'column', width: 300, height: 50}}>
                        <Text style={{ color: '#fff' }}>Desired Turn</Text>
                        <Slider onValueChange={(value)=>{
                            this.setState({ turn: (value*500).toFixed()},()=>{
                                this.sendData();
                            })
                        }}
                        />
                    </View>
                </View>
                <View style={{ flex: 2, justifyContent: 'center', alignItems: 'center'}}>
                    <Progress.Bar progress={this.state.velocity/1000} width={300} height={20} color={this.state.velocity>=500?'green':'red'} style={{marginBottom: 20,}} />
                    <View style={{ flexDirection: 'column', width: 300, flexDirection:'row', justifyContent: 'center', marginBottom: 20}}>
                        <Text style={{ color: '#fff' }}>Velocity: </Text>
                        <Text style={{ color: '#ff9f1a' }}>{this.state.velocity-500}</Text>
                    </View>
                    <View style={{ flexDirection: 'column', width: 300, marginBottom: 20}}>
                        <Text style={{ color: '#fff' }}>Desired Velocity</Text>
                        <Slider onValueChange={(value)=>{
                            this.setState({ velocity: (value*1000).toFixed()},() => {
                                this.sendData();
                            })
                        }}
                        />
                    </View>
                    <View style={{ flexDirection: 'column', width: 300, flexDirection:'row', justifyContent: 'center'}}>
                        <Text style={{ color: '#fff' }}>Voltage: </Text>
                        <Text style={{ color: '#ff9f1a' }}>{this.state.voltage}</Text>
                    </View>
                    {this.disconnectButton()}
                </View>
                <Toast ref="toast"/>
            </View>
        )
    }
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        justifyContent: 'space-around',
        alignItems: 'center',
        backgroundColor: '#3d3d3d',
        flexDirection: 'row'
    },
})
export default Controller;