import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../utils/app_theme.dart';
import 'content_detail_screen.dart';

class FlashcardTopicsScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const FlashcardTopicsScreen({super.key, this.onMenuTap});

  @override
  State<FlashcardTopicsScreen> createState() => _FlashcardTopicsScreenState();
}

class _FlashcardTopicsScreenState extends State<FlashcardTopicsScreen> {
  @override
  Widget build(BuildContext context) {
    final docProv = Provider.of<DocumentProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.onMenuTap),
        title: const Text('Flashcards'),
      ),
      body: SafeArea(
        child: docProv.documents.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.style_outlined, size: 72, color: AppTheme.mutedText.withOpacity(0.4)),
                    const SizedBox(height: 16),
                    const Text('No materials yet', style: TextStyle(color: AppTheme.greyText, fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Upload study materials from the Content tab\nto generate flashcards.',
                        textAlign: TextAlign.center, style: TextStyle(color: AppTheme.mutedText, fontSize: 13)),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Your Study Materials', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.navyText)),
                        SizedBox(height: 4),
                        Text('Select a material to generate flashcards', style: TextStyle(color: AppTheme.greyText, fontSize: 14)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: docProv.documents.length,
                      itemBuilder: (ctx, i) {
                        final doc = docProv.documents[i];
                        final topics = doc.topics ?? [];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ContentDetailScreen(document: doc, initialTab: 2),
                            )),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.style_outlined, color: AppTheme.accent, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w600, fontSize: 15)),
                                        if (topics.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6, runSpacing: 4,
                                            children: topics.take(3).map((t) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: AppTheme.accentLight,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(t.toString(), style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w500)),
                                            )).toList(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedText, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
