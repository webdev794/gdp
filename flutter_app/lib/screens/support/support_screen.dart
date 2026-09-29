import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/order_model.dart';
import '../../models/support_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';

/// Support chats with the store team — the same conversations the customer
/// sees on the website. Open chats refresh every few seconds for replies.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _newMsgController = TextEditingController();
  final TextEditingController _chatMsgController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  SupportThread? _selectedThread;
  bool _loading = true;
  bool _sending = false;
  String _error = '';
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _loadThreads();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_selectedThread != null) _refreshSelected();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _newMsgController.dispose();
    _chatMsgController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await ApiService.fetchSupportThreads();
    } catch (e) {
      _error = e is ApiException ? e.message : 'Could not load your support chats. Check your connection and try again.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openThread(SupportThread thread) async {
    HapticFeedback.lightImpact();
    setState(() => _selectedThread = thread);
    await _refreshSelected();
  }

  Future<void> _refreshSelected() async {
    final current = _selectedThread;
    if (current == null) return;
    try {
      final fresh = await ApiService.fetchSupportThread(current.id);
      if (!mounted || _selectedThread?.id != current.id) return;
      final grew = fresh.messages.length != current.messages.length;
      setState(() => _selectedThread = fresh);
      if (grew) _scrollToEnd();
    } catch (_) {}
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(_chatScroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _openNewTicketSheet() async {
    List<OrderModel> orders = ApiService.cachedOrders;
    if (orders.isEmpty) {
      try {
        orders = await ApiService.fetchOrders();
      } catch (_) {}
    }
    if (!mounted) return;

    String issueType = 'other';
    String? orderId;
    String sheetError = '';
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(top: 24, left: 20, right: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contact support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.slateDark)),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: issueType,
                  decoration: const InputDecoration(labelText: 'What went wrong?'),
                  items: supportIssueTypes.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setSheet(() => issueType = v ?? 'other'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: orderId,
                  decoration: const InputDecoration(labelText: 'About an order (optional)'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Not about a specific order')),
                    ...orders.take(20).map((o) => DropdownMenuItem<String?>(
                          value: o.id,
                          child: Text('${o.orderNumber} · \$${o.total.toStringAsFixed(2)}'),
                        )),
                  ],
                  onChanged: (v) => setSheet(() => orderId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newMsgController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Describe your issue',
                    hintText: 'How can our customer team help you today?',
                  ),
                ),
                if (sheetError.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(sheetError, style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final text = _newMsgController.text.trim();
                          if (text.isEmpty) {
                            setSheet(() => sheetError = 'Add a message describing the problem.');
                            return;
                          }
                          setSheet(() {
                            submitting = true;
                            sheetError = '';
                          });
                          HapticFeedback.heavyImpact();
                          try {
                            final thread = await ApiService.createSupportThread(issueType, text, orderId: orderId);
                            _newMsgController.clear();
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) setState(() => _selectedThread = thread);
                            _scrollToEnd();
                          } catch (e) {
                            setSheet(() {
                              submitting = false;
                              sheetError = e.toString();
                            });
                          }
                        },
                  child: Text(submitting ? 'SENDING…' : 'START CHAT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendChatMessage() async {
    final thread = _selectedThread;
    final text = _chatMsgController.text.trim();
    if (text.isEmpty || thread == null || _sending) return;
    HapticFeedback.lightImpact();
    setState(() => _sending = true);
    try {
      await ApiService.sendSupportMessage(thread.id, text);
      _chatMsgController.clear();
      await _refreshSelected();
      _scrollToEnd();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorRed));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final threads = ApiService.cachedThreads;
    final isLandscape = Responsive.isLandscape(context);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(
          _selectedThread != null ? _selectedThread!.subject : 'Customer Support 💬',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
        leading: _selectedThread != null && !isLandscape
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() => _selectedThread = null);
                  _loadThreads();
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment, color: AppTheme.emeraldPrimary),
            tooltip: 'New chat',
            onPressed: _openNewTicketSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: isLandscape
            ? Row(
                children: [
                  Expanded(flex: 4, child: _buildThreadList(threads)),
                  const VerticalDivider(width: 1, color: AppTheme.borderSubtle),
                  Expanded(
                    flex: 6,
                    child: _selectedThread != null
                        ? _buildChatPane(_selectedThread!)
                        : const Center(child: Text('Select a chat to view messages')),
                  ),
                ],
              )
            : (_selectedThread != null ? _buildChatPane(_selectedThread!) : _buildThreadList(threads)),
      ),
    );
  }

  Widget _buildThreadList(List<SupportThread> threads) {
    if (_loading && threads.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty && threads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadThreads, child: const Text('TRY AGAIN')),
            ],
          ),
        ),
      );
    }
    if (threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎧', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 14),
            const Text('No support chats yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Need help with an order? Contact our support team!', style: TextStyle(color: AppTheme.slateMuted)),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: _openNewTicketSheet, child: const Text('CONTACT SUPPORT')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadThreads,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: threads.length,
        separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final thread = threads[index];
          final isSelected = _selectedThread?.id == thread.id;
          final isOpen = thread.status == 'open';
          final when = thread.lastMessageAt ?? thread.createdAt;

          return Container(
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.sageLight : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isSelected ? AppTheme.emeraldPrimary : AppTheme.borderSubtle, width: isSelected ? 1.8 : 1),
            ),
            child: ListTile(
              onTap: () => _openThread(thread),
              title: Text(thread.subject, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.slateDark)),
              subtitle: Text(
                '${thread.messageCount} message${thread.messageCount == 1 ? '' : 's'} · ${when.day}/${when.month}/${when.year}',
                style: const TextStyle(fontSize: 12, color: AppTheme.slateMuted),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOpen ? AppTheme.sageLight : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  thread.status.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isOpen ? AppTheme.emeraldPrimary : AppTheme.slateDark),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatPane(SupportThread thread) {
    // Replying to a resolved chat reopens it (same as the website).
    final canReply = thread.status != 'closed';
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _chatScroll,
            padding: const EdgeInsets.all(16),
            itemCount: thread.messages.length,
            itemBuilder: (context, idx) {
              final msg = thread.messages[idx];
              if (msg.isSystem) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(msg.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5, color: AppTheme.slateMuted)),
                );
              }
              return Align(
                alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: msg.isUser ? AppTheme.emeraldPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: msg.isUser ? null : Border.all(color: AppTheme.borderSubtle),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!msg.isUser)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text('Support team', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppTheme.coralAccent)),
                        ),
                      if (msg.attachmentUrl != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(msg.attachmentUrl!, height: 160, fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox.shrink()),
                          ),
                        ),
                      if (msg.message.isNotEmpty)
                        Text(
                          msg.message,
                          style: TextStyle(color: msg.isUser ? Colors.white : AppTheme.slateDark, fontSize: 13.5, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (!canReply)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: const Text('This chat is closed. Start a new chat if you still need help.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.slateMuted)),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.borderSubtle))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatMsgController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onSubmitted: (_) => _sendChatMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _sending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: AppTheme.emeraldPrimary),
                  onPressed: _sending ? null : _sendChatMessage,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
