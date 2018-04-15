/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  Platform,
  StyleSheet,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  Dimensions,
  Keyboard,
} from 'react-native';



class Home extends Component{

  constructor(props){
    super(props);
    this.state = {
      message: 'Bekliyor...',
      port: 50001,
      ip: '192.168.1.100',
    }
  }
  

  render() {
    return (
      <View style={styles.container}>
        <View>
          <TextInput
          style={styles.input} 
          placeholder="IP"
          placeholderTextColor='#3d3d3d'
          value={this.state.ip} 
          onChangeText={(text)=> this.setState({ip: text})}
          />
          <TextInput
            style={styles.input}  
            placeholder="PORT"
            placeholderTextColor='#3d3d3d'
            value={''+this.state.port} 
            onChangeText={(text)=> this.setState({port: text})}
          />
        </View>
        <TouchableOpacity
        style={styles.startButton}
        onPress={()=>{
            Keyboard.dismiss();
            this.props.navigation.navigate('Controller',{ ip: this.state.ip, port: this.state.port});
        }} 
        >
        <Text style={styles.startButtonText}>Start</Text>
        </TouchableOpacity>
      </View>
    );
  }
}
const window = Dimensions.get('window');
const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'space-around',
    alignItems: 'center',
    backgroundColor: '#3d3d3d',
  },
  startButton: {
    width: window.width - 100,
    height: 75,
    backgroundColor: '#ff9f1a',
    justifyContent: 'center',
    alignItems: 'center',
    borderRadius: 5,
  },
  startButtonText: {
    fontSize: 20,
    color: '#fff'
  },
  input: {
    width: window.width - 100,
    textAlign: 'center',
    borderWidth: 1,
    borderColor: '#f7f1e3',
    borderRadius: 5,
    height: 50,
    margin: 10,
    color: '#3d3d3d',
    fontSize: 20,
    backgroundColor:'#f7f1e3' 
  },
});

export default Home;