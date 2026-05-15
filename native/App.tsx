import React from 'react';
import { StatusBar } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';

import CountrySelectScreen from './src/screens/CountrySelectScreen';
import MainMenuScreen from './src/screens/MainMenuScreen';
import PositionSelectScreen from './src/screens/PositionSelectScreen';
import ActionTypeListScreen from './src/screens/ActionTypeListScreen';
import ActionFormScreen from './src/screens/ActionFormScreen';
import CompletedActionsScreen from './src/screens/CompletedActionsScreen';
import { RootStackParamList } from './src/navigation/types';
import CycleControl from './src/components/CycleControl';

const Stack = createNativeStackNavigator<RootStackParamList>();

export default function App() {
  return (
    <NavigationContainer>
      <StatusBar barStyle="light-content" backgroundColor="#12121e" />
      <Stack.Navigator
        initialRouteName="CountrySelect"
        screenOptions={{
          headerStyle: { backgroundColor: '#1a1a2e' },
          headerTintColor: '#c9a84c',
          headerTitleStyle: { fontWeight: '700', fontSize: 18 },
          contentStyle: { backgroundColor: '#12121e' },
          headerRight: () => <CycleControl />,
        }}>
        <Stack.Screen
          name="CountrySelect"
          component={CountrySelectScreen}
          options={{ title: 'Сюзерен', headerShown: false }}
        />
        <Stack.Screen
          name="MainMenu"
          component={MainMenuScreen}
          options={{ title: 'Главное меню' }}
        />
        <Stack.Screen
          name="PositionSelect"
          component={PositionSelectScreen}
          options={{ title: 'Выбор должности' }}
        />
        <Stack.Screen
          name="ActionTypeList"
          component={ActionTypeListScreen}
          options={{ title: 'Действия' }}
        />
        <Stack.Screen
          name="ActionForm"
          component={ActionFormScreen}
          options={{ title: 'Совершить действие' }}
        />
        <Stack.Screen
          name="CompletedActions"
          component={CompletedActionsScreen}
          options={{ title: 'Совершённые действия' }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
