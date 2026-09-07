import React, { useCallback, useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator, KeyboardAvoidingView, Platform, Pressable, ScrollView,
  StyleSheet, Text, TextInput, View,
} from 'react-native';
import { api } from '../api';
import { colors } from '../theme';

export default function SupportThreadScreen({ route }) {
  const { id } = route.params;
  const [thread, setThread] = useState(null);
  const [reply, setReply] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const scrollRef = useRef(null);

  const refresh = useCallback(async () => {
    try {
      const { data } = await api.supportThread(id);
      setThread(data);
    } catch (e) {
      setError(e.message);
    }
  }, [id]);

  useEffect(() => {
    refresh();
    const timer = setInterval(refresh, 4000);
    return () => clearInterval(timer);
  }, [refresh]);

  const send = async () => {
    const body = reply.trim();
    if (!body) return;
    setBusy(true);
    setError('');
    try {
      const { data } = await api.supportReply(id, body);
      setReply('');
      setThread(data);
    } catch (e) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  };

  if (!thread) {
    return <View style={styles.center}><ActivityIndicator color={colors.brand} /></View>;
  }

  return (
    <KeyboardAvoidingView
      style={styles.screen}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={90}
    >
      {thread.status === 'resolved' && (
        <Text style={styles.resolved}>This conversation is resolved. Send a message to re-open it.</Text>
      )}
      <ScrollView
        ref={scrollRef}
        style={styles.log}
        contentContainerStyle={{ padding: 16, gap: 9 }}
        onContentSizeChange={() => scrollRef.current?.scrollToEnd({ animated: true })}
      >
        {(thread.messages ?? []).map((m) => {
          const kind = m.is_staff ? 'staff' : m.user_id ? 'me' : 'system';
          return (
            <View key={m.id} style={[styles.msg, styles[kind]]}>
              <Text style={kind === 'me' ? styles.msgTextMe : styles.msgText}>{m.body}</Text>
              <Text style={kind === 'me' ? styles.timeMe : styles.time}>
                {new Date(m.created_at).toLocaleString()}
              </Text>
            </View>
          );
        })}
      </ScrollView>
      {!!error && <Text style={styles.error}>{error}</Text>}
      <View style={styles.sendRow}>
        <TextInput
          style={styles.input}
          placeholder="Type a message"
          placeholderTextColor={colors.muted}
          value={reply}
          onChangeText={setReply}
        />
        <Pressable style={styles.sendBtn} onPress={send} disabled={busy || !reply.trim()}>
          <Text style={styles.sendText}>Send</Text>
        </Pressable>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.bg },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.bg },
  resolved: { backgroundColor: '#fdeede', color: '#8a5a1f', padding: 10, fontSize: 12 },
  log: { flex: 1 },
  msg: { maxWidth: '82%', padding: 9, borderRadius: 12 },
  me: { alignSelf: 'flex-end', backgroundColor: colors.accent },
  staff: { alignSelf: 'flex-start', backgroundColor: colors.surface, borderWidth: 1, borderColor: colors.line },
  system: { alignSelf: 'center', backgroundColor: '#e7eef6' },
  msgText: { color: colors.ink, fontSize: 13 },
  msgTextMe: { color: '#fff', fontSize: 13 },
  time: { color: colors.muted, fontSize: 9, marginTop: 3 },
  timeMe: { color: '#e4f3e4', fontSize: 9, marginTop: 3 },
  error: { color: colors.danger, paddingHorizontal: 16 },
  sendRow: { flexDirection: 'row', gap: 8, padding: 12, borderTopWidth: 1, borderColor: colors.line, backgroundColor: colors.surface },
  input: { flex: 1, borderWidth: 1, borderColor: colors.line, padding: 10, color: colors.ink, backgroundColor: colors.bg },
  sendBtn: { paddingHorizontal: 16, justifyContent: 'center', backgroundColor: colors.brand },
  sendText: { color: '#fff', fontWeight: '800' },
});
