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
  final _priceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockQtyController = TextEditingController();
  final _dealPriceController = TextEditingController();
  final _dealBadgeController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  bool _initialized = false;
  bool _saving = false;
  bool _isFrozen = false;
  bool _isActive = true;
  bool _isWeeklyDeal = false;

  DateTime? _dealStartsAt;
  DateTime? _dealEndsAt;

  String? _selectedBrandId;
  String? _selectedCategoryId;
  List<String> _images = [];

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _stockQtyController.dispose();
    _dealPriceController.dispose();
    _dealBadgeController.dispose();
    super.dispose();
  }

  void _initFromProduct(AdminProductEditModel product) {
    if (_initialized) return;

    _nameController.text = product.name;
    _slugController.text = product.slug;
    _barcodeController.text = product.barcode ?? '';
    _descriptionController.text = product.description ?? '';
    _priceController.text =
        product.priceCents != null && product.priceCents! > 0
            ? (product.priceCents! / 100).toStringAsFixed(2)
            : '';
    _salePriceController.text =
        product.salePriceCents != null && product.salePriceCents! > 0
            ? (product.salePriceCents! / 100).toStringAsFixed(2)
            : '';

    _selectedBrandId = product.brandId;
    _selectedCategoryId = product.categoryId;
    _images = List<String>.from(product.images);
    _isFrozen = product.isFrozen;
    _isActive = product.isActive;
    _isWeeklyDeal = product.isWeeklyDeal;
    _stockQtyController.text =
        product.stockQty != null ? product.stockQty.toString() : '';

    _dealPriceController.text = product.dealPriceCents != null
        ? (product.dealPriceCents! / 100).toStringAsFixed(2)
        : '';
    _dealBadgeController.text = (product.dealBadgeText ?? 'Weekly Deal').trim();

    _dealStartsAt = product.dealStartsAt;
    _dealEndsAt = product.dealEndsAt;

    _initialized = true;
  }

  Future<void> _pickDealStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dealStartsAt ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _dealStartsAt = picked);
  }

  Future<void> _pickDealEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dealEndsAt ?? _dealStartsAt ?? now,
      firstDate: _dealStartsAt ?? now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _dealEndsAt = picked);
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Not set';
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$d/$m/$y';
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

    final service = ref.read(adminProductsServiceProvider);

    final computedSlug = _slugController.text.trim().isEmpty
        ? service.buildSlugFromName(_nameController.text)
        : _slugController.text.trim();

    final baseRaw = _priceController.text.trim();
    final baseValue = double.tryParse(baseRaw);

    if (baseRaw.isEmpty || baseValue == null || baseValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid base price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final parsedBasePriceCents = (baseValue * 100).round();

    int? parsedSalePriceCents;
    final saleRaw = _salePriceController.text.trim();
    if (saleRaw.isNotEmpty) {
      final saleValue = double.tryParse(saleRaw);
      if (saleValue == null || saleValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a valid sale price'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      parsedSalePriceCents = (saleValue * 100).round();
      if (parsedSalePriceCents >= parsedBasePriceCents) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale price must be lower than base price'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    int? parsedDealPriceCents;
    if (_isWeeklyDeal) {
      final dealRaw = _dealPriceController.text.trim();
      final dealValue = double.tryParse(dealRaw);
      if (dealValue == null || dealValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enter a valid weekly deal price'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      parsedDealPriceCents = (dealValue * 100).round();
      if (parsedDealPriceCents >= parsedBasePriceCents) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deal price must be lower than base price'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final stockQtyRaw = _stockQtyController.text.trim();
    final parsedStockQty =
        stockQtyRaw.isEmpty ? null : int.tryParse(stockQtyRaw);
    if (stockQtyRaw.isNotEmpty &&
        (parsedStockQty == null || parsedStockQty < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid stock quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _saving = true);

      await service.updateProduct(
        productId: widget.productId,
        name: _nameController.text.trim(),
        slug: computedSlug,
        brandId: _selectedBrandId,
        categoryId: _selectedCategoryId,
        images: _images,
        description: _descriptionController.text.trim(),
        isActive: _isActive,
        stockQty: parsedStockQty,
        isFrozen: _isFrozen,
        barcode: _barcodeController.text.trim(),
        priceCents: parsedBasePriceCents,
        salePriceCents: parsedSalePriceCents,
        isWeeklyDeal: _isWeeklyDeal,
        dealPriceCents: parsedDealPriceCents,
        dealStartsAt: _isWeeklyDeal ? _dealStartsAt : null,
        dealEndsAt: _isWeeklyDeal ? _dealEndsAt : null,
        dealBadgeText: _isWeeklyDeal ? _dealBadgeController.text.trim() : null,
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

      Navigator.of(context).pop();
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
              final parsedStockQty = int.tryParse(
                _stockQtyController.text.trim(),
              );
              final derivedAvailableQty = parsedStockQty == null
                  ? null
                  : (parsedStockQty < 0 ? 0 : parsedStockQty);
              final derivedVisibility =
                  _isActive && (derivedAvailableQty ?? 0) > 0;

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
                                                (e) => DropdownMenuItem<String>(
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
                                                (e) => DropdownMenuItem<String>(
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
                                  const SizedBox(height: 14),
                                  _SectionCard(
                                    title: 'Availability & Stock',
                                    child: Column(
                                      children: [
                                        _ReadOnlyInfoTile(
                                          label: 'Customer Visibility',
                                          value: derivedVisibility
                                              ? 'Visible'
                                              : 'Hidden',
                                          helper:
                                              'Auto-derived from active status and stock quantity.',
                                        ),
                                        const SizedBox(height: 12),
                                        _ReadOnlyInfoTile(
                                          label: 'Available Qty',
                                          value:
                                              derivedAvailableQty?.toString() ??
                                                  '-',
                                          helper:
                                              'Backend keeps available quantity equal to stock.',
                                        ),
                                        const SizedBox(height: 12),
                                        _AppTextField(
                                          controller: _stockQtyController,
                                          label: 'Central Stock Qty',
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => setState(() {}),
                                          validator: (value) {
                                            final raw = (value ?? '').trim();
                                            if (raw.isEmpty) return null;
                                            final parsed = int.tryParse(raw);
                                            if (parsed == null || parsed < 0) {
                                              return 'Enter a valid non-negative stock quantity';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Product stock is the backend inventory truth. Customer visibility and available quantity are auto-synced from this value.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _SectionCard(
                                    title: 'Pricing',
                                    child: Column(
                                      children: [
                                        _AppTextField(
                                          controller: _priceController,
                                          label: 'Base Price (£)',
                                          keyboardType: const TextInputType
                                              .numberWithOptions(
                                            decimal: true,
                                          ),
                                          validator: (value) {
                                            final raw = (value ?? '').trim();
                                            if (raw.isEmpty) {
                                              return 'Base price is required';
                                            }
                                            final parsed = double.tryParse(raw);
                                            if (parsed == null || parsed <= 0) {
                                              return 'Enter a valid base price';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        _AppTextField(
                                          controller: _salePriceController,
                                          label: 'Sale Price (£) — optional',
                                          keyboardType: const TextInputType
                                              .numberWithOptions(
                                            decimal: true,
                                          ),
                                          validator: (value) {
                                            final raw = (value ?? '').trim();
                                            if (raw.isEmpty) return null;

                                            final sale = double.tryParse(raw);
                                            final base = double.tryParse(
                                              _priceController.text.trim(),
                                            );

                                            if (sale == null || sale <= 0) {
                                              return 'Enter a valid sale price';
                                            }
                                            if (base != null && sale >= base) {
                                              return 'Sale price must be lower than base price';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Weekly deal below overrides sale price while active.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _SectionCard(
                                    title: 'Deal Settings',
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SwitchListTile(
                                          value: _isWeeklyDeal,
                                          onChanged: (value) {
                                            setState(() {
                                              _isWeeklyDeal = value;
                                              if (_dealBadgeController.text
                                                  .trim()
                                                  .isEmpty) {
                                                _dealBadgeController.text =
                                                    'Weekly Deal';
                                              }
                                            });
                                          },
                                          activeColor: WMTheme.royalPurple,
                                          contentPadding: EdgeInsets.zero,
                                          title: const Text(
                                            'Enable Weekly Deal',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          subtitle: const Text(
                                            'Show this product in Weekly Deals on home screen',
                                          ),
                                        ),
                                        if (_isWeeklyDeal) ...[
                                          const SizedBox(height: 12),
                                          _AppTextField(
                                            controller: _dealPriceController,
                                            label: 'Deal Price (£)',
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                              decimal: true,
                                            ),
                                            validator: (_) {
                                              if (!_isWeeklyDeal) return null;

                                              final raw = _dealPriceController
                                                  .text
                                                  .trim();
                                              if (raw.isEmpty) {
                                                return 'Deal price is required';
                                              }
                                              final value =
                                                  double.tryParse(raw);
                                              if (value == null || value <= 0) {
                                                return 'Enter a valid deal price';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 12),
                                          _AppTextField(
                                            controller: _dealBadgeController,
                                            label: 'Deal Badge Text',
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: _pickDealStartDate,
                                                  icon: const Icon(
                                                    Icons.date_range_rounded,
                                                  ),
                                                  label: Text(
                                                    'Start: ${_formatDate(_dealStartsAt)}',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: _pickDealEndDate,
                                                  icon: const Icon(
                                                    Icons
                                                        .event_available_rounded,
                                                  ),
                                                  label: Text(
                                                    'End: ${_formatDate(_dealEndsAt)}',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _dealStartsAt = null;
                                                    _dealEndsAt = null;
                                                  });
                                                },
                                                child:
                                                    const Text('Clear Dates'),
                                              ),
                                            ],
                                          ),
                                        ],
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

class _ReadOnlyInfoTile extends StatelessWidget {
  const _ReadOnlyInfoTile({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              height: 1.35,
            ),
          ),
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
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _AppTextField({
    required this.controller,
    required this.label,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
