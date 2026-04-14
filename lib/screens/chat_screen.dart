import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/document_provider.dart';
import '../models/chat_message_model.dart';
import '../utils/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const ChatScreen({super.key, this.onMenuTap});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).loadSessions();
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    final prov = Provider.of<ChatProvider>(context, listen: false);

    final docProv = Provider.of<DocumentProvider>(context, listen: false);
    final allDocsText = docProv.documents
        .map((d) => '=== ${d.title} ===\n${d.content ?? d.originalText ?? ''}')
        .join('\n\n');

    await prov.sendMessage(text, studyMaterial: allDocsText);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatProv = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.onMenuTap),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat with AI'),
            if (chatProv.currentSessionId != null)
              Text('Session active', style: TextStyle(fontSize: 11, color: AppTheme.accent)),
          ],
        ),
        actions: [
          if (chatProv.messages.isNotEmpty)
            IconButton(icon: const Icon(Icons.add_rounded, color: AppTheme.accent), tooltip: 'New session',
                onPressed: () => chatProv.startNewSession()),
          IconButton(icon: const Icon(Icons.history_rounded, color: AppTheme.mutedText), tooltip: 'History',
              onPressed: () => _showHistory(context, chatProv)),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ──
          Expanded(
            child: chatProv.messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: chatProv.messages.length,
                    itemBuilder: (_, i) => _buildBubble(chatProv.messages[i]),
                  ),
          ),

          // ── Typing indicator ──
          if (chatProv.isSending)
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 8),
              child: Row(
                children: [
                  SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent)),
                  const SizedBox(width: 10),
                  const Text('AI is thinking...', style: TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                ],
              ),
            ),

          // ── Input Bar ──
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    style: const TextStyle(color: AppTheme.navyText),
                    maxLines: 4, minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask about your study materials...',
                      hintStyle: const TextStyle(color: AppTheme.mutedText),
                      filled: true,
                      fillColor: AppTheme.bgColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: chatProv.isSending ? null : _send,
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: chatProv.isSending ? AppTheme.borderColor : AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppTheme.accentLight, shape: BoxShape.circle),
              child: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.accent, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('Chat with your AI tutor', style: TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w700, fontSize: 20)),
            const SizedBox(height: 10),
            const Text('Ask questions about your uploaded study materials and get instant AI-powered answers.',
                textAlign: TextAlign.center, style: TextStyle(color: AppTheme.greyText, height: 1.6, fontSize: 14)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
              children: ['Summarize my notes', 'Create a study plan', 'Explain a concept', 'Quiz me']
                  .map((s) => GestureDetector(
                        onTap: () { _inputCtrl.text = s; },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                          ),
                          child: Text(s, style: const TextStyle(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: EdgeInsets.only(top: 6, bottom: 6, left: isUser ? 64 : 0, right: isUser ? 0 : 64),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.accent : AppTheme.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isUser ? Colors.white : AppTheme.greyText,
                  fontSize: 15, height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context, ChatProvider chatProv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInnerState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              const Text('Chat History', style: TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 12),
              if (chatProv.sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No previous sessions', style: TextStyle(color: AppTheme.mutedText)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: chatProv.sessions.length,
                    itemBuilder: (_, i) {
                      final s = chatProv.sessions[i];
                      return ListTile(
                        leading: const Icon(Icons.chat_outlined, color: AppTheme.accent),
                        title: Text(s.title, style: const TextStyle(color: AppTheme.navyText)),
                        subtitle: Text('${s.messageCount} messages', style: const TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: AppTheme.mutedText, size: 18),
                          onPressed: () { chatProv.deleteSession(s.id); setInnerState(() {}); },
                        ),
                        onTap: () { chatProv.loadHistory(s.id); Navigator.pop(ctx); _scrollToBottom(); },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
