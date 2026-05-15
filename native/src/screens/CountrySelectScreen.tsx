import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
  ActivityIndicator,
  RefreshControl,
} from 'react-native';
import { NativeStackScreenProps } from '@react-navigation/native-stack';
import { RootStackParamList } from '../navigation/types';
import { getCountriesWithPositions, Country } from '../services/api';
import { refreshCycleHeader } from '../components/CycleControl';

type Props = NativeStackScreenProps<RootStackParamList, 'CountrySelect'>;

export default function CountrySelectScreen({ navigation }: Props) {
  const [countries, setCountries] = useState<Country[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadCountries();
  }, []);

  const loadCountries = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getCountriesWithPositions();
      setCountries(data);
    } catch (e: any) {
      setError(e.message || 'Ошибка загрузки');
    } finally {
      setLoading(false);
    }
  };

  const handleSelect = (country: Country) => {
    navigation.navigate('MainMenu', {
      countryId: country.id,
      countryName: country.name,
    });
  };

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    try {
      setError(null);
      const data = await getCountriesWithPositions();
      setCountries(data);
      refreshCycleHeader();
    } catch (e: any) {
      setError(e.message || 'Ошибка загрузки');
    } finally {
      setRefreshing(false);
    }
  }, []);

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
        <TouchableOpacity style={styles.retryBtn} onPress={loadCountries}>
          <Text style={styles.retryText}>Повторить</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Выберите страну</Text>
      <ScrollView
        style={styles.list}
        contentContainerStyle={styles.listContent}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor="#c9a84c" />
        }>
        {countries.length === 0 ? (
          <Text style={styles.empty}>Нет доступных стран</Text>
        ) : (
          countries.map(item => (
            <TouchableOpacity
              key={item.id}
              style={styles.countryBtn}
              onPress={() => handleSelect(item)}
              activeOpacity={0.8}>
              <Text style={styles.countryBtnText}>{item.name}</Text>
            </TouchableOpacity>
          ))
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#12121e',
    alignItems: 'center',
    padding: 32,
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
    fontSize: 36,
    fontWeight: '700',
    marginBottom: 48,
    marginTop: 20,
    textAlign: 'center',
  },
  list: {
    flex: 1,
    alignSelf: 'center',
    width: '100%',
    maxWidth: 400,
  },
  listContent: {
    alignItems: 'center',
    paddingBottom: 32,
    gap: 24,
  },
  countryBtn: {
    backgroundColor: '#1e1e32',
    borderRadius: 16,
    borderWidth: 2,
    borderColor: '#c9a84c',
    paddingVertical: 32,
    paddingHorizontal: 48,
    alignItems: 'center',
    width: '100%',
  },
  countryBtnText: {
    color: '#e0d5c1',
    fontSize: 28,
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
