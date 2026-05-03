import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/materials_provider.dart';
import '../../utils/app_theme.dart';

class ChatScreenNew extends StatefulWidget {
  const ChatScreenNew({super.key});
  @override
  State<ChatScreenNew> createState() => _ChatScreenNewState();
}

class _ChatScreenNewState extends State<ChatScreenNew> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    final docProv = context.read<MaterialsProvider>();
    final context_ = docProv.documents
        .map((d) => '=== ${d.title} ===\n${d.rawText}')
        .join('\n\n');
    await context.read<ChatProvider>().sendMessage(text, studyMaterial: context_);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chat with AI'),
        actions: [
          if (chat.messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined, color: AppColors.accent),
              tooltip: 'New chat',
              onPressed: () => context.read<ChatProvider>().startNewSession(),
            ),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: chat.messages.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: chat.messages.length,
                  itemBuilder: (_, i) => _Bubble(msg: chat.messages[i]),
                ),
        ),

        // Typing indicator
        if (chat.isSending)
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 6),
            child: Row(children: [
              _TypingDots(),
              const SizedBox(width: 10),
              const Text('StudyFlow AI is thinking…',
                  style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),

        // Input bar
        _InputBar(ctrl: _inputCtrl, onSend: _send, disabled: chat.isSending),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.accentLight, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.accent, size: 36),
          ),
          const SizedBox(height: 20),
          const Text('Chat with AI', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 20)),
          const SizedBox(height: 8),
          const Text('Ask anything about your study materials. Your uploaded docs are automatically included as context.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.secondary, height: 1.6, fontSize: 14)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
            children: ['Summarize my notes', 'Create a study plan', 'Explain a concept', 'Quiz me']
                .map((s) => GestureDetector(
                      onTap: () => _inputCtrl.text = s,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: Text(s, style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: EdgeInsets.only(top: 4, bottom: 4, left: isUser ? 60 : 0, right: isUser ? 0 : 60),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.accent : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
              ),
              child: Text(
                msg.content.isEmpty ? '…' : msg.content,
                style: TextStyle(
                    color: isUser ? Colors.white : AppColors.primary,
                    fontSize: 15, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(children: List.generate(3, (i) {
          final opacity = (0.2 + 0.8 * (((_ctrl.value * 3) - i).clamp(0.0, 1.0))).clamp(0.2, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Opacity(opacity: opacity,
                child: const CircleAvatar(radius: 4, backgroundColor: AppColors.accent)),
          );
        }));
      },
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  final bool disabled;
  const _InputBar({required this.ctrl, required this.onSend, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
          left: 16, right: 16, top: 12, bottom: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: ctrl,
            maxLines: 4, minLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => disabled ? null : onSend(),
            style: const TextStyle(color: AppColors.primary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Ask about your study materials…',
              hintStyle: const TextStyle(color: AppColors.muted),
              filled: true, fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: disabled ? null : onSend,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: disabled ? AppColors.border : AppColors.accent,
                shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
