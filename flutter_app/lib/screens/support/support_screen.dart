import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/support_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/responsive.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _newSubjectController = TextEditingController();
  final TextEditingController _newMsgController = TextEditingController();
  final TextEditingController _chatMsgController = TextEditingController();
  SupportThread? _selectedThread;

  @override
  void dispose() {
    _newSubjectController.dispose();
    _newMsgController.dispose();
    _chatMsgController.dispose();
    super.dispose();
  }

  void _openNewTicketSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Open Support Ticket',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.slateDark),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _newSubjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject / Issue',
                    hintText: 'e.g. Missing Item, Delivery Delay, Refund',
                  ),
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
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () async {
                    if (_newSubjectController.text.trim().isEmpty || _newMsgController.text.trim().isEmpty) return;
                    HapticFeedback.heavyImpact();
                    Navigator.pop(ctx);
                    final thread = await ApiService.createSupportThread(
                      _newSubjectController.text.trim(),
                      _newMsgController.text.trim(),
                    );
                    _newSubjectController.clear();
                    _newMsgController.clear();
                    setState(() => _selectedThread = thread);
                  },
                  child: const Text('SUBMIT TICKET'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sendChatMessage() async {
    if (_chatMsgController.text.trim().isEmpty || _selectedThread == null) return;
    String text = _chatMsgController.text.trim();
    _chatMsgController.clear();
    HapticFeedback.lightImpact();

    await ApiService.sendSupportMessage(_selectedThread!.id, text);
    setState(() {});
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
                onPressed: () => setState(() => _selectedThread = null),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment, color: AppTheme.emeraldPrimary),
            tooltip: 'New Ticket',
            onPressed: _openNewTicketSheet,
          ),
        ],
      ),
      body: SafeArea(
        child: isLandscape
            ? Row(
                children: [
                  // Left Pane: Thread List
                  Expanded(
                    flex: 4,
                    child: _buildThreadList(threads),
                  ),
                  const VerticalDivider(width: 1, color: AppTheme.borderSubtle),
                  // Right Pane: Active Chat
                  Expanded(
                    flex: 6,
                    child: _selectedThread != null
                        ? _buildChatPane(_selectedThread!)
                        : const Center(child: Text('Select a support ticket to view messages')),
                  ),
                ],
              )
            : (_selectedThread != null ? _buildChatPane(_selectedThread!) : _buildThreadList(threads)),
      ),
    );
  }

  Widget _buildThreadList(List<SupportThread> threads) {
    if (threads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎧', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 14),
            const Text('No Active Support Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Need help with an order? Contact our support team!', style: TextStyle(color: AppTheme.slateMuted)),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: _openNewTicketSheet, child: const Text('OPEN NEW TICKET')),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: threads.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final thread = threads[index];
        bool isSelected = _selectedThread?.id == thread.id;

        return Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.sageLight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppTheme.emeraldPrimary : AppTheme.borderSubtle, width: isSelected ? 1.8 : 1),
          ),
          child: ListTile(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedThread = thread);
            },
            title: Text(
              thread.subject,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.slateDark),
            ),
            subtitle: Text(
              thread.messages.isNotEmpty ? thread.messages.last.message : 'No messages',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTheme.slateMuted),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: thread.status == 'open' ? AppTheme.sageLight : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                thread.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: thread.status == 'open' ? AppTheme.emeraldPrimary : AppTheme.slateDark,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatPane(SupportThread thread) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: thread.messages.length,
            itemBuilder: (context, idx) {
              final msg = thread.messages[idx];
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
                  child: Text(
                    msg.message,
                    style: TextStyle(
                      color: msg.isUser ? Colors.white : AppTheme.slateDark,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
          ),
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
                icon: const Icon(Icons.send, color: AppTheme.emeraldPrimary),
                onPressed: _sendChatMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
