import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/materials_provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../core/constants.dart';
import '../materials/document_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int)? onTabChange;
  const HomeScreen({super.key, this.onTabChange});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationProvider>().loadMyProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationProvider>();
    final auth = context.watch<AuthProvider>();
    final docs = context.watch<MaterialsProvider>();
    final user = gam.user;
    final firstName = user?.username.split(' ').first ??
        auth.firebaseUser?.email?.split('@').first ?? 'Learner';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            await context.read<GamificationProvider>().loadMyProfile();
            await context.read<MaterialsProvider>().fetchDocuments();
          },
          child: CustomScrollView(slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              floating: true, elevation: 0,
              title: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text('StudyFlow', style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ]),
            ),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hey $firstName 👋', style: GoogleFonts.plusJakartaSans(
                    fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 4),
                Text('Ready to level up your studies?',
                    style: const TextStyle(fontSize: 14, color: AppColors.secondary)),
              ]),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _XpCard(user: user),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15,
                children: [
                  _StatCard(label: 'Study Streak', value: '${user?.streak ?? 0}', unit: 'days',
                      icon: Icons.local_fire_department_rounded, color: AppColors.streakOrange),
                  _StatCard(label: 'Quizzes Taken', value: '${user?.quizzesTaken ?? 0}', unit: 'total',
                      icon: Icons.quiz_rounded, color: AppColors.accent),
                  _StatCard(label: 'Avg Accuracy', value: '${(user?.avgAccuracy ?? 0).toStringAsFixed(0)}', unit: '%',
                      icon: Icons.track_changes_rounded, color: AppColors.success),
                  _StatCard(label: 'Materials', value: '${docs.documents.length}', unit: 'docs',
                      icon: Icons.library_books_rounded, color: const Color(0xFF7C5CBF)),
                ],
              ),
            )),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _ActionBtn(label: 'Upload Material', icon: Icons.upload_file_rounded,
                      onTap: () => widget.onTabChange?.call(1))),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionBtn(label: 'Chat with AI', icon: Icons.chat_bubble_outline_rounded,
                      onTap: () => widget.onTabChange?.call(2))),
                ]),
              ]),
            )),
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Text('Recent Materials', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary)),
            )),
            if (docs.documents.isEmpty)
              const SliverToBoxAdapter(child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('No materials yet. Upload a PDF or text to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.secondary, fontSize: 14))),
              ))
            else
              SliverList(delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  if (i >= 5) return null;
                  final doc = docs.documents[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: GestureDetector(
                      onTap: () => Navigator.push(ctx, MaterialPageRoute(
                          builder: (_) => DocumentDetailScreen(document: doc))),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border)),
                        child: Row(children: [
                          Container(width: 40, height: 40,
                              decoration: BoxDecoration(color: AppColors.accentLight,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.description_outlined, color: AppColors.accent, size: 20)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(DateFormat('MMM dd, yyyy').format(doc.createdAt),
                                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                          ])),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
                        ]),
                      ),
                    ),
                  );
                },
                childCount: docs.documents.length > 5 ? 5 : docs.documents.length,
              )),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ]),
        ),
      ),
    );
  }
}

class _XpCard extends StatelessWidget {
  final UserModel? user;
  const _XpCard({this.user});
  @override
  Widget build(BuildContext context) {
    final xp = user?.xp ?? 0;
    final level = user?.level ?? 1;
    final progress = user?.xpProgress ?? 0.0;
    final toNext = user?.xpToNextLevel ?? AppConstants.xpPerLevel;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF007A6E)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Total XP', style: TextStyle(color: Colors.white70, fontSize: 13)),
            Text('$xp XP', style: GoogleFonts.plusJakartaSans(
                fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
            child: Text('Level $level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0), minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text('$toNext XP to Level ${level + 1}',
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.unit, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20)),
        const Spacer(),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(width: 3),
          Padding(padding: const EdgeInsets.only(bottom: 3),
              child: Text(unit, style: const TextStyle(fontSize: 12, color: AppColors.secondary))),
        ]),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      ),
    );
  }
}
