import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/document_provider.dart';
import '../models/document_model.dart';
import '../utils/app_theme.dart';
import '../widgets/upload_bottom_sheet.dart';
import 'content_detail_screen.dart';

class ContentScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const ContentScreen({super.key, this.onMenuTap});

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  @override
  Widget build(BuildContext context) {
    final docProv = Provider.of<DocumentProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.onMenuTap),
        title: const Text('Content'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppTheme.accent), onPressed: () => docProv.fetchDocuments()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
          builder: (_) => const UploadBottomSheet(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Upload', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => docProv.fetchDocuments(),
          color: AppTheme.accent,
          child: docProv.isLoading && docProv.documents.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : docProv.documents.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                      itemCount: docProv.documents.length,
                      itemBuilder: (ctx, i) => _buildCard(ctx, docProv.documents[i], docProv),
                    ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.feed_outlined, size: 72, color: AppTheme.mutedText.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('No materials yet', style: TextStyle(color: AppTheme.greyText, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Tap + Upload to add your first study material', textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.mutedText, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Document doc, DocumentProvider docProv) {
    final topics = (doc.topics ?? []);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContentDetailScreen(document: doc))),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_outlined, color: AppTheme.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 3),
                          Text(DateFormat('MMM dd, yyyy').format(doc.createdAt),
                              style: const TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _confirmDelete(context, doc, docProv),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.delete_outline_rounded, color: AppTheme.mutedText, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Topics
              if (topics.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SizedBox(
                    height: 28,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: topics.length > 4 ? 4 : topics.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(topics[i].toString(), style: const TextStyle(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ),

              // Divider
              const Divider(height: 1, color: AppTheme.borderColor),

              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    _actionBtn(context, Icons.summarize_outlined, 'Summary', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ContentDetailScreen(document: doc, initialTab: 0)));
                    }),
                    const SizedBox(width: 8),
                    _actionBtn(context, Icons.quiz_outlined, 'Quiz', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ContentDetailScreen(document: doc, initialTab: 1)));
                    }),
                    const SizedBox(width: 8),
                    _actionBtn(context, Icons.style_outlined, 'Cards', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ContentDetailScreen(document: doc, initialTab: 2)));
                    }),
                    const SizedBox(width: 8),
                    _actionBtn(context, Icons.preview_outlined, 'Preview', () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ContentDetailScreen(document: doc, initialTab: 3)));
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppTheme.accent),
              const SizedBox(width: 4),
              Flexible(child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.greyText, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Document doc, DocumentProvider prov) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Material?', style: TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to delete "${doc.title}"? This cannot be undone.',
            style: const TextStyle(color: AppTheme.greyText)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedText))),
          TextButton(
            onPressed: () async { Navigator.pop(context); await prov.deleteDocument(doc.id); },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
