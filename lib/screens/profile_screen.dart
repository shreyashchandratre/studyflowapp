import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/stat_card.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const ProfileScreen({super.key, this.onMenuTap});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadMyProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProv = Provider.of<AuthProvider>(context);
    final userProv = Provider.of<UserProvider>(context);
    final profile = userProv.myProfile;

    // Use auth user data as primary source (always available after login)
    final name = authProv.user?['name']?.toString() ?? profile?.name ?? 'Student';
    final email = authProv.user?['email']?.toString() ?? profile?.email ?? '';
    final username = authProv.user?['username']?.toString() ?? profile?.username ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.onMenuTap),
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.accent),
            onPressed: () => userProv.loadMyProfile(),
          ),
        ],
      ),
      body: SafeArea(
        child: userProv.isLoading && profile == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => userProv.loadMyProfile(),
                color: AppTheme.accent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // ── Profile Header ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                        color: AppTheme.surfaceColor,
                        child: Column(
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(name,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.navyText)),
                            if (username.isNotEmpty)
                              Text('@$username', style: const TextStyle(color: AppTheme.greyText, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(email, style: const TextStyle(color: AppTheme.mutedText, fontSize: 13)),
                            const SizedBox(height: 18),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _followStat('Followers', '${profile?.followersCount ?? 0}'),
                                Container(width: 1, height: 30, color: AppTheme.borderColor, margin: const EdgeInsets.symmetric(horizontal: 28)),
                                _followStat('Following', '${profile?.followingCount ?? 0}'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1, color: AppTheme.borderColor),

                      // ── Primary Stats ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: StatCard(label: 'Total XP', value: '${profile?.xp ?? 0}', icon: Icons.bolt_rounded, color: const Color(0xFFD4A017))),
                                const SizedBox(width: 12),
                                Expanded(child: StatCard(label: 'Accuracy', value: '${(profile?.avgAccuracy ?? 0).toStringAsFixed(0)}%', icon: Icons.track_changes_rounded, color: const Color(0xFF27AE60))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: StatCard(label: 'Quizzes', value: '${profile?.quizzesTaken ?? 0}', icon: Icons.quiz_rounded, color: AppTheme.accent)),
                                const SizedBox(width: 12),
                                Expanded(child: StatCard(label: 'Streak', value: '${profile?.streak ?? 0}', icon: Icons.local_fire_department_rounded, color: const Color(0xFFE67E22))),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Study Statistics ──
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 28, 24, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Study Statistics', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.navyText)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Column(
                            children: [
                              _statRow(Icons.access_time_rounded, 'Study Hours', '${profile?.studyHours ?? 0}h', const Color(0xFF3B82F6)),
                              _divider(),
                              _statRow(Icons.book_outlined, 'Topics Studied', '${profile?.topicsStudied ?? 0}', AppTheme.accent),
                              _divider(),
                              _statRow(Icons.verified_outlined, 'Topics Mastered', '${profile?.topicsMastered ?? 0}', const Color(0xFF27AE60)),
                              _divider(),
                              _statRow(Icons.local_fire_department_outlined, 'Longest Streak', '${profile?.longestStreak ?? 0} days', const Color(0xFFE67E22)),
                              _divider(),
                              _statRow(Icons.stars_outlined, 'Avg Quiz Score', '${(profile?.avgQuizScore ?? 0).toStringAsFixed(0)}%', const Color(0xFFD4A017)),
                              _divider(),
                              _statRow(
                                Icons.calendar_today_outlined,
                                'Member Since',
                                profile != null ? DateFormat('MM/dd/yyyy').format(profile.memberSince) : '-',
                                const Color(0xFF5B6ABF),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _followStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.navyText)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.greyText, fontSize: 13)),
      ],
    );
  }

  Widget _statRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: AppTheme.greyText, fontSize: 14)),
          const Spacer(),
          Text(value, style: TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 1, indent: 18, endIndent: 18);
}
