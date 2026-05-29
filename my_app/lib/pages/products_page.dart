import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:my_app/config.dart';
import 'package:my_app/pages/product_detail_page.dart';
import 'package:my_app/widgets/product_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:my_app/theme/app_theme.dart';

class ProductsPage extends StatefulWidget {
  final String? initialCategory;
  final Function(String)? onCategoryChanged;

  const ProductsPage({super.key, this.initialCategory, this.onCategoryChanged});
  

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final Dio _dio = Dio();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allProducts = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Weapons', 'Echoes', 'Materials', 'Consumables', 'Special'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    _fetchProducts();
    _searchController.addListener(_applyFilter);
  }

  @override
  void didUpdateWidget(ProductsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory) {
      _selectCategory(widget.initialCategory ?? 'All');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await _dio.get(
        '${AppConfig.apiBase}/products',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) {
        setState(() {
          _allProducts = response.data as List;
          _loading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _allProducts.where((p) {
        final name = (p['product_name'] ?? '').toLowerCase();
        final type = (p['type'] ?? '');
        final matchesSearch = name.contains(query);
        final matchesCategory = _selectedCategory == 'All' || type == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    } );
    widget.onCategoryChanged?.call(category);
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: theme.primaryTextColor),
            decoration: InputDecoration(
              hintText: 'Search equipment...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[600]),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilter();
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.surfaceBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.accentColor),
              ),
            ),
          ),
        ),

        // Category filter chips
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final selected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => _selectCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? theme.accentColor : theme.surfaceBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? theme.accentColor : theme.borderColor,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: selected ? theme.primaryTextColor : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filtered.length} item${_filtered.length != 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Grid
        Expanded(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(color: theme.accentColor))
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, color: Colors.grey[700], size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'No items found',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: theme.accentColor,
                      backgroundColor: theme.surfaceBg,
                      onRefresh: _fetchProducts,
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.68,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) => GestureDetector(
                          key: ValueKey(_filtered[index]['id']),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailPage(product: _filtered[index]),
                            ),
                          ),
                          child: ProductCard(product: _filtered[index], theme: theme),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

}