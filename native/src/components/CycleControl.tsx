import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { getCurrentCycle, nextCycle, prevCycle } from '../services/api';
import { useCable } from '../hooks/useCable';

let _refetchCycle: (() => void) | null = null;

export function refreshCycleHeader() {
  _refetchCycle?.();
}

export default function CycleControl() {
  const [cycle, setCycle] = useState(1);
  const [loading, setLoading] = useState(true);
  const navigation = useNavigation();

  const fetchCycle = useCallback(() => {
    getCurrentCycle()
      .then(p => setCycle(p.current_cycle))
      .catch(() => {});
  }, []);

  useEffect(() => {
    _refetchCycle = fetchCycle;
    return () => {
      _refetchCycle = null;
    };
  }, [fetchCycle]);

  useCable<{ type: string; current_cycle: number }>('CycleChannel', {}, (data) => {
    if (data.type === 'cycle_update') {
      setCycle(data.current_cycle);
    }
  });

  useEffect(() => {
    setLoading(true);
    getCurrentCycle()
      .then(p => setCycle(p.current_cycle))
      .catch(() => {})
      .finally(() => setLoading(false));
    const unsubscribe = navigation.addListener('focus', fetchCycle);
    return unsubscribe;
  }, [navigation, fetchCycle]);

  const increment = useCallback(async () => {
    setLoading(true);
    try {
      const p = await nextCycle();
      setCycle(p.current_cycle);
    } finally {
      setLoading(false);
    }
  }, []);

  const decrement = useCallback(async () => {
    setLoading(true);
    try {
      const p = await prevCycle();
      setCycle(p.current_cycle);
    } finally {
      setLoading(false);
    }
  }, []);

  return (
    <View style={styles.container}>
      <TouchableOpacity
        style={styles.btn}
        onPress={decrement}
        disabled={loading}
        activeOpacity={0.6}
        hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
        <Text style={[styles.btnText, loading && styles.btnDisabled]}>◀</Text>
      </TouchableOpacity>

      <View style={styles.labelWrap}>
        {loading ? (
          <ActivityIndicator size="small" color="#c9a84c" />
        ) : (
          <Text style={styles.label}>Цикл {cycle}</Text>
        )}
      </View>

      <TouchableOpacity
        style={styles.btn}
        onPress={increment}
        disabled={loading}
        activeOpacity={0.6}
        hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
        <Text style={[styles.btnText, loading && styles.btnDisabled]}>▶</Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  btn: {
    width: 32,
    height: 32,
    borderRadius: 6,
    backgroundColor: '#2a2a42',
    justifyContent: 'center',
    alignItems: 'center',
  },
  btnText: {
    color: '#c9a84c',
    fontSize: 14,
  },
  btnDisabled: {
    opacity: 0.4,
  },
  labelWrap: {
    minWidth: 70,
    alignItems: 'center',
    justifyContent: 'center',
  },
  label: {
    color: '#e0d5c1',
    fontSize: 14,
    fontWeight: '600',
  },
});
