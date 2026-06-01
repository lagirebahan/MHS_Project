import 'package:flutter/material.dart';
import 'package:my_app/pages/drawer/profile_page.dart';
import 'package:my_app/pages/drawer/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/pages/home_page.dart';
import 'package:my_app/pages/products_page.dart';
import 'package:my_app/pages/cart_page.dart';
import 'package:provider/provider.dart';
import 'package:my_app/theme/app_theme.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  String _userName = 'User';
  String _email = '';
  bool _isAdmin = false;
  String? _pendingCategory;
  

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  static const categoryMap = {
    'Weapons': 'Weapons',
    'Echoes': 'Echoes',
    'Materials': 'Materials',
    'Consumables': 'Consumables',
    'Special': 'Special',
  };

  List<Widget> get _pages => [
    HomePage(
      onSeeAll: () => setState(() {
        _pendingCategory = null;
        _currentIndex = 1;
      }),
      onCategoryTap: (category) => setState(() {
        _pendingCategory = categoryMap[category];
        _currentIndex = 1;
      }),
    ),
    ProductsPage(
      key: ValueKey(_pendingCategory),
      initialCategory: _pendingCategory,
      onCategoryChanged: (category) {
        setState(() {
          _pendingCategory = category == 'All' ? null : category;
        });
      },
    ),
    const CartPage(),
  ];

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User';
      _email = prefs.getString('email') ?? '';
      _isAdmin = (prefs.getString('role') ?? 'user') == 'admin';
    });
  }

  void _showLogoutDialog(BuildContext context, AppTheme theme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.surfaceBg,
          title: Text('Confirm Logout',
              style: theme.baseTextStyle(theme.primaryTextColor)),
          content: Text('Are you sure you want to logout?',
              style: theme.baseTextStyle(Colors.grey[500]!)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: theme.baseTextStyle(Colors.grey[500]!)),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: Text('Logout',
                  style: theme.baseTextStyle(Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Scaffold(
      backgroundColor: theme.baseBg,
      appBar: AppBar(
        backgroundColor:theme.baseBg,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/images/LogoWaresForDarkBg.png', height: 28),
        iconTheme: IconThemeData(color: theme.primaryTextColor),
        actions: [
          if (_currentIndex == 2)
            const SizedBox(width: 48)
          else
            IconButton(
              icon: Icon(Icons.shopping_cart_outlined, color: theme.primaryTextColor),
              onPressed: () => setState(() => _currentIndex = 2),
            ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: theme.baseBg,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              decoration: BoxDecoration(
                color: theme.surfaceBg,
                border: Border(
                  bottom: BorderSide(color: theme.borderColor, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.borderColor,
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: theme.baseTextStyle(
                          theme.primaryTextColor,).copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_userName,
                      style: TextStyle(
                          color: theme.primaryTextColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  if (_email.isNotEmpty)
                    Text(_email,
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 13)),
                  if (_isAdmin)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.blueAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Text('Admin',
                          style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _drawerItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    theme: theme,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfilePage()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    theme: theme,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                  if (_isAdmin) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(color: theme.borderColor),
                    ),
                    _drawerItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Admin Panel',
                      theme: theme,
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/admin');
                      },
                    ),
                  ],

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: theme.borderColor),
                  ),

                  _drawerItem(
                    icon: Icons.logout,
                    label: 'Logout',
                    theme: theme,
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog(context, theme);
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Wuthering Wares v1.0',
                  style: theme.baseTextStyle( Colors.grey[700]!,).copyWith( fontSize: 11)),
            ),
          ],
        ),
      ),

      body: _pages[_currentIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.borderColor, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: theme.baseBg,
          selectedItemColor: theme.accentColor,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: theme.baseTextStyle(theme.accentColor).copyWith(fontSize:11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: theme.baseTextStyle(Colors.grey[600]!).copyWith(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppTheme theme,
    Color? color,
  }) {
    final c = color ?? theme.primaryTextColor;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label,
          style: theme.baseTextStyle(
               c,).copyWith(fontSize: 15, fontWeight: FontWeight.w500)),
      onTap: onTap,
      horizontalTitleGap: 8,
    );
  }
}