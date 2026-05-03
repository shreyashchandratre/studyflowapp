import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gamification_provider.dart';
import '../../utils/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _searchCtrl = TextEditingController();
  Map<String, dynamic>? _compareResult;
  bool _isComparing = false;
  String? _compareError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationProvider>().loadLeaderboard();
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _compare(String username) async {
    if (username.trim().isEmpty) return;
    setState(() { _isComparing = true; _compareResult = null; _compareError = null; });
    final gam = context.read<GamificationProvider>();
    await gam.compareByUsername(username.trim());
    if (!mounted) return;
    setState(() {
      _compareResult = gam.compareResult;
      _isComparing = false;
      if (_compareResult == null) _compareError = 'User not found.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final gam = context.watch<GamificationProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: () => context.read<GamificationProvider>().loadLeaderboard(),
          ),
        ],
      ),
      body: SafeArea(child: CustomScrollView(slivers: [
        // Search / compare
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(children: [
            Row(children: [
              Expanded(child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Enter username to compare…',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted),
                ),
                onSubmitted: _compare,
              )),
              const SizedBox(width: 10),
              SizedBox(height: 52, child: ElevatedButton(
                onPressed: _isComparing ? null : () => _compare(_searchCtrl.text),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(72, 52), padding: const EdgeInsets.symmetric(horizontal: 16)),
                child: _isComparing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Compare'),
              )),
            ]),
            if (_compareError != null) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_compareError!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
            ),
            if (_compareResult != null) ...[
              const SizedBox(height: 16),
              _CompareCard(result: _compareResult!, myUsername: gam.user?.username ?? 'You'),
            ],
          ]),
        )),

        // Top 20 header
        const SliverToBoxAdapter(child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text('Top Learners', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.primary)),
        )),

        // List
        if (gam.isLoadingLeaderboard)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.accent)))
        else if (gam.leaderboard.isEmpty)
          const SliverFillRemaining(child: Center(
            child: Text('No leaderboard data yet.\nBe the first to earn XP!',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.secondary, fontSize: 14, height: 1.6)),
          ))
        else
          SliverList(delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final entry = gam.leaderboard[i];
              final isMe = entry['uid'] == gam.user?.uid || entry['username'] == gam.user?.username;
              return _LeaderRow(rank: i + 1, entry: entry, isMe: isMe,
                  onTap: () {
                    final un = entry['username']?.toString() ?? '';
                    if (un.isNotEmpty) { _searchCtrl.text = un; _compare(un); }
                  });
            },
            childCount: gam.leaderboard.length,
          )),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ])),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> entry;
  final bool isMe;
  final VoidCallback onTap;
  const _LeaderRow({required this.rank, required this.entry, required this.isMe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final username = entry['username']?.toString() ?? 'User';
    final xp = (entry['xp'] as num?)?.toInt() ?? 0;
    final streak = (entry['streak'] as num?)?.toInt() ?? 0;
    final medal = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '$rank';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isMe ? AppColors.accentLight : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isMe ? AppColors.accent : AppColors.border, width: isMe ? 1.5 : 1),
          ),
          child: Row(children: [
            SizedBox(width: 36, child: Text(medal,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: rank <= 3 ? 22 : 14, fontWeight: FontWeight.w700, color: AppColors.secondary))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(username, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 15)),
                if (isMe) const Padding(padding: EdgeInsets.only(left: 6),
                    child: Text('(You)', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 2),
              Text('🔥 $streak day streak', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$xp XP', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.accent, fontSize: 16)),
              Text('Lv ${xp ~/ 500 + 1}', style: const TextStyle(color: AppColors.muted, fontSize: 11)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final String myUsername;
  const _CompareCard({required this.result, required this.myUsername});

  @override
  Widget build(BuildContext context) {
    final me = result['currentUser'] as Map<String, dynamic>? ?? {};
    final them = result['comparedUser'] as Map<String, dynamic>? ?? {};
    final theirUsername = them['username']?.toString() ?? 'Them';

    int myVal(String k) => (me[k] as num?)?.toInt() ?? 0;
    int theirVal(String k) => (them[k] as num?)?.toInt() ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(myUsername, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 15)),
          const Text('VS', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.muted, fontSize: 13)),
          Text(theirUsername, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 15)),
        ]),
        const SizedBox(height: 14),
        const Divider(color: AppColors.border),
        const SizedBox(height: 10),
        _CmpRow(label: 'XP', myVal: myVal('xp'), theirVal: theirVal('xp'), suffix: 'XP'),
        _CmpRow(label: 'Streak', myVal: myVal('streak'), theirVal: theirVal('streak'), suffix: 'days'),
        _CmpRow(label: 'Quizzes', myVal: myVal('quizzesTaken'), theirVal: theirVal('quizzesTaken'), suffix: ''),
        _CmpRow(label: 'Accuracy', myVal: (me['avgAccuracy'] as num?)?.round() ?? 0,
            theirVal: (them['avgAccuracy'] as num?)?.round() ?? 0, suffix: '%'),
      ]),
    );
  }
}

class _CmpRow extends StatelessWidget {
  final String label;
  final int myVal, theirVal;
  final String suffix;
  const _CmpRow({required this.label, required this.myVal, required this.theirVal, required this.suffix});
  @override
  Widget build(BuildContext context) {
    final myWins = myVal >= theirVal;
    final theirWins = theirVal >= myVal;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 80, child: Text('$myVal$suffix',
            textAlign: TextAlign.left,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                color: myWins ? AppColors.accent : AppColors.secondary))),
        Expanded(child: Text(label, textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 13))),
        SizedBox(width: 80, child: Text('$theirVal$suffix',
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                color: theirWins ? AppColors.accent : AppColors.secondary))),
      ]),
    );
  }
}
