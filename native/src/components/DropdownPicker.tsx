import React, { useState } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Modal,
  FlatList,
  StyleSheet,
  Dimensions,
} from 'react-native';

interface DropdownItem {
  id: number;
  name: string;
  subtitle?: string;
}

interface DropdownPickerProps {
  items: DropdownItem[];
  selectedId: number | null;
  placeholder: string;
  onSelect: (item: DropdownItem) => void;
}

const { height: SCREEN_HEIGHT } = Dimensions.get('window');

export default function DropdownPicker({
  items,
  selectedId,
  placeholder,
  onSelect,
}: DropdownPickerProps) {
  const [visible, setVisible] = useState(false);

  const selected = items.find(i => i.id === selectedId);

  const handleSelect = (item: DropdownItem) => {
    onSelect(item);
    setVisible(false);
  };

  const renderItem = ({ item }: { item: DropdownItem }) => (
    <TouchableOpacity
      style={[
        styles.item,
        item.id === selectedId && styles.itemSelected,
      ]}
      onPress={() => handleSelect(item)}>
      <Text style={styles.itemText}>{item.name}</Text>
      {item.subtitle && (
        <Text style={styles.itemSubtext}>{item.subtitle}</Text>
      )}
    </TouchableOpacity>
  );

  return (
    <View style={styles.container}>
      <TouchableOpacity
        style={styles.trigger}
        onPress={() => setVisible(true)}
        activeOpacity={0.7}>
        <Text style={[styles.triggerText, !selected && styles.placeholder]}>
          {selected ? selected.name : placeholder}
        </Text>
        <Text style={styles.arrow}>{'▼'}</Text>
      </TouchableOpacity>

      <Modal
        visible={visible}
        transparent
        animationType="fade"
        onRequestClose={() => setVisible(false)}>
        <TouchableOpacity
          style={styles.overlay}
          activeOpacity={1}
          onPress={() => setVisible(false)}>
          <View style={styles.modal}>
            <Text style={styles.modalTitle}>{placeholder}</Text>
            <FlatList
              data={items}
              keyExtractor={item => String(item.id)}
              renderItem={renderItem}
              style={styles.list}
              ListEmptyComponent={
                <Text style={styles.empty}>Нет данных</Text>
              }
            />
          </View>
        </TouchableOpacity>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    marginBottom: 16,
  },
  trigger: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#2a2a3e',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#4a4a6a',
    paddingHorizontal: 16,
    paddingVertical: 16,
    minHeight: 56,
  },
  triggerText: {
    color: '#e0d5c1',
    fontSize: 18,
    flex: 1,
  },
  placeholder: {
    color: '#6a6a8a',
  },
  arrow: {
    color: '#8a7a5a',
    fontSize: 14,
    marginLeft: 8,
  },
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.6)',
    justifyContent: 'center',
    padding: 32,
  },
  modal: {
    backgroundColor: '#1e1e32',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#4a4a6a',
    maxHeight: SCREEN_HEIGHT * 0.6,
    overflow: 'hidden',
  },
  modalTitle: {
    color: '#c9a84c',
    fontSize: 20,
    fontWeight: '700',
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#3a3a5a',
  },
  list: {
    maxHeight: SCREEN_HEIGHT * 0.5,
  },
  item: {
    paddingHorizontal: 20,
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#2a2a42',
  },
  itemSelected: {
    backgroundColor: '#2a2a4e',
  },
  itemText: {
    color: '#e0d5c1',
    fontSize: 18,
  },
  itemSubtext: {
    color: '#8a8aaa',
    fontSize: 14,
    marginTop: 4,
  },
  empty: {
    color: '#6a6a8a',
    fontSize: 16,
    textAlign: 'center',
    padding: 32,
  },
});
