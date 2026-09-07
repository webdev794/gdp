import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { api, loadToken, setToken } from './api';

const CART_KEY = 'grocerly_cart';

const AppContext = createContext(null);

export function AppProvider({ children }) {
  const [booting, setBooting] = useState(true);
  const [user, setUser] = useState(null);
  const [cart, setCart] = useState([]);
  const [config, setConfig] = useState(null);

  useEffect(() => {
    (async () => {
      try {
        const stored = await AsyncStorage.getItem(CART_KEY);
        if (stored) setCart(JSON.parse(stored));
      } catch {}
      try {
        const { data } = await api.config();
        setConfig(data);
      } catch {}
      const token = await loadToken();
      if (token) {
        try {
          setUser(await api.me());
        } catch {
          await setToken(null);
        }
      }
      setBooting(false);
    })();
  }, []);

  useEffect(() => {
    AsyncStorage.setItem(CART_KEY, JSON.stringify(cart)).catch(() => {});
  }, [cart]);

  const value = useMemo(() => {
    const cartCount = cart.reduce((sum, item) => sum + item.quantity, 0);
    const cartTotal = cart.reduce((sum, item) => sum + item.price_cents * item.quantity, 0);

    return {
      booting,
      user,
      config,
      cart,
      cartCount,
      cartTotal,
      async signIn(token) {
        await setToken(token);
        setUser(await api.me());
      },
      async signOut() {
        try {
          await api.logout();
        } catch {}
        await setToken(null);
        setUser(null);
      },
      async refreshUser() {
        try {
          setUser(await api.me());
        } catch {}
      },
      addToCart(product) {
        setCart((current) => {
          const found = current.find((item) => item.id === product.id);
          if (found) {
            return current.map((item) =>
              item.id === product.id ? { ...item, quantity: item.quantity + 1 } : item
            );
          }
          return [
            ...current,
            { id: product.id, name: product.name, price_cents: product.price_cents, quantity: 1 },
          ];
        });
      },
      changeQuantity(id, delta) {
        setCart((current) =>
          current.flatMap((item) => {
            if (item.id !== id) return [item];
            const quantity = item.quantity + delta;
            return quantity > 0 ? [{ ...item, quantity }] : [];
          })
        );
      },
      clearCart() {
        setCart([]);
      },
    };
  }, [booting, user, config, cart]);

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp must be used inside AppProvider');
  return context;
}
