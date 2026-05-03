import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/document_model.dart';
import '../../models/flashcard_model.dart';
import '../../providers/materials_provider.dart';
import '../../utils/app_theme.dart';

class FlashcardsScreen extends StatefulWidget {
  final DocumentModel document;
  const FlashcardsScreen({super.key, required this.document});
  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  List<FlashcardModel>? _cards;
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  final PageController _pageCtrl = PageController();

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final cards = await context.read<MaterialsProvider>().generateFlashcards(widget.document.id);
      if (!mounted) return;
      if (cards.isEmpty) {
        setState(() { _error = 'Could not generate flashcards. Check your Cerebras API key.'; _isLoading = false; });
      } else {
        setState(() { _cards = cards; _isLoading = false; });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.document.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (_cards != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${_currentIndex + 1}/${_cards!.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))),
            ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: AppColors.accent),
      SizedBox(height: 16),
      Text('Generating 15 flashcards… (+20 XP)', style: TextStyle(color: AppColors.secondary)),
    ]));

    if (_error != null) return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.secondary, fontSize: 13, height: 1.5)),
          ]),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
      ]),
    ));

    return Column(children: [
      const SizedBox(height: 8),
      const Text('Tap card to flip', style: TextStyle(color: AppColors.muted, fontSize: 13)),
      const SizedBox(height: 12),

      // Card viewer
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: _cards!.length,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SingleChildScrollView(
                  child: _FlipCard(card: _cards![i]),
                ),
              ),
            ),
          ),
        ),
      ),

      // Navigation
      Padding(
        padding: const EdgeInsets.all(24),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            onPressed: _currentIndex > 0
                ? () => _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                : null,
            icon: const Icon(Icons.arrow_back_ios_rounded),
            color: AppColors.accent,
            disabledColor: AppColors.border,
          ),
          const SizedBox(width: 24),
          // Dot indicators (show up to 15)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_cards!.length, (i) => GestureDetector(
                  onTap: () => _pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentIndex ? 24 : 8, height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentIndex ? AppColors.accent : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )),
              ),
            ),
          ),
          const SizedBox(width: 24),
          IconButton(
            onPressed: _currentIndex < _cards!.length - 1
                ? () => _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut)
                : null,
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            color: AppColors.accent,
            disabledColor: AppColors.border,
          ),
        ]),
      ),
    ]);
  }
}

class _FlipCard extends StatefulWidget {
  final FlashcardModel card;
  const _FlipCard({required this.card});
  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _anim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
  }

  @override
  void didUpdateWidget(_FlipCard old) {
    super.didUpdateWidget(old);
    if (old.card.id != widget.card.id) {
      _ctrl.reset();
      _showBack = false;
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _flip() {
    if (_ctrl.isAnimating) return;
    if (_showBack) {
      _ctrl.reverse();
    } else {
      _ctrl.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final angle = _anim.value * pi;
          final isFront = angle < pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: Stack(
              children: [
                // Render both faces invisibly to force the Stack to adopt the maximum height
                Visibility(
                  visible: false, maintainSize: true, maintainAnimation: true, maintainState: true,
                  child: _CardFace(text: widget.card.front, isBack: false),
                ),
                Visibility(
                  visible: false, maintainSize: true, maintainAnimation: true, maintainState: true,
                  child: _CardFace(text: widget.card.back, isBack: true),
                ),
                // The visible face is stretched to fill the maximum height via Positioned.fill
                Positioned.fill(
                  child: isFront
                      ? _CardFace(text: widget.card.front, isBack: false)
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(pi),
                          child: _CardFace(text: widget.card.back, isBack: true),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final String text;
  final bool isBack;
  const _CardFace({required this.text, required this.isBack});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 250),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isBack ? AppColors.accentLight : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isBack ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          Text(isBack ? 'Answer' : 'Question',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: isBack ? AppColors.accent : AppColors.muted, letterSpacing: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                    color: isBack ? AppColors.accent : AppColors.primary, height: 1.4)),
          ),
          Icon(Icons.touch_app_outlined, color: isBack ? AppColors.accent.withValues(alpha: 0.4) : AppColors.muted, size: 20),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
