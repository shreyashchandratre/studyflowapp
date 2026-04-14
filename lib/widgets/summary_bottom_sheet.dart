import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../utils/app_theme.dart';
import 'shimmer_skeleton.dart';
import 'typewriter_text.dart';

class SummaryBottomSheet extends StatefulWidget {
  final String documentId;

  const SummaryBottomSheet({Key? key, required this.documentId}) : super(key: key);

  @override
  State<SummaryBottomSheet> createState() => _SummaryBottomSheetState();
}

class _SummaryBottomSheetState extends State<SummaryBottomSheet> {
  String? _summary;
  bool _isLoading = true;
  bool _typingEnded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() { _isLoading = true; _errorMessage = null; _summary = null; _typingEnded = false; });
    final provider = Provider.of<DocumentProvider>(context, listen: false);
    final result = await provider.getSummary(widget.documentId);

    if (mounted) {
      if (result != null && result.startsWith('Error:')) {
        final raw = result.replaceFirst('Error:', '').trim();
        final firstLine = raw.split('\n').where((l) => l.trim().isNotEmpty).first.trim();
        setState(() {
          _errorMessage = firstLine.isNotEmpty ? firstLine : 'AI service is currently unavailable.';
          _isLoading = false;
        });
      } else {
        setState(() { _summary = result; _isLoading = false; });
      }
    }
  }

  void _copyToClipboard() {
    if (_summary != null) {
      Clipboard.setData(ClipboardData(text: _summary!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Summary copied to clipboard!")),
      );
    }
  }

  void _retry() {
    final provider = Provider.of<DocumentProvider>(context, listen: false);
    provider.clearSummaryCache(widget.documentId);
    _fetchSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              height: 4, width: 40,
              decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppTheme.accent, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'AI Summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.navyText),
                  ),
                ],
              ),
              if (!_isLoading && _errorMessage == null)
                OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accent,
                    side: const BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerSkeleton(width: double.infinity, height: 14),
                SizedBox(height: 12),
                ShimmerSkeleton(width: double.infinity, height: 14),
                SizedBox(height: 12),
                ShimmerSkeleton(width: double.infinity, height: 14),
                SizedBox(height: 12),
                ShimmerSkeleton(width: 200, height: 14),
              ],
            )
          else if (_errorMessage != null)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: AppTheme.errorColor, size: 40),
                      const SizedBox(height: 14),
                      const Text('AI Service Unavailable',
                          style: TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(_errorMessage!, textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.greyText, height: 1.5, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ),
              ],
            )
          else
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: SingleChildScrollView(
                child: TypewriterText(
                  text: _summary ?? 'Could not fetch summary.',
                  style: const TextStyle(fontSize: 15, height: 1.7, color: AppTheme.greyText),
                  onComplete: () => setState(() => _typingEnded = true),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
