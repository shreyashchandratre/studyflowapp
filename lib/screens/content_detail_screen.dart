import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/document_model.dart';
import '../providers/document_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/typewriter_text.dart';
import '../widgets/shimmer_skeleton.dart';
import 'quiz_screen.dart';
import 'flashcard_screen.dart';

class ContentDetailScreen extends StatefulWidget {
  final Document document;
  final int initialTab;

  const ContentDetailScreen({super.key, required this.document, this.initialTab = 0});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? _summaryData;
  bool _summaryLoading = false;
  String? _summaryError;
  int _activeSummaryTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _tabController.addListener(() {
      if (_tabController.index == 0 && _summaryData == null && !_summaryLoading) {
        _loadSummary();
      }
    });
    if (widget.initialTab == 0) _loadSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() { _summaryLoading = true; _summaryError = null; });
    final prov = Provider.of<DocumentProvider>(context, listen: false);
    prov.clearSummaryCache(widget.document.id);
    final result = await prov.getSummary(widget.document.id);

    if (mounted) {
      if (result == null || result.startsWith('Error:')) {
        setState(() {
          _summaryError = result?.replaceFirst('Error:', '').trim().split('\n').first ?? 'AI service unavailable';
          _summaryLoading = false;
        });
      } else {
        setState(() { _summaryLoading = false; });
        _fetchRawSummary();
      }
    }
  }

  Future<void> _fetchRawSummary() async {
    setState(() { _summaryLoading = true; _summaryError = null; _summaryData = null; });
    try {
      final prov = Provider.of<DocumentProvider>(context, listen: false);
      final raw = await prov.getRawSummary(widget.document.id);
      if (mounted) {
        setState(() { _summaryData = raw; _summaryLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summaryError = e.toString().replaceAll('Exception: ', '');
          _summaryLoading = false;
        });
      }
    }
  }

  String _getSummaryText() {
    if (_summaryData == null) return '';
    final sums = _summaryData!['summaries'] ?? _summaryData;
    if (sums is Map) {
      switch (_activeSummaryTab) {
        case 0: return sums['brief']?.toString() ?? '';
        case 1: return sums['detailed']?.toString() ?? '';
        case 2: return sums['comprehensive']?.toString() ?? '';
      }
    }
    return _summaryData.toString();
  }

  List<String> _getTopics() {
    if (_summaryData == null) return widget.document.topics?.cast<String>() ?? [];
    return (_summaryData!['topics'] as List?)?.cast<String>() ?? widget.document.topics?.cast<String>() ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(widget.document.title, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.mutedText,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: AppTheme.borderColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.summarize_outlined, size: 18), text: 'Summary'),
            Tab(icon: Icon(Icons.quiz_outlined, size: 18), text: 'Quiz'),
            Tab(icon: Icon(Icons.style_outlined, size: 18), text: 'Flashcards'),
            Tab(icon: Icon(Icons.preview_outlined, size: 18), text: 'Preview'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          QuizScreen(documentId: widget.document.id, embedded: true),
          FlashcardScreen(documentId: widget.document.id, embedded: true),
          _buildPreviewTab(),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    if (_summaryLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Column(children: [
          ShimmerSkeleton(width: double.infinity, height: 14),
          SizedBox(height: 12),
          ShimmerSkeleton(width: double.infinity, height: 14),
          SizedBox(height: 12),
          ShimmerSkeleton(width: double.infinity, height: 14),
          SizedBox(height: 12),
          ShimmerSkeleton(width: 220, height: 14),
        ]),
      );
    }

    if (_summaryError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppTheme.errorColor, size: 48),
              const SizedBox(height: 16),
              const Text('AI Service Unavailable', style: TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 8),
              Text(_summaryError!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.greyText, height: 1.5, fontSize: 13)),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _fetchRawSummary,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_summaryData == null) {
      return Center(
        child: OutlinedButton.icon(
          onPressed: _fetchRawSummary,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Generate Summary'),
        ),
      );
    }

    final topics = _getTopics();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topics.isNotEmpty) ...[
            const Text('Topics Covered', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: topics.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(t, style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w500)),
              )).toList(),
            ),
            const SizedBox(height: 24),
          ],

          const Text('AI-Generated Summary', style: TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 14),

          // Tab selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                _summaryTypeBtn(0, 'Quick'),
                _summaryTypeBtn(1, 'Detailed'),
                _summaryTypeBtn(2, 'Comprehensive'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: TypewriterText(
              key: ValueKey(_activeSummaryTab),
              text: _getSummaryText().isNotEmpty ? _getSummaryText() : 'Summary not available for this type.',
              style: const TextStyle(color: AppTheme.greyText, height: 1.7, fontSize: 15),
              onComplete: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTypeBtn(int index, String label) {
    final isSelected = _activeSummaryTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeSummaryTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))] : [],
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppTheme.accent : AppTheme.mutedText,
              fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewTab() {
    final content = widget.document.content ?? widget.document.originalText ?? 'No content available.';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline_rounded, color: AppTheme.accent, size: 16),
                SizedBox(width: 8),
                Text('Original uploaded content', style: TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(content, style: const TextStyle(color: AppTheme.greyText, height: 1.8, fontSize: 14)),
        ],
      ),
    );
  }
}
