import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
  RefreshControl,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../navigation/types';
import {
  getActionTypeWithLists,
  getCountries,
  performAction,
  ActionTypeWithLists,
  Country,
} from '../services/api';
import { refreshCycleHeader } from '../components/CycleControl';
import DropdownPicker from '../components/DropdownPicker';

type Props = NativeStackScreenProps<RootStackParamList, 'ActionForm'>;

export default function ActionFormScreen({ route, navigation }: Props) {
  const { countryId, countryName, actionType } = route.params;

  const [data, setData] = useState<ActionTypeWithLists | null>(null);
  const [allCountries, setAllCountries] = useState<Country[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Selection state
  const [selectedCountry, setSelectedCountry] = useState<number | null>(null);
  const [selectedCountry2, setSelectedCountry2] = useState<number | null>(null);
  const [selectedProvince, setSelectedProvince] = useState<number | null>(null);

  const isPrince = actionType.action_type === 'prince';

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const [lists, countries] = await Promise.all([
        getActionTypeWithLists(actionType.id, countryId),
        getCountries(),
      ]);
      setData(lists);
      setAllCountries(countries);
    } catch (e: any) {
      setError(e.message || 'Ошибка загрузки');
    } finally {
      setLoading(false);
    }
  }, [actionType.id, countryId]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    try {
      setError(null);
      const [lists, countries] = await Promise.all([
        getActionTypeWithLists(actionType.id, countryId),
        getCountries(),
      ]);
      setData(lists);
      setAllCountries(countries);
      refreshCycleHeader();
    } catch (e: any) {
      setError(e.message || 'Ошибка загрузки');
    } finally {
      setRefreshing(false);
    }
  }, [actionType.id, countryId]);

  const validate = (): string | null => {
    switch (actionType.display_params) {
      case 'C':
        if (!selectedCountry) return 'не выбрана страна';
        break;
      case 'P':
        if (!selectedProvince) return 'не выбрана провинция';
        break;
      case 'PF':
        if (!selectedProvince) return 'не выбрана провинция';
        break;
      case 'C2':
        if (!selectedCountry) return 'не выбрана страна';
        if (!selectedCountry2) return 'не выбрана вторая страна';
        break;
    }
    return null;
  };

  const handleSubmit = async (result: boolean) => {
    const validationError = validate();

    if (validationError) {
      Alert.alert(
        'Не заполнено',
        `${validationError}. Точно отправить?`,
        [
          { text: 'Отмена', style: 'cancel' },
          { text: 'Отправить', onPress: () => doSubmit(result) },
        ],
      );
      return;
    }

    await doSubmit(result);
  };

  const doSubmit = async (result: boolean) => {
    try {
      setSubmitting(true);

      const params: any = {
        position_id: route.params.positionId,
        action_type_id: actionType.id,
        result,
      };

      switch (actionType.display_params) {
        case 'C':
          params.country_id = selectedCountry;
          break;
        case 'P':
        case 'PF':
          params.province_id = selectedProvince;
          break;
        case 'C2':
          params.country_id = selectedCountry;
          params.second_country_id = selectedCountry2;
          break;
      }

      await performAction(params);
      Alert.alert('Готово', 'Действие совершено!', [
        {
          text: 'OK',
          onPress: () => navigation.pop(2),
        },
      ]);
    } catch (e: any) {
      Alert.alert('Ошибка', e.message || 'Не удалось совершить действие');
    } finally {
      setSubmitting(false);
    }
  };

  if (loading) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color="#c9a84c" />
        <Text style={styles.loadingText}>Загрузка...</Text>
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.center}>
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity style={styles.retryBtn} onPress={loadData}>
          <Text style={styles.retryText}>Повторить</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const displayParams = actionType.display_params;

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={
        <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#c9a84c" />
      }>
      <Text style={styles.title}>{actionType.name}</Text>

      <View style={styles.resultSection}>
        <Text style={styles.resultLabel}>Результат при успехе:</Text>
        <Text style={styles.resultText}>{actionType.success_result}</Text>
      </View>

      <View style={styles.resultSection}>
        <Text style={styles.resultLabel}>Результат при неудаче:</Text>
        <Text style={styles.resultText}>{actionType.failure_result}</Text>
      </View>

      <View style={styles.formSection}>
        {displayParams === 'C' && data && (
          <View style={styles.fieldGroup}>
            <Text style={styles.fieldLabel}>Страна</Text>
            <DropdownPicker
              items={data.other_countries.map(c => ({
                id: c.id,
                name: c.name,
              }))}
              selectedId={selectedCountry}
              placeholder="Выберите страну..."
              onSelect={item => setSelectedCountry(item.id)}
            />
          </View>
        )}

        {displayParams === 'P' && data && (
          <View style={styles.fieldGroup}>
            <Text style={styles.fieldLabel}>Провинция</Text>
            <DropdownPicker
              items={data.provinces_of_country.map(p => ({
                id: p.id,
                name: p.name,
              }))}
              selectedId={selectedProvince}
              placeholder="Выберите провинцию..."
              onSelect={item => setSelectedProvince(item.id)}
            />
          </View>
        )}

        {displayParams === 'PF' && data && (
          <View style={styles.fieldGroup}>
            <Text style={styles.fieldLabel}>Провинция</Text>
            <DropdownPicker
              items={data.provinces_of_other.map(p => ({
                id: p.id,
                name: p.name,
                subtitle: p.country_name,
              }))}
              selectedId={selectedProvince}
              placeholder="Выберите провинцию..."
              onSelect={item => setSelectedProvince(item.id)}
            />
          </View>
        )}

        {displayParams === 'C2' && (
          <>
            <View style={styles.fieldGroup}>
              <Text style={styles.fieldLabel}>Страна</Text>
              <DropdownPicker
                items={allCountries.map(c => ({ id: c.id, name: c.name }))}
                selectedId={selectedCountry}
                placeholder="Выберите страну..."
                onSelect={item => setSelectedCountry(item.id)}
              />
            </View>

            <View style={styles.fieldGroup}>
              <Text style={styles.fieldLabel}>Вторая Страна</Text>
              <DropdownPicker
                items={allCountries.map(c => ({ id: c.id, name: c.name }))}
                selectedId={selectedCountry2}
                placeholder="Выберите вторую страну..."
                onSelect={item => setSelectedCountry2(item.id)}
              />
            </View>
          </>
        )}
      </View>

      {isPrince ? (
        <View style={styles.princeButtons}>
          <TouchableOpacity
            style={[styles.successBtn, submitting && styles.submitBtnDisabled]}
            onPress={() => handleSubmit(true)}
            disabled={submitting}
            activeOpacity={0.8}>
            {submitting ? (
              <ActivityIndicator size="small" color="#e0d5c1" />
            ) : (
              <Text style={styles.princeBtnText}>Успех</Text>
            )}
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.failureBtn, submitting && styles.submitBtnDisabled]}
            onPress={() => handleSubmit(false)}
            disabled={submitting}
            activeOpacity={0.8}>
            {submitting ? (
              <ActivityIndicator size="small" color="#e0d5c1" />
            ) : (
              <Text style={styles.princeBtnText}>Не успех</Text>
            )}
          </TouchableOpacity>
        </View>
      ) : (
        <TouchableOpacity
          style={[styles.submitBtn, submitting && styles.submitBtnDisabled]}
          onPress={() => handleSubmit(true)}
          disabled={submitting}
          activeOpacity={0.8}>
          {submitting ? (
            <ActivityIndicator size="small" color="#12121e" />
          ) : (
            <Text style={styles.submitBtnText}>Совершить действие</Text>
          )}
        </TouchableOpacity>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#12121e',
  },
  content: {
    padding: 20,
    paddingBottom: 48,
  },
  center: {
    flex: 1,
    backgroundColor: '#12121e',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
  },
  title: {
    color: '#c9a84c',
    fontSize: 28,
    fontWeight: '700',
    textAlign: 'center',
    marginBottom: 24,
    marginTop: 8,
  },
  resultSection: {
    backgroundColor: '#1e1e32',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#3a3a5a',
    padding: 16,
    marginBottom: 12,
  },
  resultLabel: {
    color: '#8a8aaa',
    fontSize: 16,
    marginBottom: 4,
  },
  resultText: {
    color: '#e0d5c1',
    fontSize: 18,
    lineHeight: 24,
  },
  formSection: {
    marginTop: 20,
    marginBottom: 32,
  },
  fieldGroup: {
    marginBottom: 8,
  },
  fieldLabel: {
    color: '#c9a84c',
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 8,
  },
  displayField: {
    backgroundColor: '#2a2a3e',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#4a4a6a',
    paddingHorizontal: 16,
    paddingVertical: 16,
    minHeight: 56,
    justifyContent: 'center',
  },
  displayFieldText: {
    color: '#e0d5c1',
    fontSize: 18,
  },
  princeButtons: {
    flexDirection: 'row',
    gap: 12,
  },
  successBtn: {
    flex: 1,
    backgroundColor: '#2a6a3a',
    borderRadius: 12,
    paddingVertical: 20,
    alignItems: 'center',
  },
  failureBtn: {
    flex: 1,
    backgroundColor: '#6a2a2a',
    borderRadius: 12,
    paddingVertical: 20,
    alignItems: 'center',
  },
  submitBtn: {
    backgroundColor: '#c9a84c',
    borderRadius: 12,
    paddingVertical: 20,
    alignItems: 'center',
  },
  submitBtnDisabled: {
    opacity: 0.6,
  },
  submitBtnText: {
    color: '#12121e',
    fontSize: 22,
    fontWeight: '700',
  },
  princeBtnText: {
    color: '#e0d5c1',
    fontSize: 22,
    fontWeight: '700',
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
});
