import React, { useCallback, useState } from 'react';
import { useFocusEffect } from '@react-navigation/native';
import {
  ActivityIndicator, Linking, Pressable, RefreshControl, ScrollView, StyleSheet, Text, View,
} from 'react-native';
import * as Location from 'expo-location';
import { api } from '../api';
import { colors, money } from '../theme';

// Best-effort: tell the server where the rider is so auto-assignment can pick the
// closest one. Silent on failure (permission denied, GPS off, offline).
async function pingLocation() {
  try {
    const { status } = await Location.requestForegroundPermissionsAsync();
    if (status !== 'granted') return;
    const pos = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Balanced });
    await api.riderLocation(pos.coords.latitude, pos.coords.longitude);
  } catch {
    // ignore
  }
}

function addressLine(a) {
  if (!a) return '';
  return [a.line1, a.city, a.state, a.postal_code].filter(Boolean).join(', ');
}

function DeliveryCard({ order, mine, onAction, navigation, busy }) {
  const a = order.delivery_address || {};
  return (
    <Pressable style={styles.card} onPress={() => navigation.navigate('DeliveryDetail', { id: order.id })}>
      <View style={styles.cardHead}>
        <Text style={styles.orderId}>Order #{order.id}</Text>
        <Text style={styles.meta}>{order.items?.length ?? 0} items · {money(order.total_cents)}</Text>
      </View>
      <Text style={styles.addr}>{addressLine(a)}</Text>
      {!!order.delivery_instructions && <Text style={styles.note}>“{order.delivery_instructions}”</Text>}
      {order.cod_due > 0 && <Text style={styles.cod}>Collect cash: {money(order.cod_due)}</Text>}
      <View style={styles.actions}>
        <Pressable style={styles.linkBtn} onPress={() => Linking.openURL(`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(addressLine(a))}`)}>
          <Text style={styles.linkText}>Maps</Text>
        </Pressable>
        {!!order.customer_phone && (
          <Pressable style={styles.linkBtn} onPress={() => Linking.openURL(`tel:${order.customer_phone}`)}>
            <Text style={styles.linkText}>Call</Text>
          </Pressable>
        )}
        {mine ? (
          <>
            {order.cod_due > 0 && (
              <Pressable style={styles.actBtn} disabled={busy} onPress={() => onAction('cash', order)}>
                <Text style={styles.actText}>Cash collected</Text>
              </Pressable>
            )}
            <Pressable style={[styles.actBtn, styles.primaryBtn]} disabled={busy} onPress={() => onAction('deliver', order)}>
              <Text style={styles.actText}>Mark delivered</Text>
            </Pressable>
          </>
        ) : (
          <Pressable style={[styles.actBtn, styles.primaryBtn]} disabled={busy} onPress={() => onAction('claim', order)}>
            <Text style={styles.actText}>Pick up</Text>
          </Pressable>
        )}
      </View>
    </Pressable>
  );
}

export default function RiderScreen({ navigation }) {
  const [data, setData] = useState({ assigned: [], pool: [] });
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    try {
      const { data: d } = await api.riderOrders();
      setData(d ?? { assigned: [], pool: [] });
      setError('');
    } catch (e) {
      setError(e.message);
    }
  }, []);

  useFocusEffect(useCallback(() => {
    let active = true;
    (async () => { await load(); if (active) setLoading(false); })();
    pingLocation();
    const timer = setInterval(load, 15000);
    // Refresh the rider's position every couple of minutes while the screen is open.
    const locTimer = setInterval(pingLocation, 120000);
    return () => { active = false; clearInterval(timer); clearInterval(locTimer); };
  }, [load]));

  const onAction = async (kind, order) => {
    setBusy(true);
    setError('');
    try {
      if (kind === 'claim') await api.claimOrder(order.id);
      if (kind === 'cash') await api.riderCashCollected(order.id);
      if (kind === 'deliver') await api.riderStatus(order.id, 'completed');
      await load();
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  };

  if (loading) return <View style={styles.center}><ActivityIndicator size="large" color={colors.brand} /></View>;

  return (
    <ScrollView
      style={styles.screen}
      contentContainerStyle={{ padding: 16, paddingBottom: 40 }}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={async () => { setRefreshing(true); await load(); setRefreshing(false); }} />}
    >
      {!!error && <Text style={styles.error}>{error}</Text>}

      <Text style={styles.section}>My deliveries ({data.assigned.length})</Text>
      {data.assigned.length === 0 && <Text style={styles.muted}>Nothing on the go.</Text>}
      {data.assigned.map((o) => (
        <DeliveryCard key={o.id} order={o} mine onAction={onAction} navigation={navigation} busy={busy} />
      ))}

      <Text style={styles.section}>Available to pick up ({data.pool.length})</Text>
      {data.pool.length === 0 && <Text style={styles.muted}>No orders waiting.</Text>}
      {data.pool.map((o) => (
        <DeliveryCard key={o.id} order={o} mine={false} onAction={onAction} navigation={navigation} busy={busy} />
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.bg },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.bg },
  section: { fontSize: 13, fontWeight: '800', color: colors.ink, marginTop: 18, marginBottom: 8, textTransform: 'uppercase' },
  muted: { color: colors.muted, fontSize: 13 },
  error: { color: colors.danger, marginBottom: 10 },
  card: { backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.line, borderRadius: 12, padding: 14, marginBottom: 10 },
  cardHead: { flexDirection: 'row', justifyContent: 'space-between' },
  orderId: { fontWeight: '800', color: colors.ink },
  meta: { color: colors.muted, fontSize: 12 },
  addr: { marginTop: 6, color: colors.ink, fontSize: 13 },
  note: { marginTop: 4, color: '#8a6d2f', fontSize: 12, fontStyle: 'italic' },
  cod: { marginTop: 6, color: colors.accent, fontWeight: '700', fontSize: 13 },
  actions: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 12 },
  linkBtn: { paddingVertical: 8, paddingHorizontal: 14, borderWidth: 1, borderColor: colors.line, borderRadius: 8 },
  linkText: { color: colors.ink, fontWeight: '700', fontSize: 12 },
  actBtn: { paddingVertical: 8, paddingHorizontal: 14, borderRadius: 8, backgroundColor: colors.brand },
  primaryBtn: { backgroundColor: colors.accent },
  actText: { color: '#fff', fontWeight: '800', fontSize: 12 },
});
