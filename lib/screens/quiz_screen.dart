import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';

class QuizScreen extends StatefulWidget {
  final String documentId;
  final bool embedded;

  const QuizScreen({super.key, required this.documentId, this.embedded = false});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic>? _questions;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentIndex = 0;
  int _score = 0;
  bool _showExplanation = false;
  int? _selectedAnswerIndex;

  @override
  void initState() {
    super.initState();
    _fetchQuiz();
  }

  Future<void> _fetchQuiz() async {
    setState(() { _isLoading = true; _errorMessage = null; _questions = null; _currentIndex = 0; _score = 0; _showExplanation = false; _selectedAnswerIndex = null; });
    final provider = Provider.of<DocumentProvider>(context, listen: false);
    final quiz = await provider.generateQuiz(widget.documentId);
    if (mounted) {
      if (quiz == null || quiz.isEmpty) {
        final err = provider.errorMessage;
        setState(() {
          _errorMessage = err != null && err.isNotEmpty
              ? err.split('\n').where((l) => l.trim().isNotEmpty).first.trim()
              : 'Could not generate quiz. The AI service may be unavailable.';
          _isLoading = false;
        });
      } else {
        setState(() { _questions = quiz; _isLoading = false; });
      }
    }
  }

  void _answerQuestion(int index) {
    if (_showExplanation) return;
    final question = _questions![_currentIndex];
    final actualAnswer = question['correctAnswer'] ?? question['answer'];
    final isCorrect = question['options'][index] == actualAnswer;
    setState(() { _selectedAnswerIndex = index; if (isCorrect) _score++; _showExplanation = true; });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions!.length - 1) {
      setState(() { _currentIndex++; _showExplanation = false; _selectedAnswerIndex = null; });
    } else {
      _showResultsDialog();
    }
  }

  void _showResultsDialog() {
    // Award XP and track quiz completion
    final userProv = Provider.of<UserProvider>(context, listen: false);
    userProv.addXp(5);
    userProv.incrementQuizzesTaken();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quiz Complete! 🎉', style: TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w700)),
        content: Text('You scored $_score out of ${_questions!.length}!', style: const TextStyle(color: AppTheme.greyText)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
          TextButton(onPressed: () { Navigator.of(context).pop(); _fetchQuiz(); }, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Generating quiz...', style: TextStyle(color: AppTheme.mutedText, fontSize: 14)),
        ],
      ));
    }

    if (_errorMessage != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
            ),
            child: Column(children: [
              const Icon(Icons.cloud_off_rounded, color: AppTheme.errorColor, size: 48),
              const SizedBox(height: 16),
              const Text('AI Service Unavailable', style: TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w700, fontSize: 17)),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.greyText, height: 1.5, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(onPressed: _fetchQuiz, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
        ]),
      ));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions!.length,
            backgroundColor: AppTheme.borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accent),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 24),
        Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Question ${_currentIndex + 1} of ${_questions!.length}',
              style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 12),
          Text(_questions![_currentIndex]['question'] ?? '',
              style: const TextStyle(fontSize: 20, color: AppTheme.navyText, fontWeight: FontWeight.w600, height: 1.4)),
          const SizedBox(height: 24),

          // Options
          ...List.generate((_questions![_currentIndex]['options'] as List).length, (index) {
            final option = _questions![_currentIndex]['options'][index];
            final qItem = _questions![_currentIndex];
            final actualAnswer = qItem['correctAnswer'] ?? qItem['answer'];
            final isCorrectAnswer = option == actualAnswer;

            Color getBorderColor() {
              if (!_showExplanation) return AppTheme.borderColor;
              if (isCorrectAnswer) return const Color(0xFF27AE60);
              if (_selectedAnswerIndex == index) return AppTheme.errorColor;
              return AppTheme.borderColor;
            }
            Color getBgColor() {
              if (!_showExplanation) return AppTheme.surfaceColor;
              if (isCorrectAnswer) return const Color(0xFF27AE60).withOpacity(0.08);
              if (_selectedAnswerIndex == index) return AppTheme.errorColor.withOpacity(0.06);
              return AppTheme.surfaceColor;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _answerQuestion(index),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: getBgColor(),
                    border: Border.all(color: getBorderColor(), width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(option.toString(), style: const TextStyle(color: AppTheme.navyText, fontSize: 15))),
                    if (_showExplanation && isCorrectAnswer) const Icon(Icons.check_circle_rounded, color: Color(0xFF27AE60)),
                    if (_showExplanation && _selectedAnswerIndex == index && !isCorrectAnswer) const Icon(Icons.cancel_rounded, color: AppTheme.errorColor),
                  ]),
                ),
              ),
            );
          }),

          // Explanation
          if (_showExplanation) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Explanation', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Text(_questions![_currentIndex]['explanation'] ?? 'This was the correct answer.',
                    style: const TextStyle(color: AppTheme.greyText, height: 1.5)),
              ]),
            ),
          ],
        ]))),
        const SizedBox(height: 16),
        if (_showExplanation)
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _nextQuestion,
              child: Text(_currentIndex < _questions!.length - 1 ? 'Next Question →' : 'Finish Quiz 🎉',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody();

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: const Text('Quiz')),
      body: SafeArea(child: _buildBody()),
    );
  }
}
