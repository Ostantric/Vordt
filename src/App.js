import React from 'react';
import { StackNavigator } from 'react-navigation';
import Home from './screens/Home';
import Controller from './screens/Controller';

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