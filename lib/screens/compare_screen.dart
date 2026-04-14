import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';

class CompareScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const CompareScreen({super.key, this.onMenuTap});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _compareUsername;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProv = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu_rounded), onPressed: widget.onMenuTap),
        title: const Text('Compare'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Find a Study Buddy', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.navyText)),
              const SizedBox(height: 4),
              const Text('Search by username and compare stats', style: TextStyle(color: AppTheme.greyText, fontSize: 14)),
              const SizedBox(height: 20),

              // ── Search Bar ──
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: AppTheme.navyText),
                      onChanged: (v) {
                        userProv.searchUsers(v);
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Search username...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.mutedText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      final q = _searchCtrl.text.trim();
                      if (q.isEmpty) return;
                      setState(() => _compareUsername = q);
                      userProv.compare(q);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),

              // ── Search suggestions ──
              if (userProv.isSearching)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_searchCtrl.text.length >= 2 && userProv.searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    children: userProv.searchResults.take(5).map((u) {
                      final name = u['name']?.toString() ?? '';
                      final uname = u['username']?.toString() ?? '';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.accentLight,
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600)),
                        ),
                        title: Text(name, style: const TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w500)),
                        subtitle: Text('@$uname', style: const TextStyle(color: AppTheme.mutedText, fontSize: 12)),
                        trailing: const Icon(Icons.compare_arrows_rounded, color: AppTheme.accent, size: 18),
                        onTap: () {
                          _searchCtrl.text = uname;
                          setState(() => _compareUsername = uname);
                          userProv.compare(uname);
                          FocusScope.of(context).unfocus();
                        },
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 28),

              // ── Compare Results ──
              if (userProv.isComparing)
                Center(child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text('Comparing stats...', style: TextStyle(color: AppTheme.mutedText)),
                  ]),
                ))
              else if (userProv.compareResult != null)
                _buildCompareResult(userProv)
              else
                _buildCompareEmpty(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompareEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppTheme.accentLight, shape: BoxShape.circle),
              child: const Icon(Icons.people_outline_rounded, color: AppTheme.accent, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('Compare with Others', style: TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Search for a classmate by username\nand see how your stats compare!',
                textAlign: TextAlign.center, style: TextStyle(color: AppTheme.greyText, height: 1.6)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareResult(UserProvider userProv) {
    final result = userProv.compareResult!;
    final me = result['currentUser'] ?? result['user1'] ?? result['me'] ?? {};
    final them = result['comparedUser'] ?? result['user2'] ?? result['other'] ?? {};

    String nameOf(Map m) => m['name']?.toString() ?? m['username']?.toString() ?? '?';
    num valueOf(Map m, String key) {
      final v = m[key];
      if (v is num) return v;
      if (v is String) return num.tryParse(v) ?? 0;
      return 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('You vs @$_compareUsername', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.navyText)),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(child: _userHeader(nameOf(me as Map), isMe: true)),
            const SizedBox(width: 8),
            const Text('VS', style: TextStyle(color: AppTheme.mutedText, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Expanded(child: _userHeader(nameOf(them as Map), isMe: false)),
          ],
        ),
        const SizedBox(height: 20),

        ...[
          ['XP Points', 'xp'],
          ['Study Streak', 'streak'],
          ['Quizzes Taken', 'quizzesTaken'],
          ['Avg Accuracy', 'avgAccuracy'],
        ].map((row) {
          final label = row[0];
          final key = row[1];
          final myVal = valueOf(me as Map, key);
          final theirVal = valueOf(them as Map, key);
          final total = myVal + theirVal;
          final myFrac = total == 0 ? 0.5 : myVal / total;
          return _compareRow(label, myVal, theirVal, myFrac.toDouble());
        }),
      ],
    );
  }

  Widget _userHeader(String name, {required bool isMe}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isMe ? AppTheme.accent.withOpacity(0.4) : AppTheme.borderColor),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: isMe ? AppTheme.accent : AppTheme.bgColor,
            radius: 22,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: isMe ? Colors.white : AppTheme.navyText, fontWeight: FontWeight.w600, fontSize: 18)),
          ),
          const SizedBox(height: 8),
          Text(name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w600, fontSize: 13)),
          if (isMe) const Text('You', style: TextStyle(color: AppTheme.accent, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _compareRow(String label, num myVal, num theirVal, double myFraction) {
    final myWins = myVal >= theirVal;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.greyText, fontSize: 13, fontWeight: FontWeight.w500)),
              Text(myWins ? 'You lead' : 'They lead',
                  style: TextStyle(fontSize: 11, color: myWins ? AppTheme.accent : AppTheme.mutedText, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('${myVal.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 15)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Stack(
                    children: [
                      Container(height: 6, decoration: BoxDecoration(color: AppTheme.borderColor, borderRadius: BorderRadius.circular(10))),
                      FractionallySizedBox(
                        widthFactor: myFraction,
                        child: Container(height: 6, decoration: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(10),
                        )),
                      ),
                    ],
                  ),
                ),
              ),
              Text('${theirVal.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.navyText, fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
