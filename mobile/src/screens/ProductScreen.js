import React, { useEffect, useState } from 'react';
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { api } from '../api';
import { useApp } from '../state';
import { colors, money } from '../theme';

export default function ProductScreen({ route, navigation }) {
  const { slug } = route.params;
  const { addToCart, deliveryLocation } = useApp();
  const [product, setProduct] = useState(null);
  const [error, setError] = useState('');
  const [added, setAdded] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const { data } = await api.product(
          slug,
          deliveryLocation ? { lat: deliveryLocation.lat, lng: deliveryLocation.lng } : {},
        );
        setProduct(data);
        navigation.setOptions({ title: data.name });
      } catch (e) {
        setError(e.message);
      }
    })();
  }, [slug]);

  if (error) return <Text style={styles.error}>{error}</Text>;
  if (!product) {
    return (
      <View style={styles.centre}>
        <ActivityIndicator size="large" color={colors.brand} />
      </View>
    );
  }

  return (
    <ScrollView style={styles.wrap} contentContainerStyle={{ padding: 20 }}>
      <View style={styles.hero}>
        <Text style={styles.heroText}>
          {product.name.split(' ').map((w) => w[0]).join('').slice(0, 2).toUpperCase()}
        </Text>
      </View>
      <Text style={styles.cat}>{product.category?.name ?? 'Grocery'}</Text>
      <Text style={styles.name}>{product.name}</Text>
      <Text style={styles.price}>{money(product.price_cents)}</Text>
      {!!product.description && <Text style={styles.desc}>{product.description}</Text>}
      <Text style={styles.stock}>
        {product.inventory_quantity > 0 ? `${product.inventory_quantity} in stock` : 'Out of stock'}
      </Text>

      <Pressable
        style={[styles.button, product.inventory_quantity <= 0 && styles.buttonOff]}
        disabled={product.inventory_quantity <= 0}
        onPress={() => {
          addToCart(product);
          setAdded(true);
          setTimeout(() => setAdded(false), 1500);
        }}
      >
        <Text style={styles.buttonText}>
          {product.inventory_quantity <= 0 ? 'Out of stock' : added ? 'Added to cart' : 'Add to cart'}
        </Text>
      </Pressable>
      <Pressable style={styles.secondary} onPress={() => navigation.navigate('Cart')}>
        <Text style={styles.secondaryText}>Go to cart</Text>
      </Pressable>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  wrap: { flex: 1, backgroundColor: colors.bg },
  centre: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.bg },
  error: { color: colors.danger, padding: 20 },
  hero: {
    height: 180,
    borderRadius: 16,
    backgroundColor: '#eef1ec',
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroText: { fontSize: 46, fontWeight: '800', color: colors.accent },
  cat: { fontSize: 11, color: colors.muted, textTransform: 'uppercase', letterSpacing: 0.6, marginTop: 18 },
  name: { fontSize: 24, fontWeight: '800', color: colors.ink, marginTop: 4, letterSpacing: -0.5 },
  price: { fontSize: 20, fontWeight: '800', color: colors.ink, marginTop: 10 },
  desc: { fontSize: 14, color: colors.muted, marginTop: 14, lineHeight: 21 },
  stock: { fontSize: 12, color: colors.muted, marginTop: 14 },
  button: {
    backgroundColor: colors.brand,
    borderRadius: 10,
    paddingVertical: 15,
    alignItems: 'center',
    marginTop: 24,
  },
  buttonOff: { backgroundColor: colors.muted, opacity: 0.6 },
  buttonText: { color: '#fff', fontSize: 15, fontWeight: '700' },
  secondary: { paddingVertical: 14, alignItems: 'center' },
  secondaryText: { color: colors.muted, fontSize: 13 },
});
