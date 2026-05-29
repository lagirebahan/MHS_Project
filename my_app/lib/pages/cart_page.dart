import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:my_app/config.dart';
import 'package:my_app/pages/checkout_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:my_app/theme/app_theme.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Dio _dio = Dio();
  List<dynamic> _cartItems = [];
  Set<int> _selectedIds = {};
  bool _loading = true;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _fetchCart();
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _fetchCart() async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '${AppConfig.apiBase}/cart',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) {
        setState(() {
          _cartItems = response.data as List;
          _loading = false;
          _selectedIds = _cartItems.map<int>((i) => i['order_id'] as int).toSet();
          _selectAll = _cartItems.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateQuantity(int orderId, int quantity) async {
    if (quantity < 1) {
      _removeItem(orderId);
      return;
    }
    try {
      final token = await _getToken();
      await _dio.patch(
        '${AppConfig.apiBase}/cart/$orderId',
        data: {'quantity': quantity},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      setState(() {
        final idx = _cartItems.indexWhere((i) => i['order_id'] == orderId);
        if (idx != -1) _cartItems[idx]['quantity'] = quantity;
      });
    } catch (e) {
      // silently fail, could show snackbar
    }
  }

  Future<void> _removeItem(int orderId) async {
    try {
      final token = await _getToken();
      await _dio.delete(
        '${AppConfig.apiBase}/cart/$orderId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      setState(() {
        _cartItems.removeWhere((i) => i['order_id'] == orderId);
        _selectedIds.remove(orderId);
        _syncSelectAll();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove item')));
      }
    }
  }

  Future<void> _removeSelected() async {
    final ids = _selectedIds.toList();
    for (final id in ids) {
      await _removeItem(id);
    }
  }

  void _toggleSelect(int orderId) {
    setState(() {
      if (_selectedIds.contains(orderId)) {
        _selectedIds.remove(orderId);
      } else {
        _selectedIds.add(orderId);
      }
      _syncSelectAll();
    });
  }

  void _toggleSelectAll(bool? val) {
    setState(() {
      _selectAll = val ?? false;
      if (_selectAll) {
        _selectedIds = _cartItems.map<int>((i) => i['order_id'] as int).toSet();
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _syncSelectAll() {
    _selectAll = _cartItems.isNotEmpty &&
        _cartItems.every((i) => _selectedIds.contains(i['order_id'] as int));
  }

  int get _totalPrice {
    return _cartItems.fold(0, (sum, item) {
      if (!_selectedIds.contains(item['order_id'] as int)) return sum;
      final price = double.tryParse(item['price'].toString()) ?? 0;
      final qty = item['quantity'] as int;
      return sum + (price * qty).toInt();
    });
  }

  String _formatPrice(dynamic price) {
    final p = double.tryParse(price.toString()) ?? 0;
    return p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Column(
      children: [
        Expanded(
          child: _loading
              ? Center(
                  child: CircularProgressIndicator(color: theme.accentColor))
              : _cartItems.isEmpty
                  ? _emptyCart()
                  : RefreshIndicator(
                      color: theme.accentColor,
                      backgroundColor: theme.surfaceBg,
                      onRefresh: _fetchCart,
                      child: Column(
                        children: [
                          // Select all bar
                          _selectAllBar(theme),
                          // Reorderable list
                          Expanded(
                            child: ReorderableListView.builder(
                            padding: const EdgeInsets.only(bottom: 8),
                            itemCount: _cartItems.length,
                            proxyDecorator: (child, index, animation) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (context, child) => Material(
                                  color: Colors.transparent,
                                  elevation: 0,
                                  child: Opacity(opacity: 0.75, child: child),
                                ),
                                child: child,
                              );
                            },
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) newIndex--;
                                  final item = _cartItems.removeAt(oldIndex);
                                  _cartItems.insert(newIndex, item);
                                });
                              },
                              itemBuilder: (context, index) {
                                final item = _cartItems[index];
                                final orderId = item['order_id'] as int;
                                return _cartItem(item, orderId, index, theme);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
        ),

        // Bottom checkout bar
        if (!_loading && _cartItems.isNotEmpty) _checkoutBar(theme),
      ],
    );
  }

  Widget _emptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              color: Colors.grey[700], size: 64),
          const SizedBox(height: 16),
          Text('Your cart is empty',
              style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Add items from the Products page',
              style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _selectAllBar(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration:  BoxDecoration(
        color: theme.surfaceBg,
        border: Border(bottom: BorderSide(color: theme.borderColor)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _selectAll,
            onChanged: _toggleSelectAll,
            activeColor: theme.accentColor,
            checkColor: theme.baseBg,
            side: const BorderSide(color: Colors.grey),
          ),
          Text('Select All',
              style: TextStyle(color: theme.primaryTextColor, fontSize: 14)),
          const Spacer(),
          if (_selectedIds.isNotEmpty)
            GestureDetector(
              onTap: _removeSelected,
              child: const Text('Delete',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }

  Widget _cartItem(dynamic item, int orderId, int index, AppTheme theme) {
    final imageUrl = item['image'] ?? '';
    final name = item['product_name'] ?? '';
    final price = item['price'] ?? 0;
    final type = item['type'] ?? '';
    final quantity = item['quantity'] as int;
    final stock = item['stock'] as int;
    final isSelected = _selectedIds.contains(orderId);

    return Container(
      key: ValueKey(orderId),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: theme.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? theme.accentColor.withValues(alpha: 0.5) : theme.borderColor,
        ),
      ),
      child: Row(
        children: [
          // Drag handle (three lines)
          ReorderableDragStartListener(
            index: index,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (_) => Container(
                    width: 16,
                    height: 2,
                    margin: const EdgeInsets.symmetric(vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Checkbox
          Checkbox(
            value: isSelected,
            onChanged: (_) => _toggleSelect(orderId),
            activeColor: theme.accentColor,
            checkColor: theme.baseBg,
            side: const BorderSide(color: Colors.grey),
          ),

          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 72,
              height: 72,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            color: theme.borderColor,
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey, size: 20),
                          ))
                  : Container(
                      color: theme.borderColor,
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 20),
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // Product info + quantity
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type,
                      style: TextStyle(
                          color: theme.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: theme.primaryTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('Rp ${_formatPrice(price)}',
                      style: TextStyle(
                          color: theme.primaryTextColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Quantity controls
                  Row(
                    children: [
                      _qtyButton(
                        icon: Icons.remove,
                        onTap: () => _updateQuantity(orderId, quantity - 1),
                        theme: theme,
                      ),
                      Container(
                        width: 36,
                        alignment: Alignment.center,
                        child: Text('$quantity',
                            style: TextStyle(
                                color: theme.primaryTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                      ),
                      _qtyButton(
                        icon: Icons.add,
                        onTap: quantity < stock
                            ? () => _updateQuantity(orderId, quantity + 1)
                            : null,
                        theme: theme,
                      ),
                      if (quantity >= stock)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text('Max',
                              style: TextStyle(
                                  color: Colors.orange[400], fontSize: 11)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onTap, required AppTheme theme}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null
              ? theme.borderColor
              : theme.surfaceBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF3A3A5A)),
        ),
        child: Icon(icon,
            size: 16,
            color: onTap != null ? theme.primaryTextColor : Colors.grey[700]),
      ),
    );
  }

  Widget _checkoutBar(AppTheme theme) {
    final count = _selectedIds.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.surfaceBg,
        border: Border(top: BorderSide(color: theme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total ($count item${count != 1 ? 's' : ''})',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rp ${_formatPrice(_totalPrice)}',
                  style: TextStyle(
                      color: theme.primaryTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: count > 0 ? () {
            final selectedItems = _cartItems
                .where((i) => _selectedIds.contains(i['order_id'] as int))
                .toList();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CheckoutPage(selectedItems: selectedItems),
              ),
            );
          } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accentColor,
              disabledBackgroundColor: theme.borderColor,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Checkout ($count)',
              style: TextStyle(
                  color: count > 0 ? theme.baseBg : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}