import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../providers/document_provider.dart';
import '../providers/chat_provider.dart';
import '../screens/login_screen.dart';
import '../utils/app_theme.dart';
import 'dashboard_screen.dart';
import 'content_screen.dart';
import 'flashcard_topics_screen.dart';
import 'chat_screen.dart';
import 'compare_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    _NavItem(icon: Icons.library_books_outlined, label: 'Content'),
    _NavItem(icon: Icons.style_outlined, label: 'Flashcards'),
    _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chat with AI'),
    _NavItem(icon: Icons.compare_arrows_outlined, label: 'Compare'),
    _NavItem(icon: Icons.person_outline_rounded, label: 'My Profile'),
  ];

  late final List<Widget> _screens;

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onMenuTap: _openDrawer),
      ContentScreen(onMenuTap: _openDrawer),
      FlashcardTopicsScreen(onMenuTap: _openDrawer),
      ChatScreen(onMenuTap: _openDrawer),
      CompareScreen(onMenuTap: _openDrawer),
      ProfileScreen(onMenuTap: _openDrawer),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadMyProfile();
      Provider.of<DocumentProvider>(context, listen: false).fetchDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.bgColor,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      drawer: _buildDrawer(context),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userProv = Provider.of<UserProvider>(context, listen: false);
    final profile = userProv.myProfile;
    final name = auth.user?['name']?.toString() ?? profile?.name ?? 'Student';
    final username = auth.user?['username']?.toString() ?? profile?.username ?? '';
    final xp = profile?.xp ?? 0;

    return Drawer(
      backgroundColor: AppTheme.drawerBg,
      child: SafeArea(
        child: Column(
          children: [
            // ── Profile Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accent,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                  if (username.isNotEmpty)
                    Text('@$username', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
                  const SizedBox(height: 10),
                  // XP badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$xp XP',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Nav Items ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: _navItems.length,
                itemBuilder: (context, index) {
                  final item = _navItems[index];
                  final isSelected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected ? AppTheme.accent : Colors.white.withOpacity(0.4),
                        size: 22,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: AppTheme.accent.withOpacity(0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),

            // ── Logout ──
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: Colors.white.withOpacity(0.5), size: 22),
                title: Text('Logout', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onTap: () async {
                  await Provider.of<AuthProvider>(context, listen: false).logout();
                  if (context.mounted) {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

mixin DrawerOpener<T extends StatefulWidget> on State<T> {
  void openDrawer() => Scaffold.of(context).openDrawer();
}
