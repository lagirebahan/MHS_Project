import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:my_app/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:my_app/theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String _userName = 'User';
  String _email = '';
  String _role = 'user';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Wanderer';
      _email = prefs.getString('email') ?? 'wanderer@wutheringwares.com';
      _role = prefs.getString('role') ?? 'user';
    });
    await _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final response = await Dio().get(
        '${AppConfig.apiBase}/history',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) {
        setState(() {
          _transactions = response.data as List;
          _isLoading = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color get _roleColor =>
      _role == 'admin' ? Colors.blueAccent : Colors.cyanAccent;

  String get _roleLabel => _role == 'admin' ? 'Admin' : 'Wanderer';

  String get _initials {
    final parts = _userName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _userName.isNotEmpty ? _userName[0].toUpperCase() : 'W';
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.baseBg,
        body: Center(child: CircularProgressIndicator(color: theme.accentColor)),
      );
    }

    return Scaffold(
      backgroundColor: theme.baseBg,
      appBar: AppBar(
        backgroundColor: theme.baseBg,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryTextColor),
        title: Text(
          'Profile',
          style: TextStyle(
            color: theme.primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(theme),
                const SizedBox(height: 28),
                _buildStatsRow(theme),
                const SizedBox(height: 32),
                _buildSectionHeader('Transaction History', theme),
                const SizedBox(height: 12),
                ..._transactions.map((tx) => _buildTransactionCard(tx, theme)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(AppTheme theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.surfaceBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.accentColor.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.accentColor.withValues(alpha: 0.3),
                  Colors.blueAccent.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: theme.accentColor.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Center(
              child: Text(
                _initials,
                style: TextStyle(
                  color: theme.accentColor,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: TextStyle(
                    color: theme.primaryTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _roleColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _roleLabel,
                    style: TextStyle(
                      color: _roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppTheme theme) {
    final stats = [
      {'label': 'Orders', 'value': '${_transactions.length}'},
      {'label': 'Total Spent', 'value': 'Rp ${_transactions.fold<double>(0, (sum, tx) => sum + double.parse(tx['total_price'].toString())).toStringAsFixed(0)}'},
      {'label': 'Member Since', 'value': 'Apr 2025'},
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: stat == stats.last ? 0 : 10,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: theme.surfaceBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.borderColor),
            ),
            child: Column(
              children: [
                Text(
                  stat['value']!,
                  style: TextStyle(
                    color: theme.accentColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['label']!,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String title, AppTheme theme) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: theme.accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: theme.primaryTextColor,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, AppTheme theme) {
    // final isCompleted = tx['status'] == 'Completed';
    // final statusColor = isCompleted ? Colors.greenAccent : Colors.orangeAccent;
    
    final itemNames = (tx['item_names'] as String? ?? '').split('||');
    final itemQtys = (tx['item_quantities'] as String? ?? '').split('||');
    final itemList = List.generate(
      itemNames.length,
      (i) => '${itemNames[i]} x${itemQtys[i]}',
    );

    final createdAt = DateTime.tryParse(tx['created_at'] ?? '');
    final dateStr = createdAt != null
        ? '${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#TXN-${tx['transaction_id'].toString().padLeft(5, '0')}',
                style: TextStyle(
                  color: theme.accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              //   decoration: BoxDecoration(
              //     color: statusColor.withValues(alpha: 0.1),
              //     borderRadius: BorderRadius.circular(20),
              //     border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              //   ),
              //   child: Text(
              //     tx['status'],
              //     style: TextStyle(
              //       color: statusColor,
              //       fontSize: 10,
              //       fontWeight: FontWeight.w700,
              //       letterSpacing: 0.5,
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            itemList.join('  ·  '),
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text(
                'Rp ${tx['total_price']}',
                style: TextStyle(
                  color: theme.primaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  } 

  String _monthName(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[month - 1];
  }
  
}