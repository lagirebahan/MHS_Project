import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:my_app/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:my_app/theme/app_theme.dart';

class CheckoutPage extends StatefulWidget {
  final List<dynamic> selectedItems;

  const CheckoutPage({super.key, required this.selectedItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Dio _dio = Dio();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  String _formatPrice(dynamic price) {
    final p = double.tryParse(price.toString()) ?? 0;
    return p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  int get _totalPrice {
    return widget.selectedItems.fold(0, (sum, item) {
      final price = double.tryParse(item['price'].toString()) ?? 0;
      final qty = item['quantity'] as int;
      return sum + (price * qty).toInt();
    });
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = await _getToken();
      final orderIds = widget.selectedItems
          .map<int>((i) => i['order_id'] as int)
          .toList();

      await _dio.post(
        '${AppConfig.apiBase}/checkout',
        data: {
          'order_ids': orderIds,
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'total_price': _totalPrice,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => _OrderSuccessPage(
              items: widget.selectedItems,
              name: _nameController.text.trim(),
              address: _addressController.text.trim(),
              totalPrice: _totalPrice,
              formatPrice: _formatPrice,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Something went wrong. Please try again.';
        if (e is DioException && e.response != null) {
          msg = e.response!.data['message'] ?? msg;
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Scaffold(
      backgroundColor: theme.baseBg,
      appBar: AppBar(
        backgroundColor: theme.surfaceBg,
        foregroundColor: theme.primaryTextColor,
        title: Text('Checkout',
            style: theme.baseTextStyle(theme.primaryTextColor).copyWith(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.borderColor),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader('Order Summary', Icons.receipt_long_outlined, theme),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.surfaceBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.borderColor),
              ),
              child: Column(
                children: [
                  ...widget.selectedItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final isLast = i == widget.selectedItems.length - 1;
                    return _orderItem(item, isLast, theme);
                  }),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.baseBg,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total (${widget.selectedItems.length} item${widget.selectedItems.length != 1 ? 's' : ''})',
                          style: theme.baseTextStyle(
                              Colors.grey,).copyWith(fontSize: 13),
                        ),
                        Text(
                          'Rp ${_formatPrice(_totalPrice)}',
                          style: theme.baseTextStyle(
                            theme.accentColor,).copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _sectionHeader('Delivery Details', Icons.local_shipping_outlined, theme),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.surfaceBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.borderColor),
              ),
              child: Column(
                children: [
                  _formField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    icon: Icons.person_outline,
                    theme: theme,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  _formField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: 'e.g. 08123456789',
                    icon: Icons.phone_outlined,
                    theme: theme,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Phone is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _formField(
                    controller: _addressController,
                    label: 'Delivery Address',
                    hint: 'Street, city, postal code',
                    icon: Icons.location_on_outlined,
                    theme: theme,
                    maxLines: 3,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Address is required'
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _sectionHeader('Payment Method', Icons.payments_outlined, theme),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.surfaceBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: theme.accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delivery_dining,
                        color: theme.accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cash on Delivery',
                          style: theme.baseTextStyle(
                              theme.primaryTextColor,).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      Text('Pay when your order arrives',
                          style:
                              theme.baseTextStyle(Colors.grey,).copyWith(fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.check_circle,
                      color: theme.accentColor, size: 20),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.accentColor,
                  disabledBackgroundColor: theme.borderColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Text(
                        'Place Order',
                        style: theme.baseTextStyle(
                            Colors.black,).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, AppTheme theme) {
    return Row(
      children: [
        Icon(icon, color: theme.accentColor, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: theme.baseTextStyle(
                theme.primaryTextColor,).copyWith(
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _orderItem(dynamic item, bool isLast, AppTheme theme) {
    final imageUrl = item['image'] ?? '';
    final name = item['product_name'] ?? '';
    final price = double.tryParse(item['price'].toString()) ?? 0;
    final qty = item['quantity'] as int;
    final subtotal = (price * qty).toInt();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: isLast
            ? Border(bottom: BorderSide(color: theme.borderColor))
            : Border(bottom: BorderSide(color: theme.borderColor)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                            color: theme.borderColor,
                            child: const Icon(Icons.image_not_supported,
                                color: Colors.grey, size: 18),
                          ))
                  : Container(
                      color: theme.borderColor,
                      child: const Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 18),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.baseTextStyle(
                        theme.primaryTextColor,).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Qty: $qty',
                    style:
                        theme.baseTextStyle(Colors.grey,).copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Rp ${_formatPrice(subtotal)}',
            style: theme.baseTextStyle(
                theme.primaryTextColor,).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required AppTheme theme,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: theme.baseTextStyle(theme.primaryTextColor),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.baseTextStyle(Colors.grey),
        hintText: hint,
        hintStyle: theme.baseTextStyle(Color(0xFF3A3A5A)),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.accentColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        filled: true,
        fillColor: theme.baseBg,
      ),
    );
  }
}

class _OrderSuccessPage extends StatelessWidget {
  final List<dynamic> items;
  final String name;
  final String address;
  final int totalPrice;
  final String Function(dynamic) formatPrice;

  const _OrderSuccessPage({
    required this.items,
    required this.name,
    required this.address,
    required this.totalPrice,
    required this.formatPrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Scaffold(
      backgroundColor: theme.baseBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),

              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: theme.accentColor.withValues(alpha: 0.4),
                      width: 2),
                ),
                child: Icon(Icons.check_rounded,
                    color: theme.accentColor, size: 52),
              ),

              const SizedBox(height: 24),

              Text('Order Placed!',
                  style: theme.baseTextStyle(
                      theme.primaryTextColor,).copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold)),

              const SizedBox(height: 8),

              Text(
                'Your order is being processed.\nWe\'ll deliver it to you soon.',
                textAlign: TextAlign.center,
                style: theme.baseTextStyle(Colors.grey,).copyWith(fontSize: 14, height: 1.5),
              ),

              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.surfaceBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Recipient', name, theme),
                    const SizedBox(height: 8),
                    _detailRow('Address', address, theme),
                    const SizedBox(height: 8),
                    _detailRow(
                        'Items',
                        '${items.length} item${items.length != 1 ? 's' : ''}',
                        theme
                        ),
                    Divider(color: theme.borderColor, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: theme.baseTextStyle(
                                Colors.grey[500]!,).copyWith(
                                fontWeight: FontWeight.w500)),
                        Text(
                          'Rp ${formatPrice(totalPrice)}',
                          style: theme.baseTextStyle(
                              theme.accentColor,).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Payment',
                            style: theme.baseTextStyle(Colors.grey[500]!)),
                        Text('Cash on Delivery',
                            style: theme.baseTextStyle(theme.primaryTextColor)),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamedAndRemoveUntil(
                          context, '/home', (_) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Back to Home',
                      style: theme.baseTextStyle(
                          Colors.black,).copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, AppTheme theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: theme.baseTextStyle(Colors.grey[500]!,).copyWith(fontSize: 13)),
        ),
        Text(' : ',
            style: theme.baseTextStyle(Colors.grey[500]!,).copyWith(fontSize: 13)),
        Expanded(
          child: Text(value,
              style:
                  theme.baseTextStyle(theme.primaryTextColor,).copyWith(fontSize: 13)),
        ),
      ],
    );
  }
}