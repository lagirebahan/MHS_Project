import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:my_app/config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailPage extends StatefulWidget {
  final dynamic product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final Dio _dio = Dio();
  final ScrollController _scrollController = ScrollController();
  int _quantity = 1;
  bool _addingToCart = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _addToCart() async {
    setState(() => _addingToCart = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      await _dio.post(
        '${AppConfig.apiBase}/cart',
        data: {
          'product_id': widget.product['product_id'],
          'quantity': _quantity,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 18),
                const SizedBox(width: 8),
                Text('${widget.product['product_name']} added to cart'),
              ],
            ),
            backgroundColor: const Color(0xFF1A1A2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to add to cart'),
            backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  String _formatPrice(dynamic price) {
    final p = double.tryParse(price.toString()) ?? 0;
    return p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.product['image'] ?? '';
    final name = widget.product['product_name'] ?? '';
    final type = widget.product['type'] ?? '';
    final description = widget.product['description'] ?? 'No description available.';
    final price = widget.product['price'] ?? 0;
    final stock = int.tryParse(widget.product['stock'].toString()) ?? 0;

    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth; // square = full width

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background image (fixed, gets covered by scrolling sheet)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              width: imageSize,
              height: imageSize,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1A1A2E),
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey, size: 48),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF1A1A2E),
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 48),
                    ),
            ),
          ),

          // Scrollable content sheet that slides over the image
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Transparent spacer so content starts below image
                // Slightly overlapping so rounded corners peek over image
                SizedBox(height: imageSize - 24),

                // Content sheet
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - imageSize + 24,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D0D1A),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag indicator
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 16),
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A4A),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price
                            Text(
                              'Rp ${_formatPrice(price)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            // Stock
                            Row(
                              children: [
                                Icon(
                                  stock > 10
                                      ? Icons.check_circle_outline
                                      : stock > 0
                                          ? Icons.warning_amber_outlined
                                          : Icons.cancel_outlined,
                                  size: 14,
                                  color: stock > 10
                                      ? Colors.greenAccent
                                      : stock > 0
                                          ? Colors.orange
                                          : Colors.redAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  stock > 0
                                      ? '$stock left in stock'
                                      : 'Out of stock',
                                  style: TextStyle(
                                    color: stock > 10
                                        ? Colors.greenAccent
                                        : stock > 0
                                            ? Colors.orange
                                            : Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            const Divider(color: Color(0xFF2A2A4A)),

                            const SizedBox(height: 16),

                            // Type · Name
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$type  ·  ',
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Description
                            Text(
                              description,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),

                            const SizedBox(height: 100), // space for bottom bar
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          border: Border(top: BorderSide(color: Color(0xFF2A2A4A))),
        ),
        child: Row(
          children: [
            // Quantity selector
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A4A)),
              ),
              child: Row(
                children: [
                  _qtyButton(
                    icon: Icons.remove,
                    onTap: _quantity > 1
                        ? () => setState(() => _quantity--)
                        : null,
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$_quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  _qtyButton(
                    icon: Icons.add,
                    onTap: _quantity < stock
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Add to cart button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: stock > 0 && !_addingToCart ? _addToCart : null,
                icon: _addingToCart
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF0D0D1A)))
                    : const Icon(Icons.shopping_cart, size: 18),
                label: Text(
                  stock > 0 ? '+ Add to Cart' : 'Out of Stock',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  disabledBackgroundColor: const Color(0xFF2A2A4A),
                  foregroundColor: const Color(0xFF0D0D1A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 18,
            color: onTap != null ? Colors.white : Colors.grey[700]),
      ),
    );
  }
}