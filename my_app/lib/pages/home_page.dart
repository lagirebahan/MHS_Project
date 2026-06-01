import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:my_app/config.dart';
import 'package:my_app/pages/product_detail_page.dart';
import 'package:my_app/widgets/product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:my_app/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onSeeAll; 
  final void Function(String)? onCategoryTap; 

  const HomePage({super.key, this.onSeeAll, this.onCategoryTap});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Dio _dio = Dio();
  List<dynamic> _featured = [];
  bool _loading = true;
  String _userName = 'Resonator';

  final PageController _bannerController = PageController();
  int _currentBanner = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
    _bannerTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final next = (_currentBanner + 1) % 3;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentBanner = next);
    });
  }

  Future<void> _loadUserAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Resonator';
      });
    }
    
    try {
      final response = await _dio.get(
        '${AppConfig.apiBase}/products',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) {
        setState(() {
          _featured = (response.data as List).take(4).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _dio.close();
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Widget _buildBanner({
    required String title,
    required String subtitle,
    required List<Color> colors,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 30, bottom: -30,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12)),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: widget.onSeeAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Shop Now',
                        style: TextStyle(
                            color: colors[0],
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back,',
                      style: theme.baseTextStyle(theme.primaryTextColor).copyWith(fontSize: 13)),
                  Text(_userName,
                      style: theme.baseTextStyle(theme.primaryTextColor).copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold
                      )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(
                    height: 160,
                    child: PageView(
                      controller: _bannerController,
                      onPageChanged: (i) => setState(() => _currentBanner = i),
                      children: [
                        _buildBanner(
                          title: 'Resonator Equipment',
                          subtitle: 'Gear up for the next expedition',
                          colors: [Color(0xFF0A3D62), Color(0xFF00B4D8)],
                        ),
                        _buildBanner(
                          title: 'Terminal Supplies',
                          subtitle: 'Stock up before you deploy',
                          colors: [Color(0xFF1B4332), Color(0xFF52B788)],
                        ),
                        _buildBanner(
                          title: 'Limited Stock',
                          subtitle: 'Rare gear available now',
                          colors: [Color(0xFF6A0572), Color(0xFFE040FB)],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentBanner == i ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentBanner == i ? theme.accentColor : Colors.grey[600],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _categoryChip(Icons.flash_on, 'Weapons', theme),
                  _categoryChip(Icons.graphic_eq, 'Echoes', theme),
                  _categoryChip(Icons.precision_manufacturing_outlined, 'Materials', theme),
                  _categoryChip(Icons.medication_outlined, 'Consumables', theme),
                  _categoryChip(Icons.auto_awesome, 'Special', theme),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Featured Items',
                    style: theme.baseTextStyle(theme.primaryTextColor).copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    )
                  ),
                  GestureDetector(
                    onTap: widget.onSeeAll,
                    child: Text('See all',
                      style: theme.baseTextStyle(theme.accentColor.withValues(alpha: 0.8)).copyWith(
                        fontSize: 13,
                      )
                    ),
                  ),
                  
                ],
              ),
            ),

            const SizedBox(height: 16),

            _loading
                ? Center(
                    child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: theme.accentColor),
                  ))
                : _featured.isEmpty
                    ? const Center(
                        child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No products yet',
                            style: TextStyle(color: Colors.grey)),
                      ))
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: _featured.length,
                          itemBuilder: (context, index) => GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailPage(product: _featured[index]),
                              ),
                            ),
                            child: ProductCard(product: _featured[index], theme: theme),
                          ),
                        ),
                      ),

            const SizedBox(height: 32),
          ],
        ),      
    );
  }

  Widget _categoryChip(IconData icon, String label, AppTheme theme) {
    return GestureDetector(
      onTap: () => widget.onCategoryTap?.call(label),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.surfaceBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.borderColor),
            ),
            child: Icon(icon, color: theme.accentColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                color: theme.primaryTextColor, 
                fontSize: 11,
                fontFamily: theme.fontFamily == 'Default' ? null : theme.fontFamily,
              )),
        ],
      ),
    );
  }

}