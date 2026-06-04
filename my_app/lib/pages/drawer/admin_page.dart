import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:my_app/theme/app_theme.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final Dio _dio = Dio();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _products = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String _selectedCategory = 'All';

  final List<String> _categories = ['All', 'Weapons', 'Echoes', 'Materials', 'Consumables', 'Special'];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dio.close();
    super.dispose();
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _products.where((p) {
        final name = (p['product_name'] ?? '').toLowerCase();
        final type = (p['type'] ?? '');
        final matchesSearch = name.contains(query);
        final matchesCategory =
            _selectedCategory == 'All' || type == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
    _applyFilter();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _fetchProducts() async {
    try {
      final token = await _getToken();
      final response = await _dio.get(
        '${AppConfig.apiBase}/products',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (mounted) setState(() {
        _products = response.data as List;
        _filtered = _products;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteProduct(dynamic product, AppTheme theme) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surfaceBg,
        title: Text('Delete Product',
            style: TextStyle(color: theme.primaryTextColor)),
        content: Text(
            'Delete "${product['product_name']}"? This cannot be undone.',
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await _getToken();
      await _dio.delete(
        '${AppConfig.apiBase}/products/${product['product_id']}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      _fetchProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product deleted'),
            backgroundColor: theme.surfaceBg,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _openForm({dynamic product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductForm(
        product: product,
        apiBase: AppConfig.apiBase,
        onSaved: _fetchProducts,
      ),
    );
  }

  String _formatPrice(dynamic price) {
    final p = double.tryParse(price.toString()) ?? 0;
    return p.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Scaffold(
      backgroundColor: theme.baseBg,
      appBar: AppBar(
        backgroundColor: theme.baseBg,
        elevation: 0,
        title: Text('Admin Panel',
            style: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: theme.accentColor,
        icon: Icon(Icons.add, color: theme.baseBg),
        label: Text('Add Product',
            style: TextStyle(
                color: theme.baseBg, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: theme.accentColor))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: theme.primaryTextColor),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
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
                        borderSide:
                          BorderSide(color: theme.accentColor),
                      ),
                    ),
                  ),
                ),

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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? theme.accentColor
                                : theme.surfaceBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? theme.accentColor
                                  : theme.borderColor,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              color: selected
                                  ? theme.baseBg
                                  : Colors.grey[400],
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_filtered.length} product${_filtered.length != 1 ? 's' : ''}',
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  color: Colors.grey[700], size: 56),
                              const SizedBox(height: 12),
                              Text('No products found',
                                  style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 15)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: theme.accentColor,
                          backgroundColor: theme.surfaceBg,
                          onRefresh: _fetchProducts,
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final p = _filtered[index];
                              return Container(
                                decoration: BoxDecoration(
                                  color: theme.surfaceBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: theme.borderColor),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                          const BorderRadius.horizontal(
                                              left: Radius.circular(12)),
                                      child: SizedBox(
                                        width: 80,
                                        height: 80,
                                        child: (p['image'] ?? '').isNotEmpty
                                            ? Image.network('${AppConfig.serverBase}/uploads/${p['image']}',
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      color: theme.borderColor,
                                                      child: const Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          color: Colors.grey),
                                                    ))
                                            : Container(
                                                color:
                                                    theme.borderColor,
                                                child: const Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(p['type'] ?? '',
                                                style: TextStyle(
                                                    color: theme.accentColor,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text(p['product_name'] ?? '',
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    color: theme.primaryTextColor,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text(
                                                'Rp ${_formatPrice(p['price'])}  ·  Stock: ${p['stock']}',
                                                style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                              Icons.edit_outlined,
                                              color: theme.accentColor,
                                              size: 20),
                                          onPressed: () =>
                                              _openForm(product: p),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                              size: 20),
                                          onPressed: () =>
                                              _deleteProduct(p, theme),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final dynamic product;
  final String apiBase;
  final VoidCallback onSaved;

  const _ProductForm({this.product, required this.apiBase, required this.onSaved});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final Dio _dio = Dio();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedType = 'Weapons';
  File? _pickedImage;
  bool _saving = false;

  final List<String> _types = ['Weapons', 'Echoes', 'Materials', 'Consumables', 'Special'];
  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameController.text = widget.product['product_name'] ?? '';
      _descController.text = widget.product['description'] ?? '';
      _stockController.text = widget.product['stock'].toString();
      _priceController.text = widget.product['price'].toString();
      _selectedType = widget.product['type'] ?? 'Weapons';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _stockController.dispose();
    _priceController.dispose();
    _dio.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final stock = _stockController.text.trim();
    final price = _priceController.text.trim();

    if (name.isEmpty || stock.isEmpty || price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, stock and price are required')));
      return;
    }

    if (!_isEdit && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')));
      return;
    }

    setState(() => _saving = true);

    try {
      final token = await _getToken();

      if (_isEdit && _pickedImage == null) {
        await _dio.patch(
          '${widget.apiBase}/products/${widget.product['product_id']}',
          data: {
            'product_name': name,
            'type': _selectedType,
            'description': desc,
            'stock': stock,
            'price': price,
          },
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      } else {
        final formData = FormData.fromMap({
          'product_name': name,
          'type': _selectedType,
          'description': desc,
          'stock': stock,
          'price': price,
          if (_pickedImage != null)
            'image': await MultipartFile.fromFile(_pickedImage!.path),
        });

        if (_isEdit) {
          await _dio.patch(
            '${widget.apiBase}/products/${widget.product['product_id']}',
            data: formData,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        } else {
          await _dio.post(
            '${widget.apiBase}/products',
            data: formData,
            options: Options(headers: {'Authorization': 'Bearer $token'}),
          );
        }
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    final existingImage = _isEdit ? (widget.product['image'] ?? '') : '';

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            color: theme.baseBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(_isEdit ? 'Edit Product' : 'Add Product',
                        style: TextStyle(
                            color: theme.primaryTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Divider(color: theme.borderColor, height: 1),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: theme.surfaceBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: theme.borderColor,
                                style: BorderStyle.solid),
                          ),
                          child: _pickedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(_pickedImage!,
                                      fit: BoxFit.cover))
                              : existingImage.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.network('${AppConfig.serverBase}/uploads/$existingImage',
                                              fit: BoxFit.cover),
                                          Container(
                                            color:
                                                Colors.black.withValues(alpha: 0.4),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.edit,
                                                    color: theme.primaryTextColor,
                                                    size: 28),
                                                SizedBox(height: 6),
                                                Text('Tap to change',
                                                    style: TextStyle(
                                                        color: theme.primaryTextColor,
                                                        fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined,
                                            color: Colors.grey, size: 36),
                                        SizedBox(height: 8),
                                        Text('Tap to select image',
                                            style: TextStyle(
                                                color: Colors.grey, fontSize: 13)),
                                      ],
                                    ),
                        ),
                      ),

                      if (!_isEdit)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: RichText(
                            text: const TextSpan(
                              text: 'Image',
                              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                              children: [TextSpan(text: ' *', style: TextStyle(color: Colors.redAccent))],
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      _label('Type', required: true),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: theme.surfaceBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.borderColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedType,
                            isExpanded: true,
                            dropdownColor: theme.surfaceBg,
                            style: TextStyle(color: theme.primaryTextColor),
                            items: _types
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedType = val!),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      _label('Product Name', required: true),
                      const SizedBox(height: 8),
                      _field(_nameController, 'e.g. Broadblade of Reverb'),

                      const SizedBox(height: 16),

                      _label('Description', required: true),
                      const SizedBox(height: 8),
                      _field(_descController, 'Item description...',
                          maxLines: 3),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Stock', required: true),
                                const SizedBox(height: 8),
                                _field(_stockController, '0',
                                    keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Price (Rp)', required: true),
                                const SizedBox(height: 8),
                                _field(_priceController, '0',
                                    keyboardType: TextInputType.number),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.accentColor,
                            disabledBackgroundColor: theme.borderColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _saving
                              ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.baseBg))
                              : Text(
                                  _isEdit ? 'Save Changes' : 'Add Product',
                                  style: TextStyle(
                                      color: theme.baseBg,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
            fontWeight: FontWeight.w500),
        children: required
            ? const [TextSpan(text: ' *', style: TextStyle(color: Colors.redAccent))]
            : [],
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint,
      {int maxLines = 1, TextInputType? keyboardType}) {
        final theme = context.read<AppTheme>();
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(color: theme.primaryTextColor),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[700]),
        filled: true,
        fillColor: theme.surfaceBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.accentColor),
        ),
      ),
    );
  }
}