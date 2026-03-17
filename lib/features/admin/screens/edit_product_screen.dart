import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:western_malabar/features/admin/models/admin_product_edit_model.dart';
import 'package:western_malabar/features/admin/providers/admin_products_provider.dart';
import 'package:western_malabar/features/admin/screens/barcode_scan_screen.dart';
import 'package:western_malabar/shared/theme/theme.dart';
import 'package:western_malabar/shared/theme/wm_gradients.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final String productId;

  const EditProductScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _initialized = false;
  bool _saving = false;
  bool _isFrozen = false;
  bool _isActive = true;

  String? _selectedBrandId;
  String? _selectedCategoryId;
  List<String> _images = [];

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initFromProduct(AdminProductEditModel product) {
    if (_initialized) return;

    _nameController.text = product.name;
    _slugController.text = product.slug;
    _barcodeController.text = product.barcode ?? '';
    _descriptionController.text = product.description ?? '';
    _selectedBrandId = product.brandId;
    _selectedCategoryId = product.categoryId;
    _images = List<String>.from(product.images);
    _isFrozen = product.isFrozen;
    _isActive = product.isActive;

    _initialized = true;
  }

  Future<void> _pickImageFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (file == null || !mounted) return;

    await _uploadPickedImage(File(file.path));
  }

  Future<void> _pickImageFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (file == null || !mounted) return;

    await _uploadPickedImage(File(file.path));
  }

  Future<void> _uploadPickedImage(File file) async {
    try {
      setState(() => _saving = true);

      final url =
          await ref.read(adminProductsServiceProvider).uploadProductImage(file);

      if (!mounted) return;

      setState(() {
        _images = [url];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image uploaded'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image upload failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const BarcodeScanScreen(),
      ),
    );

    if (!mounted || result == null || result.trim().isEmpty) return;

    setState(() {
      _barcodeController.text = result.trim();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _saving = true);

      final service = ref.read(adminProductsServiceProvider);

      final computedSlug = _slugController.text.trim().isEmpty
          ? service.buildSlugFromName(_nameController.text)
          : _slugController.text.trim();

      await service.updateProduct(
        productId: widget.productId,
        name: _nameController.text.trim(),
        slug: computedSlug,
        brandId: _selectedBrandId,
        categoryId: _selectedCategoryId,
        images: _images,
        description: _descriptionController.text.trim(),
        isActive: _isActive,
        isFrozen: _isFrozen,
        barcode: _barcodeController.text.trim(),
      );

      if (!mounted) return;

      ref.invalidate(adminProductsProvider);
      ref.invalidate(adminProductByIdProvider(widget.productId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(adminProductByIdProvider(widget.productId));
    final brandsAsync = ref.watch(adminBrandsProvider);
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: WMGradients.pageBackground,
        ),
        child: SafeArea(
          child: productAsync.when(
            data: (product) {
              _initFromProduct(product);

              return brandsAsync.when(
                data: (brands) {
                  return categoriesAsync.when(
                    data: (categories) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.maybePop(context),
                                  icon: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                  ),
                                ),
                                const Expanded(
                                  child: Text(
                                    'Edit Product',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Form(
                              key: _formKey,
                              child: ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                children: [
                                  _SectionCard(
                                    title: 'Image & Barcode',
                                    child: Column(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          height: 220,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: const Color(0xFFE6DFF0),
                                            ),
                                          ),
                                          child: _images.isEmpty
                                              ? const Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.image_not_supported,
                                                      size: 42,
                                                      color:
                                                          WMTheme.royalPurple,
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      'No product image',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  child: Image.network(
                                                    _images.first,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    errorBuilder:
                                                        (_, __, ___) =>
                                                            const Center(
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 40,
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: _saving
                                                    ? null
                                                    : _pickImageFromCamera,
                                                icon: const Icon(
                                                  Icons.camera_alt_rounded,
                                                ),
                                                label: const Text('Camera'),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: _saving
                                                    ? null
                                                    : _pickImageFromGallery,
                                                icon: const Icon(
                                                  Icons.photo_library_rounded,
                                                ),
                                                label: const Text('Gallery'),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        _AppTextField(
                                          controller: _barcodeController,
                                          label: 'Barcode',
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                _saving ? null : _scanBarcode,
                                            icon: const Icon(
                                              Icons.qr_code_scanner_rounded,
                                            ),
                                            label: const Text(
                                              'Scan Barcode',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  WMTheme.royalPurple,
                                              foregroundColor: Colors.white,
                                              minimumSize:
                                                  const Size.fromHeight(50),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _SectionCard(
                                    title: 'Core Details',
                                    child: Column(
                                      children: [
                                        _AppTextField(
                                          controller: _nameController,
                                          label: 'Product Name',
                                          validator: (value) {
                                            if ((value ?? '').trim().isEmpty) {
                                              return 'Product name is required';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            if (_slugController.text
                                                .trim()
                                                .isEmpty) {
                                              _slugController.text = ref
                                                  .read(
                                                      adminProductsServiceProvider)
                                                  .buildSlugFromName(value);
                                            }
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        _AppTextField(
                                          controller: _slugController,
                                          label: 'Slug',
                                          validator: (value) {
                                            if ((value ?? '').trim().isEmpty) {
                                              return 'Slug is required';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        DropdownButtonFormField<String>(
                                          value: brands.any((e) =>
                                                  e.id == _selectedBrandId)
                                              ? _selectedBrandId
                                              : null,
                                          items: brands
                                              .map(
                                                (e) => DropdownMenuItem(
                                                  value: e.id,
                                                  child: Text(e.name),
                                                ),
                                              )
                                              .toList(),
                                          decoration: InputDecoration(
                                            labelText: 'Brand',
                                            filled: true,
                                            fillColor: const Color(0xFFF9F6FC),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedBrandId = value;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        DropdownButtonFormField<String>(
                                          value: categories.any((e) =>
                                                  e.id == _selectedCategoryId)
                                              ? _selectedCategoryId
                                              : null,
                                          items: categories
                                              .map(
                                                (e) => DropdownMenuItem(
                                                  value: e.id,
                                                  child: Text(e.name),
                                                ),
                                              )
                                              .toList(),
                                          decoration: InputDecoration(
                                            labelText: 'Category',
                                            filled: true,
                                            fillColor: const Color(0xFFF9F6FC),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _selectedCategoryId = value;
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        _AppTextField(
                                          controller: _descriptionController,
                                          label: 'Description',
                                          maxLines: 4,
                                        ),
                                        const SizedBox(height: 12),
                                        SwitchListTile(
                                          value: _isFrozen,
                                          onChanged: (value) {
                                            setState(() {
                                              _isFrozen = value;
                                            });
                                          },
                                          activeColor: WMTheme.royalPurple,
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text(
                                            'Frozen Product',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        SwitchListTile(
                                          value: _isActive,
                                          onChanged: (value) {
                                            setState(() {
                                              _isActive = value;
                                            });
                                          },
                                          activeColor: WMTheme.royalPurple,
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text(
                                            'Active Product',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x12000000),
                                  blurRadius: 10,
                                  offset: Offset(0, -4),
                                ),
                              ],
                            ),
                            child: SafeArea(
                              top: false,
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: WMTheme.royalPurple,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _saving
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Text('Failed to load categories\n$e'),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Center(
                  child: Text('Failed to load brands\n$e'),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Center(
              child: Text('Failed to load product\n$e'),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final int maxLines;
  final void Function(String)? onChanged;

  const _AppTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF9F6FC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}




