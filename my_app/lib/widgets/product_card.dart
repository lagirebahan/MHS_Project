import 'package:flutter/material.dart';
import 'package:my_app/config.dart';
import 'package:my_app/theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;
  final AppTheme theme;

  const ProductCard({super.key, required this.product, required this.theme});

  @override
  Widget build(BuildContext context) {
    final imageUrl = '${AppConfig.serverBase}/uploads/${product['image']}';
    final name = product['product_name'] ?? '';
    final price = product['price'] ?? 0;
    final type = product['type'] ?? '';
    final stock = int.tryParse(product['stock'].toString()) ?? 0;
    final isOutOfStock = stock <= 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 1,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: theme.borderColor,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: theme.borderColor,
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey),
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.baseTextStyle(theme.primaryTextColor).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Rp ${_formatPrice(price)}',
                  style: theme.baseTextStyle(theme.primaryTextColor).copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatPrice(dynamic price) {
    final p = double.tryParse(price.toString()) ?? 0;
    return p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }
  
}