import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  FlatList,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
  RefreshControl,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../navigation/types';
import {
  getCurrentCycleActions,
  markActionRead,
  ActionItem,
} from '../services/api';
import { refreshCycleHeader } from '../components/CycleControl';
import { useCable } from '../hooks/useCable';

type Props = NativeStackScreenProps<RootStackParamList, 'CompletedActions'>;

function sortActions(actions: ActionItem[]): ActionItem[] {
  const typeOrder: Record<string, number> = { prince: 0, noble: 1 };
  return actions.sort((a, b) => {
    const typeDiff =
      (typeOrder[a.action_type.action_type] ?? 1) -
      (typeOrder[b.action_type.action_type] ?? 1);
    if (typeDiff !== 0) return typeDiff;
    return (
      new Date(a.created_at).getTime() -
      new Date(b.created_at).getTime()
    );
  });
}

export default function CompletedActionsScreen({ route }: Props) {
  const { countryId, countryName } = route.params;
  const [actions, setActions] = useState<ActionItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [updatingId, setUpdatingId] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);

  const loadActions = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getCurrentCycleActions(countryId);
      setActions(sortActions([...data]));
    } catch (e: any) {
      setError(e.message || 'Ошибка загрузки');
    } finally {
      setLoading(false);
    }
  }, [countryId]);

  useEffect(() => {
    loadActions();
  }, [loadActions]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    try {
      setError(null);
      const data = await getCurrentCycleActions(countryId);
      setActions(sortActions([...data]));
      refreshCycleHeader();
    } catch (e: any) {
      setError(e.message || 'Ошибка загрузки');
    } finally {
      setRefreshing(false);
    }
  }, [countryId]);

  const handleMarkRead = async (action: ActionItem) => {
    if (action.read) {
      Alert.alert('Уже прочитано', 'Это действие уже было отмечено как прочитанное.');
      return;
    }

    try {
      setUpdatingId(action.id);
      await markActionRead(action.id);
      setActions(prev =>
        prev.map(a => (a.id === action.id ? { ...a, read: true } : a)),
      );
    } catch (e: any) {
      Alert.alert('Ошибка', e.message || 'Не удалось отметить как прочитанное');
    } finally {
      setUpdatingId(null);
    }
  };

  useCable<{ type: string; action: ActionItem }>('ActionsChannel', { country_id: countryId }, (data) => {
    if (data.type === 'action_created') {
      setActions(prev => {
        if (prev.some(a => a.id === data.action.id)) return prev;
        return sortActions([...prev, data.action]);
      });
    } else if (data.type === 'action_updated') {
      setActions(prev =>
        prev.map(a => (a.id === data.action.id ? data.action : a)),
      );
    }
  });

  const formatParams = (action: ActionItem): string => {
    const parts: string[] = [];

    if (action.action_type.display_params === 'C' && action.country) {
      parts.push(`Страна: ${action.country.name}`);
    } else if (
      (action.action_type.display_params === 'P' ||
        action.action_type.display_params === 'PF') &&
      action.province
    ) {
      parts.push(`Провинция: ${action.province.name}`);
    } else if (action.action_type.display_params === 'C2') {
      if (action.country) parts.push(`Страна: ${action.country.name}`);
      if (action.second_country)
        parts.push(`Вторая страна: ${action.second_country.name}`);
    }

    return parts.join('\n');
  };

  const renderAction = ({ item }: { item: ActionItem }) => {
    const isUpdating = updatingId === item.id;
    const isSuccess = item.result;

    return (
      <View
        style={[
          styles.card,
          item.read && styles.cardRead,
          item.action_type.action_type === 'prince' && styles.cardPrince,
        ]}>
        <View style={styles.cardHeader}>
          <Text style={styles.positionName} numberOfLines={1}>
            {item.position.name}
          </Text>
          <View
            style={[
              styles.readBadge,
              item.read ? styles.readBadgeDone : styles.readBadgePending,
            ]}>
            <Text style={styles.readBadgeText}>
              {item.read ? 'Прочитано' : 'Новое'}
            </Text>
          </View>
        </View>

        <Text
          style={[
            styles.typeLabel,
            item.action_type.action_type === 'noble'
              ? styles.typeLabelNoble
              : styles.typeLabelPrince,
          ]}>
          {item.action_type.action_type === 'noble'
            ? 'Приказ Государя'
            : 'Приказ Вельможи'}
        </Text>

        <View style={styles.actionRow}>
          <Text style={styles.actionName} numberOfLines={1}>
            {item.action_type.name}
          </Text>

          <TouchableOpacity
            style={[
              styles.readBtn,
              item.read && styles.readBtnDone,
              isUpdating && styles.readBtnDisabled,
            ]}
            onPress={() => handleMarkRead(item)}
            disabled={isUpdating}
            activeOpacity={0.7}>
            {isUpdating ? (
              <ActivityIndicator size="small" color="#c9a84c" />
            ) : (
              <Text
                style={[
                  styles.readBtnText,
                  item.read && styles.readBtnTextDone,
                ]}>
                {item.read ? '✓' : 'Отм. прочитанным'}
              </Text>
            )}
          </TouchableOpacity>
        </View>

        <View style={styles.resultRow}>
          <Text
            style={[
              styles.resultIcon,
              isSuccess ? styles.resultSuccess : styles.resultFailure,
            ]}>
            {isSuccess ? 'Успех' : 'Провал'}
          </Text>
          <Text style={styles.resultText}>
            {isSuccess
              ? item.action_type.success_result
              : item.action_type.failure_result}
          </Text>
        </View>

        {formatParams(item) ? (
          <Text style={styles.paramsText} numberOfLines={2}>
            {formatParams(item)}
          </Text>
        ) : null}
      </View>
    );
  };

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#c9a84c" />
        <Text style={styles.loadingText}>Загрузка действий...</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.center}>
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity style={styles.retryBtn} onPress={loadActions}>
          <Text style={styles.retryText}>Повторить</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.header}>{countryName} — совершённые действия</Text>

      <FlatList
        data={actions}
        keyExtractor={item => String(item.id)}
        renderItem={renderAction}
        contentContainerStyle={styles.list}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#c9a84c" />
        }
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyIcon}>📭</Text>
            <Text style={styles.emptyText}>
              В этом цикле ещё нет совершённых действий
            </Text>
          </View>
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
    paddingBottom: 32,
  },
  card: {
    backgroundColor: '#1e1e32',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#3a3a5a',
    padding: 12,
    marginBottom: 8,
  },
  cardRead: {
    opacity: 0.65,
    borderColor: '#2a2a42',
  },
  cardPrince: {
    borderColor: '#c9a84c',
    borderWidth: 2,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 2,
  },
  positionName: {
    color: '#c9a84c',
    fontSize: 17,
    fontWeight: '600',
    flex: 1,
    marginRight: 8,
  },
  readBadge: {
    borderRadius: 6,
    paddingHorizontal: 8,
    paddingVertical: 2,
  },
  readBadgePending: {
    backgroundColor: '#3a2a1a',
  },
  readBadgeDone: {
    backgroundColor: '#1a3a2a',
  },
  readBadgeText: {
    fontSize: 13,
    fontWeight: '700',
    color: '#e0d5c1',
  },
  actionName: {
    color: '#e0d5c1',
    fontSize: 18,
    fontWeight: '500',
    flex: 1,
    marginRight: 8,
  },
  actionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
  },
  typeLabel: {
    fontSize: 12,
    fontWeight: '700',
    textTransform: 'uppercase',
    letterSpacing: 1,
    marginBottom: 6,
    alignSelf: 'flex-start',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 4,
    overflow: 'hidden',
  },
  typeLabelPrince: {
    color: '#c9a84c',
    backgroundColor: '#2a2010',
  },
  typeLabelNoble: {
    color: '#8a8acc',
    backgroundColor: '#1a1a3a',
  },
  resultRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 4,
    gap: 6,
  },
  resultIcon: {
    fontSize: 13,
    fontWeight: '700',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    overflow: 'hidden',
  },
  resultSuccess: {
    color: '#8aca8a',
    backgroundColor: '#1a3a2a',
  },
  resultFailure: {
    color: '#e06c6c',
    backgroundColor: '#3a1a1a',
  },
  resultText: {
    color: '#b8b0a0',
    fontSize: 15,
    flex: 1,
  },
  paramsText: {
    color: '#a0a0c0',
    fontSize: 14,
    marginBottom: 6,
  },
  readBtn: {
    backgroundColor: '#2a3a2a',
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#4a8a4a',
    paddingVertical: 4,
    paddingHorizontal: 8,
  },
  readBtnDone: {
    backgroundColor: '#1a2a1a',
    borderColor: '#2a5a2a',
  },
  readBtnDisabled: {
    opacity: 0.6,
  },
  readBtnText: {
    color: '#8aca8a',
    fontSize: 13,
    fontWeight: '600',
  },
  readBtnTextDone: {
    color: '#4a7a4a',
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
  emptyContainer: {
    alignItems: 'center',
    marginTop: 64,
  },
  emptyIcon: {
    fontSize: 48,
    marginBottom: 16,
  },
  emptyText: {
    color: '#6a6a8a',
    fontSize: 18,
    textAlign: 'center',
  },
});
