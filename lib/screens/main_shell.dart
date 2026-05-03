import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/materials_provider.dart';
import '../providers/gamification_provider.dart';
import '../utils/app_theme.dart';
import 'home/home_screen.dart';
import 'materials/materials_screen.dart';
import 'chat/chat_screen_new.dart';
import 'leaderboard/leaderboard_screen.dart';
import 'profile/profile_screen_new.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  static const _tabs = [
    _TabItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _TabItem(Icons.library_books_rounded, Icons.library_books_outlined, 'Materials'),
    _TabItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat'),
    _TabItem(Icons.leaderboard_rounded, Icons.leaderboard_outlined, 'Leaderboard'),
    _TabItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onTabChange: (i) => setState(() => _tab = i)),
      const MaterialsScreen(),
      const ChatScreenNew(),
      const LeaderboardScreen(),
      const ProfileScreenNew(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GamificationProvider>().loadMyProfile();
      context.read<MaterialsProvider>().fetchDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      if (constraints.maxWidth > 720) return _buildDesktop(ctx);
      return _buildMobile();
    });
  }

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildDesktop(BuildContext ctx) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(children: [
        _buildRail(),
        const VerticalDivider(width: 1),
        Expanded(child: IndexedStack(index: _tab, children: _screens)),
      ]),
    );
  }

  Widget _buildRail() {
    return NavigationRail(
      backgroundColor: AppColors.surface,
      selectedIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(color: AppColors.accent),
      unselectedIconTheme: const IconThemeData(color: AppColors.muted),
      selectedLabelTextStyle: const TextStyle(
          color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelTextStyle:
          const TextStyle(color: AppColors.muted, fontSize: 12),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
              color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
        ),
      ),
      destinations: _tabs
          .map((t) => NavigationRailDestination(
                icon: Icon(t.iconOutlined),
                selectedIcon: Icon(t.icon),
                label: Text(t.label),
              ))
          .toList(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final t = _tabs[i];
              final sel = _tab == i;
              return GestureDetector(
                onTap: () => setState(() => _tab = i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 60,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(sel ? t.icon : t.iconOutlined,
                        color: sel ? AppColors.accent : AppColors.muted, size: 24),
                    const SizedBox(height: 3),
                    Text(t.label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                            color: sel ? AppColors.accent : AppColors.muted)),
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData iconOutlined;
  final String label;
  const _TabItem(this.icon, this.iconOutlined, this.label);
}
