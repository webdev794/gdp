import React, { useCallback, useState } from 'react';
import { useFocusEffect } from '@react-navigation/native';
import {
  ActivityIndicator, Linking, Pressable, ScrollView, StyleSheet, Text, View,
} from 'react-native';
import { api } from '../api';
import { colors, money } from '../theme';

const addressLine = (a) => (a ? [a.line1, a.city, a.state, a.postal_code].filter(Boolean).join(', ') : '');

export default function DeliveryDetailScreen({ route, navigation }) {
  const { id } = route.params;
  const [order, setOrder] = useState(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    try {
      const { data } = await api.riderOrders();
      const found = [...(data.assigned || []), ...(data.pool || [])].find((o) => o.id === id);
      setOrder(found || null);
      setError('');
    } catch (e) {
      setError(e.message);
    }
  }, [id]);

  useFocusEffect(useCallback(() => { load(); }, [load]));

  const act = async (kind) => {
    setBusy(true);
    setError('');
    try {
      if (kind === 'claim') await api.claimOrder(id);
      if (kind === 'cash') await api.riderCashCollected(id);
      if (kind === 'deliver') { await api.riderStatus(id, 'completed'); navigation.goBack(); return; }
      await load();
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  };

  if (!order) {
    return <View style={styles.center}>{error ? <Text style={styles.error}>{error}</Text> : <ActivityIndicator color={colors.brand} />}</View>;
  }

  const a = order.delivery_address || {};
  const mine = order.status === 'out_for_delivery';

  return (
    <ScrollView style={styles.screen} contentContainerStyle={{ padding: 16, paddingBottom: 40 }}>
      <Text style={styles.h}>Order #{order.id}</Text>
      <Text style={styles.sub}>{order.customer_name}</Text>
      {!!order.customer_phone && (
        <Pressable onPress={() => Linking.openURL(`tel:${order.customer_phone}`)}>
          <Text style={styles.link}>📞 {order.customer_phone}</Text>
        </Pressable>
      )}

      <Text style={styles.label}>Deliver to</Text>
      <Pressable onPress={() => Linking.openURL(`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(addressLine(a))}`)}>
        <Text style={styles.link}>{a.name ? `${a.name}\n` : ''}{addressLine(a)}  ↗</Text>
      </Pressable>

      {!!order.delivery_instructions && (
        <>
          <Text style={styles.label}>Instructions</Text>
          <Text style={styles.body}>“{order.delivery_instructions}”</Text>
        </>
      )}

      <Text style={styles.label}>Items</Text>
      {order.items.map((it, i) => (
        <Text key={i} style={styles.body}>{it.quantity} × {it.name}</Text>
      ))}

      <Text style={styles.label}>Payment</Text>
      <Text style={styles.body}>
        {order.payment_method === 'cod' ? 'Cash on delivery' : 'Paid online'} · {money(order.total_cents)}
      </Text>
      {order.cod_due > 0 && <Text style={styles.cod}>Collect {money(order.cod_due)} in cash.</Text>}

      {!!error && <Text style={styles.error}>{error}</Text>}

      <View style={styles.actions}>
        {mine ? (
          <>
            {order.cod_due > 0 && (
              <Pressable style={styles.btn} disabled={busy} onPress={() => act('cash')}><Text style={styles.btnText}>Cash collected</Text></Pressable>
            )}
            <Pressable style={[styles.btn, styles.primary]} disabled={busy} onPress={() => act('deliver')}><Text style={styles.btnText}>Mark delivered</Text></Pressable>
          </>
        ) : (
          <Pressable style={[styles.btn, styles.primary]} disabled={busy} onPress={() => act('claim')}><Text style={styles.btnText}>Pick up</Text></Pressable>
        )}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.bg },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.bg },
  h: { fontSize: 20, fontWeight: '800', color: colors.ink },
  sub: { color: colors.muted, marginTop: 2 },
  label: { marginTop: 18, marginBottom: 4, fontSize: 11, fontWeight: '800', color: colors.muted, textTransform: 'uppercase' },
  body: { color: colors.ink, fontSize: 14, lineHeight: 20 },
  link: { color: colors.accent, fontSize: 14, lineHeight: 20, fontWeight: '600' },
  cod: { marginTop: 6, color: colors.accent, fontWeight: '800' },
  error: { color: colors.danger, marginTop: 12 },
  actions: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, marginTop: 24 },
  btn: { paddingVertical: 12, paddingHorizontal: 18, borderRadius: 8, backgroundColor: colors.brand },
  primary: { backgroundColor: colors.accent },
  btnText: { color: '#fff', fontWeight: '800' },
});
