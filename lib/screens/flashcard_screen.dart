import 'package:flutter/material.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';

class FlashcardScreen extends StatefulWidget {
  final String documentId;
  final bool embedded;

  const FlashcardScreen({super.key, required this.documentId, this.embedded = false});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<dynamic>? _flashcards;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFlashcards();
  }

  Future<void> _fetchFlashcards() async {
    setState(() { _isLoading = true; _errorMessage = null; _flashcards = null; });
    final provider = Provider.of<DocumentProvider>(context, listen: false);
    final flashcards = await provider.generateFlashcards(widget.documentId);
    if (mounted) {
      if (flashcards == null || flashcards.isEmpty) {
        final err = provider.errorMessage;
        setState(() {
          _errorMessage = err != null && err.isNotEmpty
              ? err.split('\n').where((l) => l.trim().isNotEmpty).first.trim()
              : 'Could not generate flashcards. The AI service may be unavailable.';
          _isLoading = false;
        });
      } else {
        Provider.of<UserProvider>(context, listen: false).addXp(5);
        setState(() { _flashcards = flashcards; _isLoading = false; });
      }
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Generating flashcards...', style: TextStyle(color: AppTheme.mutedText, fontSize: 14)),
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
          OutlinedButton.icon(onPressed: _fetchFlashcards, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
        ]),
      ));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_flashcards!.length} cards', style: const TextStyle(color: AppTheme.mutedText, fontSize: 13)),
              const Text('Tap card to flip', style: TextStyle(color: AppTheme.mutedText, fontSize: 13)),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            itemCount: _flashcards!.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: FlipCard(
                    frontText: _flashcards![index]['front'] ?? _flashcards![index]['question'] ?? '',
                    backText: _flashcards![index]['back'] ?? _flashcards![index]['answer'] ?? '',
                    cardIndex: index + 1,
                    total: _flashcards!.length,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildBody();

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(title: const Text('Flashcards')),
      body: SafeArea(child: _buildBody()),
    );
  }
}

class FlipCard extends StatefulWidget {
  final String frontText;
  final String backText;
  final int cardIndex;
  final int total;

  const FlipCard({super.key, required this.frontText, required this.backText, required this.cardIndex, required this.total});

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _flip() {
    _isFront ? _controller.forward() : _controller.reverse();
    _isFront = !_isFront;
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final isBackShowing = _animation.value > 0.5;
          final angle = _animation.value * pi;
          return Transform(
            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.55,
              decoration: BoxDecoration(
                color: isBackShowing ? AppTheme.accentLight : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isBackShowing ? AppTheme.accent.withOpacity(0.3) : AppTheme.borderColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Transform(
                transform: Matrix4.identity()..rotateY(isBackShowing ? pi : 0),
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    // Card counter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${widget.cardIndex} / ${widget.total}',
                          style: const TextStyle(color: AppTheme.mutedText, fontSize: 11, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 24),
                    Icon(
                      isBackShowing ? Icons.lightbulb_outline_rounded : Icons.help_outline_rounded,
                      color: isBackShowing ? const Color(0xFFD4A017) : AppTheme.accent, size: 40,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isBackShowing ? widget.backText : widget.frontText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.navyText,
                        fontSize: isBackShowing ? 17 : 20,
                        fontWeight: isBackShowing ? FontWeight.w500 : FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.touch_app_rounded, size: 14, color: AppTheme.mutedText),
                      const SizedBox(width: 6),
                      Text(isBackShowing ? 'Tap to see question' : 'Tap to reveal answer',
                          style: const TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                    ]),
                  ]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
