import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/document_model.dart';
import '../../providers/materials_provider.dart';
import '../../utils/app_theme.dart';
import '../quiz/quiz_screen_new.dart';
import '../flashcards/flashcards_screen.dart';
import '../summary/summary_screen.dart';

class DocumentDetailScreen extends StatelessWidget {
  final DocumentModel document;
  const DocumentDetailScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(document.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete document?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await context.read<MaterialsProvider>().deleteDocument(document.id);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Container(width: 48, height: 48,
                    decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.description_outlined, color: AppColors.accent, size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(document.title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('${document.rawText.split(' ').length} words',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ])),
              ]),
            ),
            const SizedBox(height: 24),

            const Text('Study Tools', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 14),

            _ToolCard(
              icon: Icons.article_outlined, label: 'Summary',
              description: 'Brief, detailed, or comprehensive notes',
              color: const Color(0xFF7C5CBF),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => SummaryScreen(document: document))),
            ),
            const SizedBox(height: 12),
            _ToolCard(
              icon: Icons.style_outlined, label: 'Flashcards',
              description: 'Generate 15 flip cards (+20 XP)',
              color: AppColors.accent,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => FlashcardsScreen(document: document))),
            ),
            const SizedBox(height: 12),
            _ToolCard(
              icon: Icons.quiz_outlined, label: 'Quiz',
              description: '10 MCQ questions (+10 XP per correct)',
              color: AppColors.success,
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => QuizScreenNew(document: document))),
            ),

            const SizedBox(height: 28),
            const Text('Document Content', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border)),
              child: Text(
                document.rawText.isNotEmpty ? document.rawText : '(No text content)',
                style: const TextStyle(color: AppColors.secondary, fontSize: 14, height: 1.6),
              ),
            ),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String label, description;
  final Color color;
  final VoidCallback onTap;
  const _ToolCard({required this.icon, required this.label, required this.description,
      required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)]),
        child: Row(children: [
          Container(width: 44, height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15)),
            const SizedBox(height: 2),
            Text(description, style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}
