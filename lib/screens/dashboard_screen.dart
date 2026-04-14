import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/document_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/stat_card.dart';
import 'content_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const DashboardScreen({super.key, this.onMenuTap});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
    final docProv = Provider.of<DocumentProvider>(context);
    final profile = userProv.myProfile;

    // Use the logged-in user's real name
    final userName = authProv.user?['name']?.toString().split(' ').first
        ?? profile?.name.split(' ').first
        ?? 'Student';

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.onMenuTap),
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.accent),
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).loadMyProfile();
              Provider.of<DocumentProvider>(context, listen: false).fetchDocuments();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: userProv.isLoading && profile == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await Provider.of<UserProvider>(context, listen: false).loadMyProfile();
                  await Provider.of<DocumentProvider>(context, listen: false).fetchDocuments();
                },
                color: AppTheme.accent,
                child: CustomScrollView(
                  slivers: [
                    // ── Greeting ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hey $userName 👋',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.navyText),
                            ),
                            const SizedBox(height: 4),
                            const Text("Here's your study overview", style: TextStyle(color: AppTheme.greyText, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),

                    // ── XP Progress ──
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('XP Points', style: TextStyle(color: AppTheme.greyText, fontSize: 13)),
                                        Text(
                                          '${profile?.xp ?? 0} XP',
                                          style: const TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w700, fontSize: 15),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: ((profile?.xp ?? 0) % 100) / 100,
                                        backgroundColor: AppTheme.borderColor,
                                        valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Level ${((profile?.xp ?? 0) ~/ 100) + 1}',
                                      style: const TextStyle(color: AppTheme.mutedText, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Stats Grid ──
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15,
                        ),
                        delegate: SliverChildListDelegate([
                          StatCard(label: 'Study Streak', value: '${profile?.streak ?? 0} days', icon: Icons.local_fire_department_rounded, color: const Color(0xFFE67E22)),
                          StatCard(label: 'Quizzes Taken', value: '${profile?.quizzesTaken ?? 0}', icon: Icons.quiz_rounded, color: AppTheme.accent),
                          StatCard(label: 'Avg Quiz Score', value: '${(profile?.avgQuizScore ?? 0).toStringAsFixed(0)}%', icon: Icons.track_changes_rounded, color: const Color(0xFF27AE60)),
                          StatCard(label: 'Materials', value: '${docProv.documents.length}', icon: Icons.library_books_rounded, color: const Color(0xFF5B6ABF)),
                        ]),
                      ),
                    ),

                    // ── Recent Activity Header ──
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 28, 24, 12),
                        child: Text('Recent Materials', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.navyText)),
                      ),
                    ),

                    // ── Recent Documents ──
                    if (docProv.documents.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('No materials uploaded yet', style: TextStyle(color: AppTheme.mutedText))),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= 5) return null;
                            final doc = docProv.documents[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                              child: GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ContentDetailScreen(document: doc))),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppTheme.borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42, height: 42,
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentLight,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.description_outlined, color: AppTheme.accent, size: 20),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(doc.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w600, fontSize: 14)),
                                            const SizedBox(height: 3),
                                            Text(DateFormat('MMM dd, yyyy').format(doc.createdAt),
                                                style: const TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedText, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: docProv.documents.length > 5 ? 5 : docProv.documents.length,
                        ),
                      ),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
      ),
    );
  }
}
