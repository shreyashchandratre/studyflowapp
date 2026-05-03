import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/document_model.dart';
import '../../providers/materials_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../services/firebase_service.dart';
import '../../utils/app_theme.dart';
import '../../core/constants.dart';

class QuizScreenNew extends StatefulWidget {
  final DocumentModel document;
  const QuizScreenNew({super.key, required this.document});
  @override
  State<QuizScreenNew> createState() => _QuizScreenNewState();
}

class _QuizScreenNewState extends State<QuizScreenNew> {
  List<Map<String, dynamic>>? _questions;
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedIdx;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() { _isLoading = true; _error = null; _questions = null; _currentIndex = 0; _score = 0; _answered = false; _selectedIdx = null; });
    final prov = context.read<MaterialsProvider>();
    final q = await prov.generateQuiz(widget.document.id);
    if (!mounted) return;
    if (q == null || q.isEmpty) {
      setState(() { _error = prov.errorMessage ?? 'Could not generate quiz. Check your Cerebras API key.'; _isLoading = false; });
    } else {
      setState(() { _questions = q; _isLoading = false; });
    }
  }

  void _answer(int idx) {
    if (_answered) return;
    final q = _questions![_currentIndex];
    final correct = (q['answer'] ?? q['correctAnswer']).toString();
    final opts = q['options'] as List;
    final isCorrect = opts[idx].toString() == correct;
    setState(() { _selectedIdx = idx; _answered = true; if (isCorrect) _score++; });
  }

  void _next() {
    if (_currentIndex < _questions!.length - 1) {
      setState(() { _currentIndex++; _answered = false; _selectedIdx = null; });
    } else {
      _showResults();
    }
  }

  void _showResults() {
    final total = _questions!.length;
    final accuracy = total > 0 ? (_score / total * 100).round() : 0;
    final xp = _score * AppConstants.xpPerCorrect;

    // Write to Firestore
    FirebaseService().recordQuizResult(correctAnswers: _score, totalQuestions: total);
    context.read<GamificationProvider>().refreshUser();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          const Text('Quiz Complete!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 16),
          _ResultRow(label: 'Score', value: '$_score / $total'),
          _ResultRow(label: 'Accuracy', value: '$accuracy%'),
          _ResultRow(label: 'XP Earned', value: '+$xp XP', valueColor: AppColors.accent),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Done'),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () { Navigator.pop(context); _loadQuiz(); },
              child: const Text('Retry'),
            )),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.document.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: AppColors.accent),
      SizedBox(height: 16),
      Text('Generating 10 questions…', style: TextStyle(color: AppColors.secondary)),
    ]));

    if (_error != null) return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.2))),
          child: Column(children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            const Text('Could not generate quiz', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.secondary, fontSize: 13, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: _loadQuiz, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
      ]),
    ));

    final q = _questions![_currentIndex];
    final opts = (q['options'] as List).map((e) => e.toString()).toList();
    final correct = (q['answer'] ?? q['correctAnswer']).toString();
    final explanation = q['explanation']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Progress
        Row(children: [
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions!.length, minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          )),
          const SizedBox(width: 12),
          Text('${_currentIndex + 1}/${_questions!.length}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14)),
        ]),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight,
            child: Text('Score: $_score', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 13))),
        const SizedBox(height: 20),

        Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border)),
            child: Text(q['question']?.toString() ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary, height: 1.4)),
          ),
          const SizedBox(height: 20),

          ...List.generate(opts.length, (i) {
            final opt = opts[i];
            final isCorrect = opt == correct;
            Color bg = AppColors.surface;
            Color border = AppColors.border;
            Widget? trail;
            if (_answered) {
              if (isCorrect) { bg = AppColors.success.withValues(alpha: 0.1); border = AppColors.success; trail = const Icon(Icons.check_circle_rounded, color: AppColors.success); }
              else if (_selectedIdx == i) { bg = AppColors.error.withValues(alpha: 0.08); border = AppColors.error; trail = const Icon(Icons.cancel_rounded, color: AppColors.error); }
            } else if (_selectedIdx == i) {
              border = AppColors.accent;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _answer(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: bg, border: Border.all(color: border, width: 1.5), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Expanded(child: Text(opt, style: const TextStyle(color: AppColors.primary, fontSize: 15))),
                    if (trail != null) trail,
                  ]),
                ),
              ),
            );
          }),

          if (_answered && explanation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Explanation', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                Text(explanation, style: const TextStyle(color: AppColors.primary, height: 1.5)),
              ]),
            ),
          ],
        ]))),

        if (_answered) ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _next,
              child: Text(_currentIndex < _questions!.length - 1 ? 'Next Question →' : 'Finish Quiz 🎉'),
            ),
          ),
        ],
      ]),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _ResultRow({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppColors.secondary, fontSize: 14)),
        Text(value, style: TextStyle(color: valueColor ?? AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
      ]),
    );
  }
}
