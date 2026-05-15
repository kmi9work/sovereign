import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  RefreshControl,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../navigation/types';
import { refreshCycleHeader } from '../components/CycleControl';

type Props = NativeStackScreenProps<RootStackParamList, 'MainMenu'>;

export default function MainMenuScreen({ route, navigation }: Props) {
  const { countryId, countryName } = route.params;
  const [refreshing, setRefreshing] = useState(false);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await new Promise<void>(resolve => setTimeout(resolve, 500));
    refreshCycleHeader();
    setRefreshing(false);
  }, []);

  return (
    <ScrollView
      style={styles.scroll}
      contentContainerStyle={styles.container}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#c9a84c" />
      }>
      <Text style={styles.title}>{countryName}</Text>
      <Text style={styles.subtitle}>Выберите действие</Text>

      <View style={styles.buttons}>
        <TouchableOpacity
          style={styles.actionBtn}
          onPress={() =>
            navigation.navigate('PositionSelect', { countryId, countryName })
          }
          activeOpacity={0.8}>
          <Text style={styles.actionBtnIcon}>⚔️</Text>
          <Text style={styles.actionBtnText}>Совершить действие</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.viewBtn}
          onPress={() =>
            navigation.navigate('CompletedActions', { countryId, countryName })
          }
          activeOpacity={0.8}>
          <Text style={styles.viewBtnIcon}>📜</Text>
          <Text style={styles.viewBtnText}>Посмотреть совершённые действия</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  scroll: {
    flex: 1,
    backgroundColor: '#12121e',
  },
  container: {
    flexGrow: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
  },
  title: {
    color: '#c9a84c',
    fontSize: 36,
    fontWeight: '700',
    marginBottom: 8,
    textAlign: 'center',
  },
  subtitle: {
    color: '#8a8aaa',
    fontSize: 20,
    marginBottom: 48,
  },
  buttons: {
    width: '100%',
    maxWidth: 500,
    gap: 24,
  },
  actionBtn: {
    backgroundColor: '#1e3a2a',
    borderRadius: 16,
    borderWidth: 2,
    borderColor: '#4a9a6a',
    paddingVertical: 32,
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 12,
  },
  actionBtnIcon: {
    fontSize: 28,
  },
  actionBtnText: {
    color: '#e0d5c1',
    fontSize: 22,
    fontWeight: '600',
  },
  viewBtn: {
    backgroundColor: '#2a1e2a',
    borderRadius: 16,
    borderWidth: 2,
    borderColor: '#8a4a8a',
    paddingVertical: 32,
    alignItems: 'center',
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 12,
  },
  viewBtnIcon: {
    fontSize: 28,
  },
  viewBtnText: {
    color: '#e0d5c1',
    fontSize: 22,
    fontWeight: '600',
  },
});
