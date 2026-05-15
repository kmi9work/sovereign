import React, { useState, useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  RefreshControl,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../navigation/types';
import { ActionType } from '../services/api';
import { refreshCycleHeader } from '../components/CycleControl';

type Props = NativeStackScreenProps<RootStackParamList, 'ActionTypeList'>;

export default function ActionTypeListScreen({ route, navigation }: Props) {
  const { countryId, countryName, position } = route.params;
  const [refreshing, setRefreshing] = useState(false);

  const actionTypes = (position.action_types || []).sort((a, b) => {
    if (a.action_type !== b.action_type) {
      return a.action_type === 'prince' ? -1 : 1;
    }
    return a.name.localeCompare(b.name);
  });

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await new Promise<void>(resolve => setTimeout(resolve, 300));
    refreshCycleHeader();
    setRefreshing(false);
  }, []);

  const handleSelect = (actionType: ActionType) => {
    navigation.navigate('ActionForm', {
      countryId,
      countryName,
      actionType,
      positionId: position.id,
    });
  };

  const renderActionType = ({ item }: { item: ActionType }) => (
    <TouchableOpacity
      style={[
        styles.card,
        item.action_type === 'prince' && styles.cardPrince,
      ]}
      onPress={() => handleSelect(item)}
      activeOpacity={0.7}>
      <Text
        style={[
          styles.actionTypeLabel,
          item.action_type === 'noble'
            ? styles.actionTypeNoble
            : styles.actionTypePrince,
        ]}>
        {item.action_type === 'noble'
          ? 'Приказ Государя'
          : 'Приказ Вельможи'}
      </Text>
      <Text style={styles.cardTitle}>{item.name}</Text>
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <Text style={styles.header}>
        {position.name} — действия
      </Text>

      <FlatList
        data={actionTypes}
        keyExtractor={item => String(item.id)}
        renderItem={renderActionType}
        contentContainerStyle={styles.list}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#c9a84c" />
        }
        ListEmptyComponent={
          <Text style={styles.empty}>Нет действий для этой должности</Text>
        }
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#12121e',
    padding: 16,
  },
  header: {
    color: '#c9a84c',
    fontSize: 24,
    fontWeight: '700',
    textAlign: 'center',
    marginBottom: 20,
    marginTop: 12,
  },
  list: {
    paddingBottom: 24,
  },
  card: {
    backgroundColor: '#1e1e32',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#3a3a5a',
    padding: 20,
    marginBottom: 12,
  },
  actionTypeLabel: {
    fontSize: 11,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: 8,
    alignSelf: 'flex-start',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 4,
    overflow: 'hidden',
  },
  actionTypePrince: {
    color: '#c9a84c',
    backgroundColor: '#2a2010',
  },
  actionTypeNoble: {
    color: '#8a8acc',
    backgroundColor: '#1a1a3a',
  },
  cardPrince: {
    borderColor: '#c9a84c',
    borderWidth: 2,
  },
  cardTitle: {
    color: '#e0d5c1',
    fontSize: 20,
    fontWeight: '600',
    marginBottom: 4,
  },
  cardType: {
    color: '#8a8aaa',
    fontSize: 16,
  },
  empty: {
    color: '#6a6a8a',
    fontSize: 18,
    textAlign: 'center',
    marginTop: 48,
  },
});
