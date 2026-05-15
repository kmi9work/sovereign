import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../navigation/types';
import { getPositionsWithActions, Position } from '../services/api';
import { refreshCycleHeader } from '../components/CycleControl';

type Props = NativeStackScreenProps<RootStackParamList, 'PositionSelect'>;

export default function PositionSelectScreen({ route, navigation }: Props) {
  const { countryId, countryName } = route.params;
  const [positions, setPositions] = useState<Position[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadPositions();
  }, []);

  const loadPositions = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getPositionsWithActions(countryId);
      setPositions(data);
    } catch (e: any) {
      setError(e.message || 'Ошибка загрузки');
    } finally {
      setLoading(false);
    }
  };

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    try {
      setError(null);
      const data = await getPositionsWithActions(countryId);
      setPositions(data);
      refreshCycleHeader();
    } catch (e: any) {
      setError(e.message || 'Ошибка загрузки');
    } finally {
      setRefreshing(false);
    }
  }, [countryId]);

  const handleSelect = (position: Position) => {
    navigation.navigate('ActionTypeList', {
      countryId,
      countryName,
      position,
    });
  };

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#c9a84c" />
        <Text style={styles.loadingText}>Загрузка должностей...</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.center}>
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity style={styles.retryBtn} onPress={loadPositions}>
          <Text style={styles.retryText}>Повторить</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const typeLabels: Record<string, string> = {
    prince: 'Приказы Вельможи',
    noble: 'Приказы Государя',
  };

  const renderPosition = ({ item }: { item: Position }) => {
    const counts = item.action_type_counts || {};

    return (
      <TouchableOpacity
        style={styles.positionCard}
        onPress={() => handleSelect(item)}
        activeOpacity={0.7}>
        <View style={styles.positionInfo}>
          <Text style={styles.positionName}>{item.name}</Text>
          <Text style={styles.actionCount}>
            {item.action_types?.length || 0} действий
          </Text>
        </View>
        {Object.keys(counts).length > 0 && (
          <View style={styles.countsRow}>
            {Object.entries(counts).map(([type, count]) => (
              <View key={type} style={styles.countBadge}>
                <Text style={styles.countBadgeText}>
                  {typeLabels[type] || type}: {count}
                </Text>
              </View>
            ))}
          </View>
        )}
      </TouchableOpacity>
    );
  };

  return (
    <View style={styles.container}>
      <Text style={styles.header}>
        {countryName} — выберите должность
      </Text>

      <FlatList
        data={positions}
        keyExtractor={item => String(item.id)}
        renderItem={renderPosition}
        contentContainerStyle={styles.list}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#c9a84c" />
        }
        ListEmptyComponent={
          <Text style={styles.empty}>Нет должностей</Text>
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
  center: {
    flex: 1,
    backgroundColor: '#12121e',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
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
  positionCard: {
    backgroundColor: '#1e1e32',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#3a3a5a',
    padding: 20,
    marginBottom: 12,
  },
  positionInfo: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  positionName: {
    color: '#e0d5c1',
    fontSize: 22,
    fontWeight: '600',
  },
  actionCount: {
    color: '#8a8aaa',
    fontSize: 16,
  },
  countsRow: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 10,
  },
  countBadge: {
    backgroundColor: '#2a2a3e',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#c9a84c',
    paddingVertical: 4,
    paddingHorizontal: 10,
  },
  countBadgeText: {
    color: '#c9a84c',
    fontSize: 13,
    fontWeight: '600',
  },
  loadingText: {
    color: '#8a8aaa',
    fontSize: 18,
    marginTop: 16,
  },
  errorText: {
    color: '#e06c6c',
    fontSize: 18,
    textAlign: 'center',
    marginBottom: 24,
  },
  retryBtn: {
    backgroundColor: '#c9a84c',
    borderRadius: 10,
    paddingHorizontal: 32,
    paddingVertical: 12,
  },
  retryText: {
    color: '#12121e',
    fontSize: 18,
    fontWeight: '600',
  },
  empty: {
    color: '#6a6a8a',
    fontSize: 18,
    textAlign: 'center',
    marginTop: 48,
  },
});
