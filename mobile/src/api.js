import AsyncStorage from '@react-native-async-storage/async-storage';
import { API_URL } from './config';

const TOKEN_KEY = 'grocerly_token';

let memoryToken = null;

export async function loadToken() {
  if (memoryToken) return memoryToken;
  memoryToken = await AsyncStorage.getItem(TOKEN_KEY);
  return memoryToken;
}

export async function setToken(token) {
  memoryToken = token;
  if (token) await AsyncStorage.setItem(TOKEN_KEY, token);
  else await AsyncStorage.removeItem(TOKEN_KEY);
}

async function request(path, { method = 'GET', body, auth = false } = {}) {
  const headers = { Accept: 'application/json' };
  if (body !== undefined) headers['Content-Type'] = 'application/json';
  if (auth) {
    const token = await loadToken();
    if (token) headers.Authorization = `Bearer ${token}`;
  }

  let response;
  try {
    response = await fetch(`${API_URL}${path}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch (error) {
    throw new Error(`Cannot reach the API at ${API_URL}. Is Laravel running?`);
  }

  const text = await response.text();
  const data = text ? JSON.parse(text) : {};

  if (!response.ok) {
    const message =
      data.message ||
      Object.values(data.errors || {})[0]?.[0] ||
      `Request failed (${response.status}).`;
    const err = new Error(message);
    err.status = response.status;
    err.data = data;
    throw err;
  }

  return data;
}

export const api = {
  config: () => request('/config'),

  register: (payload) => request('/auth/register', { method: 'POST', body: payload }),
  login: (payload) => request('/auth/login', { method: 'POST', body: payload }),
  verifyOtp: (payload) => request('/auth/verify-otp', { method: 'POST', body: payload }),
  resendOtp: (payload) => request('/auth/resend-otp', { method: 'POST', body: payload }),
  me: () => request('/user', { auth: true }),
  logout: () => request('/auth/logout', { method: 'POST', auth: true }),

  categories: () => request('/categories'),
  products: ({ search, category } = {}) => {
    const params = new URLSearchParams();
    if (search) params.set('search', search);
    if (category) params.set('category', category);
    const query = params.toString();
    return request(`/products${query ? `?${query}` : ''}`);
  },
  product: (slug) => request(`/products/${slug}`),

  addCartItem: (product_id, quantity) =>
    request('/cart/items', { method: 'POST', body: { product_id, quantity }, auth: true }),
  clearCart: () => request('/cart', { method: 'DELETE', auth: true }),

  addresses: () => request('/addresses', { auth: true }),
  addAddress: (payload) => request('/addresses', { method: 'POST', body: payload, auth: true }),

  checkout: (payload) => request('/checkout', { method: 'POST', body: payload, auth: true }),
  paymentIntent: (orderId) =>
    request(`/orders/${orderId}/payment-intent`, { method: 'POST', auth: true }),
  orders: () => request('/orders', { auth: true }),
  order: (id) => request(`/orders/${id}`, { auth: true }),
};
