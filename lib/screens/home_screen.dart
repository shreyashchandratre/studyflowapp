import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';
import 'login_screen.dart';
import '../utils/app_theme.dart';
import '../widgets/upload_bottom_sheet.dart';
import '../widgets/summary_bottom_sheet.dart';
import 'quiz_screen.dart';
import 'flashcard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DocumentProvider>(context, listen: false).fetchDocuments();
    });
  }

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const UploadBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final docProvider = Provider.of<DocumentProvider>(context);
    final username = authProvider.user?['name']?.split(' ').first ?? 'Student';

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('StudyFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.mutedText),
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => docProvider.fetchDocuments(),
          color: AppTheme.accent,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hey $username 👋',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.navyText)),
                      const SizedBox(height: 6),
                      const Text('Ready to flow through your studies?',
                          style: TextStyle(color: AppTheme.greyText, fontSize: 15)),
                    ],
                  ),
                ),
              ),

              if (docProvider.isLoading && docProvider.documents.isEmpty)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (docProvider.documents.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.feed_outlined, size: 72, color: AppTheme.mutedText.withOpacity(0.4)),
                        const SizedBox(height: 16),
                        const Text('Upload your first document\nto get started!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.greyText, fontSize: 17)),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = docProvider.documents[index];
                      return _buildDocumentCard(doc);
                    },
                    childCount: docProvider.documents.length,
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildDocumentCard(document) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 4, height: 48,
              decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.accentLight, borderRadius: BorderRadius.circular(6)),
                        child: const Text('DOC', style: TextStyle(fontSize: 10, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Text(DateFormat('MMM dd, yyyy').format(document.createdAt),
                          style: const TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(document.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.navyText, fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12, runSpacing: 8,
                    children: [
                      _actionButton(Icons.summarize_outlined, 'Summary', onTap: () {
                        showModalBottomSheet(
                          context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                          builder: (_) => SummaryBottomSheet(documentId: document.id),
                        );
                      }),
                      _actionButton(Icons.style_outlined, 'Flashcards', onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardScreen(documentId: document.id)));
                      }),
                      _actionButton(Icons.quiz_outlined, 'Quiz', onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(documentId: document.id)));
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.accent),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: AppTheme.greyText, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
