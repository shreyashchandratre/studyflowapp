import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/document_model.dart';
import '../../providers/materials_provider.dart';
import '../../utils/app_theme.dart';

class SummaryScreen extends StatefulWidget {
  final DocumentModel document;
  const SummaryScreen({super.key, required this.document});
  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  static const _modes = ['Brief', 'Detailed', 'Comprehensive'];
  int _modeIdx = 1; // default: Detailed
  Map<String, String>? _summaries;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _summaries = await context.read<MaterialsProvider>().getSummaries(widget.document.id);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _currentKey {
    switch (_modeIdx) {
      case 0: return 'brief';
      case 2: return 'comprehensive';
      default: return 'detailed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.document.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: () {
              context.read<MaterialsProvider>().clearSummaryCache(widget.document.id);
              _load();
            },
          ),
        ],
      ),
      body: SafeArea(child: Column(children: [
        // Mode selector
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: AppColors.border.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
            child: Row(children: List.generate(_modes.length, (i) {
              final sel = _modeIdx == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _modeIdx = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(_modes[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13,
                            color: sel ? Colors.white : AppColors.secondary)),
                  ),
                ),
              );
            })),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildContent()),
      ])),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: AppColors.accent),
      SizedBox(height: 16),
      Text('Generating summary…', style: TextStyle(color: AppColors.secondary)),
    ]));

    if (_error != null) return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
        const SizedBox(height: 12),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.secondary, height: 1.5)),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
      ]),
    ));

    String text = _summaries?[_currentKey] ?? 'Summary not available.';
    text = text.trim();
    if (text.startsWith('["') && text.endsWith('"]')) {
      text = text.substring(2, text.length - 2).trim();
    } else if (text.startsWith('[') && text.endsWith(']')) {
      text = text.substring(1, text.length - 1).trim();
    }
    if (text.startsWith('"') && text.endsWith('"')) {
      text = text.substring(1, text.length - 1).trim();
    }
    text = text.replaceAll(r'\"', '"').replaceAll(r'\n', '\n');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Mode badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(8)),
          child: Text('${_modes[_modeIdx]} Summary',
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
          ),
          child: SelectableText(text,
              style: const TextStyle(color: AppColors.primary, fontSize: 15, height: 1.7)),
        ),
      ]),
    );
  }
}
