import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gamification_provider.dart';
import '../../utils/app_theme.dart';
import '../../core/constants.dart';
import '../login_screen.dart';

class ProfileScreenNew extends StatelessWidget {
  const ProfileScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final gam = context.watch<GamificationProvider>();
    final user = gam.user;

    final username = user?.username ?? auth.firebaseUser?.email?.split('@').first ?? 'Learner';
    final email = auth.firebaseUser?.email ?? '';
    final xp = user?.xp ?? 0;
    final level = user?.level ?? 1;
    final progress = user?.xpProgress ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () => context.read<GamificationProvider>().loadMyProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Avatar
              Center(child: Column(children: [
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF007A6E)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: Center(child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'S',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                  )),
                ),
                const SizedBox(height: 14),
                Text(username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: AppColors.secondary, fontSize: 14)),
                ],
              ])),

              const SizedBox(height: 24),

              // XP Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF007A6E)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Level', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('$xp / ${level * AppConstants.xpPerLevel} XP',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ]),
                  const SizedBox(height: 6),
                  Text('Level $level',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                  const SizedBox(height: 12),
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0), minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      )),
                  const SizedBox(height: 8),
                  Text('${user?.xpToNextLevel ?? AppConstants.xpPerLevel} XP to next level',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),

              const SizedBox(height: 20),

              // Stats grid
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
                children: [
                  _StatTile(label: 'Study Streak', value: '${user?.streak ?? 0}', unit: 'days', icon: Icons.local_fire_department_rounded, color: AppColors.streakOrange),
                  _StatTile(label: 'Quizzes Taken', value: '${user?.quizzesTaken ?? 0}', unit: 'total', icon: Icons.quiz_rounded, color: AppColors.accent),
                  _StatTile(label: 'Avg Accuracy', value: '${(user?.avgAccuracy ?? 0).toStringAsFixed(1)}', unit: '%', icon: Icons.track_changes_rounded, color: AppColors.success),
                  _StatTile(label: 'Total XP', value: '$xp', unit: 'pts', icon: Icons.bolt_rounded, color: AppColors.xpGold),
                ],
              ),

              const SizedBox(height: 24),

              // Account section
              Container(
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border)),
                child: Column(children: [
                  _MenuItem(icon: Icons.email_outlined, label: email.isEmpty ? 'Email not set' : email, onTap: null),
                  const Divider(height: 1, color: AppColors.border),
                  _MenuItem(icon: Icons.info_outline_rounded, label: 'App version 2.0.0', onTap: null),
                  const Divider(height: 1, color: AppColors.border),
                  _MenuItem(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    color: AppColors.error,
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Sign out?'),
                          content: const Text('You will need to sign in again.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sign Out', style: TextStyle(color: AppColors.error))),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await context.read<AuthProvider>().logout();
                        Navigator.pushAndRemoveUntil(context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
                      }
                    },
                  ),
                ]),
              ),

              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.unit, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 22),
      const Spacer(),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(width: 3),
        Padding(padding: const EdgeInsets.only(bottom: 2),
            child: Text(unit, style: const TextStyle(fontSize: 11, color: AppColors.secondary))),
      ]),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
    ]),
  );
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  const _MenuItem({required this.icon, required this.label, this.onTap, this.color});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color ?? AppColors.secondary, size: 22),
    title: Text(label, style: TextStyle(color: color ?? AppColors.primary, fontSize: 14)),
    trailing: onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20) : null,
    onTap: onTap,
  );
}
