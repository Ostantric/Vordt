import React from 'react';
import { StackNavigator } from 'react-navigation';
import { StatusBar } from 'react-native';
import Home from './screens/Home';
import Controller from './screens/Controller';
StatusBar.setHidden(true);

const App = StackNavigator({
  Home: {
    screen: Home,
    navigationOptions: {
      gesturesEnabled: false,
    },
  },
  Controller: {
    screen: Controller,
    header: { visible: false },
    navigationOptions: {
      gesturesEnabled: false,
    },
  },
},{
  headerMode: 'none',
});

export default App;