import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/seller_brand_option_model.dart';
import '../models/seller_category_option_model.dart';
import '../providers/seller_barcode_lookup_provider.dart';
import '../providers/seller_product_requests_provider.dart';
import '../providers/seller_request_form_provider.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

import '../providers/seller_request_lookup_provider.dart';
import '../providers/seller_request_upload_provider.dart';
import 'seller_barcode_scanner_screen.dart';

class SellerNewProductRequestScreen extends ConsumerStatefulWidget {
  const SellerNewProductRequestScreen({super.key});

  @override
  ConsumerState<SellerNewProductRequestScreen> createState() =>
      _SellerNewProductRequestScreenState();
}

class _SellerNewProductRequestScreenState
    extends ConsumerState<SellerNewProductRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _requestedPriceController;

  final List<String> _uploadedImageUrls = <String>[];
  bool _isUploadingImage = false;

  SellerCategoryOptionModel? _selectedCategory;
  SellerBrandOptionModel? _selectedBrand;
  Timer? _barcodeDebounce;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _barcodeController = TextEditingController();
    _requestedPriceController = TextEditingController();
    _barcodeController.addListener(_onBarcodeChanged);
  }

  @override
  void dispose() {
    _barcodeDebounce?.cancel();
    _barcodeController.removeListener(_onBarcodeChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _requestedPriceController.dispose();
    super.dispose();
  }

  void _onBarcodeChanged() {
    _barcodeDebounce?.cancel();

    _barcodeDebounce = Timer(const Duration(milliseconds: 500), () {
      ref
          .read(sellerBarcodeLookupProvider.notifier)
          .checkBarcode(_barcodeController.text);
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String> _uploadRequestImage(File file) async {
    return ref
        .read(sellerRequestUploadServiceProvider)
        .uploadProductRequestImage(file);
  }

  Future<void> _addImage() async {
    if (_uploadedImageUrls.length >= 2 || _isUploadingImage) return;

    try {
      setState(() => _isUploadingImage = true);

      final source = await _showImageSourceSheet();
      if (source == null) return;

      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 78,
        maxWidth: 1280,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return;

      final file = File(picked.path);
      final uploadedUrl = await _uploadRequestImage(file);

      if (!mounted) return;
      setState(() {
        _uploadedImageUrls.add(uploadedUrl);
      });
    } catch (_) {
      _showError('Failed to add image');
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _replaceImageAt(int index) async {
    if (index < 0 || index >= _uploadedImageUrls.length || _isUploadingImage) {
      return;
    }

    try {
      setState(() => _isUploadingImage = true);

      final source = await _showImageSourceSheet();
      if (source == null) return;

      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 78,
        maxWidth: 1280,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return;

      final file = File(picked.path);
      final uploadedUrl = await _uploadRequestImage(file);

      if (!mounted) return;
      setState(() {
        _uploadedImageUrls[index] = uploadedUrl;
      });
    } catch (_) {
      _showError('Failed to replace image');
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _removeImageAt(int index) {
    if (index < 0 || index >= _uploadedImageUrls.length || _isUploadingImage) {
      return;
    }

    setState(() {
      _uploadedImageUrls.removeAt(index);
    });
  }

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Add Product Image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _ImageSourceTile(
                icon: Icons.photo_camera_outlined,
                title: 'Take Photo',
                subtitle: 'Use camera for a fresh product picture',
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              const SizedBox(height: 10),
              _ImageSourceTile(
                icon: Icons.photo_library_outlined,
                title: 'Choose from Gallery',
                subtitle: 'Pick an existing product image',
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final cleanedImages = _uploadedImageUrls
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .take(2)
        .toList();

    if (cleanedImages.isEmpty) {
      _showError('Please add at least 1 product image');
      return;
    }

    final requestedPrice =
        double.tryParse(_requestedPriceController.text.trim());

    if (requestedPrice == null || requestedPrice <= 0) {
      _showError('Enter a valid requested price');
      return;
    }

    final canContinue = await _confirmDuplicateBarcodeIfNeeded();
    if (!canContinue) return;

    final formNotifier = ref.read(sellerRequestFormProvider.notifier);
    formNotifier.setSubmitting(true);

    try {
      await ref.read(sellerProductRequestServiceProvider).submitRequest(
            productName: _nameController.text.trim(),
            categoryId: _selectedCategory?.id,
            brandId: _selectedBrand?.id,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            barcode: _barcodeController.text.trim().isEmpty
                ? null
                : _barcodeController.text.trim(),
            requestedImages: cleanedImages,
            requestedImageUrl:
                cleanedImages.isEmpty ? null : cleanedImages.first,
            requestedPriceCents: (requestedPrice * 100).round(),
          );

      ref.invalidate(sellerProductRequestsProvider);

      if (mounted) {
        setState(() {
          _uploadedImageUrls.clear();
          _isUploadingImage = false;
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product request submitted')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      _showError('Submit failed: $e');
    } finally {
      formNotifier.setSubmitting(false);
    }
  }

  Future<void> _pickCategory(
    List<SellerCategoryOptionModel> categories,
  ) async {
    final result = await showModalBottomSheet<SellerCategoryOptionModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryPickerSheet(
        items: categories,
        selectedId: _selectedCategory?.id,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCategory = result;
      });
    }
  }

  Future<void> _pickBrand(
    List<SellerBrandOptionModel> brands,
  ) async {
    final result = await showModalBottomSheet<SellerBrandOptionModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BrandPickerSheet(
        items: brands,
        selectedId: _selectedBrand?.id,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedBrand = result;
      });
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const SellerBarcodeScannerScreen(),
      ),
    );

    if (result == null || result.trim().isEmpty) return;

    _barcodeController.text = result.trim();

    await ref
        .read(sellerBarcodeLookupProvider.notifier)
        .checkBarcode(_barcodeController.text);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Barcode scanned: ${result.trim()}')),
    );
  }

  Widget _buildImageSection({required bool isBusy}) {
    final canAddMore = _uploadedImageUrls.length < 2;
    final actionsDisabled = isBusy || _isUploadingImage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7E1EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Images',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add at least 1 image. You can add up to 2 images.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (int i = 0; i < _uploadedImageUrls.length; i++)
                _RequestImageTile(
                  imageUrl: _uploadedImageUrls[i],
                  label: i == 0 ? 'Front image' : 'Second image',
                  onReplace: () => _replaceImageAt(i),
                  onRemove: () => _removeImageAt(i),
                  isDisabled: actionsDisabled,
                ),
              if (canAddMore)
                _AddImageTile(
                  isLoading: _isUploadingImage,
                  isDisabled: actionsDisabled,
                  label: _uploadedImageUrls.isEmpty
                      ? 'Add image'
                      : 'Add second image',
                  onTap: _addImage,
                ),
            ],
          ),
          if (_uploadedImageUrls.length == 1) ...[
            const SizedBox(height: 12),
            const Text(
              'Optional: add a second image for barcode, weight, or back-of-pack details.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<bool> _confirmDuplicateBarcodeIfNeeded() async {
    final lookupState = ref.read(sellerBarcodeLookupProvider);

    if (!(lookupState.result?.exists ?? false)) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Barcode already exists'),
        content: Text(
          'This barcode is already linked to "${lookupState.result?.productName ?? 'an existing product'}".\n\n'
          'You can cancel now and review it, or continue and send this request to admin moderation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit Anyway'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  String? _validateProductName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Required';

    final words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length < 2) {
      return 'Enter a more descriptive product name';
    }

    if (text.length < 5) {
      return 'Product name is too short';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(sellerRequestFormProvider);
    final categoriesAsync = ref.watch(sellerCategoriesProvider);
    final brandsAsync = ref.watch(sellerBrandsProvider);

    final isBusy = formState.submitting || _isUploadingImage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImageSection(isBusy: isBusy),
              const SizedBox(height: 14),
              _Input(
                controller: _nameController,
                label: 'Product Name *',
                validator: _validateProductName,
              ),
              const SizedBox(height: 12),
              _PickerTile(
                label: 'Category',
                value: _selectedCategory?.name,
                loading: categoriesAsync.isLoading,
                onTap: isBusy
                    ? null
                    : categoriesAsync.whenOrNull(
                        data: (items) => () => _pickCategory(items),
                      ),
              ),
              const SizedBox(height: 12),
              _PickerTile(
                label: 'Brand',
                value: _selectedBrand?.name,
                loading: brandsAsync.isLoading,
                onTap: isBusy
                    ? null
                    : brandsAsync.whenOrNull(
                        data: (items) => () => _pickBrand(items),
                      ),
              ),
              const SizedBox(height: 12),
              Column(
                children: [
                  _ScanInput(
                    controller: _barcodeController,
                    label: 'Barcode',
                    hintText: 'Scan or enter manually',
                    onScanTap: isBusy ? null : _scanBarcode,
                  ),
                  const SizedBox(height: 8),
                  const _BarcodeLookupStatus(),
                ],
              ),
              const SizedBox(height: 12),
              _Input(
                controller: _requestedPriceController,
                label: 'Requested Price (£) *',
                validator: (v) {
                  final parsed = double.tryParse((v ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid price';
                  }
                  return null;
                },
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              _Input(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 4,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isBusy ? null : _submit,
                  icon: formState.submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    formState.submitting ? 'Submitting...' : 'Submit Request',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Seller submits image, barcode, and requested price. Admin reviews duplicates, quality, and final selling price before approval.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddImageTile extends StatelessWidget {
  final bool isLoading;
  final bool isDisabled;
  final String label;
  final VoidCallback onTap;

  const _AddImageTile({
    required this.isLoading,
    required this.isDisabled,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.65 : 1,
        child: Container(
          width: 140,
          height: 180,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F5FC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD9C9EC)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const CircularProgressIndicator()
              else
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 34,
                  color: Color(0xFF6F3BA8),
                ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6F3BA8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestImageTile extends StatelessWidget {
  final String imageUrl;
  final String label;
  final VoidCallback onReplace;
  final VoidCallback onRemove;
  final bool isDisabled;

  const _RequestImageTile({
    required this.imageUrl,
    required this.label,
    required this.onReplace,
    required this.onRemove,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7E1EF)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              width: 140,
              height: 140,
              child: WmProductImage(
                imageUrl: imageUrl,
                width: 140,
                height: 140,
                borderRadius: 0,
                placeholderIcon: Icons.image_outlined,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isDisabled ? null : onReplace,
                    child: const Text('Replace'),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isDisabled ? null : onRemove,
                    child: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _BarcodeLookupStatus extends ConsumerWidget {
  const _BarcodeLookupStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sellerBarcodeLookupProvider);

    if (state.checkedBarcode.isEmpty) {
      return const SizedBox.shrink();
    }

    if (state.checking) {
      return Row(
        children: const [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text(
            'Checking barcode...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    if (state.error != null) {
      return const Text(
        'Barcode check failed',
        style: TextStyle(
          fontSize: 12,
          color: Colors.redAccent,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    if (state.result?.exists ?? false) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF4E5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFC266)),
        ),
        child: Text(
          'Barcode already exists for "${state.result?.productName ?? 'existing product'}". Admin will review this as a possible duplicate.',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF8A5200),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9AD9A5)),
      ),
      child: const Text(
        'Barcode not found in current catalog.',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF236B35),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScanInput extends StatelessWidget {
  const _ScanInput({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.onScanTap,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final VoidCallback? onScanTap;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: onScanTap,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          tooltip: 'Scan barcode',
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final String? value;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCFD4DC)),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value == null || value!.isEmpty ? label : value!,
                style: TextStyle(
                  fontSize: 15,
                  color: value == null ? Colors.black54 : Colors.black87,
                  fontWeight: value == null ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ),
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}

class _ImageSourceTile extends StatelessWidget {
  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFCFBFE),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFECE5F6)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EDFB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF5A2D82),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({
    required this.items,
    required this.selectedId,
  });

  final List<SellerCategoryOptionModel> items;
  final String? selectedId;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  late List<SellerCategoryOptionModel> filtered;
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    filtered = widget.items;
    controller.addListener(() {
      final q = controller.text.trim().toLowerCase();
      setState(() {
        filtered = widget.items.where((e) {
          return e.name.toLowerCase().contains(q) ||
              (e.slug ?? '').toLowerCase().contains(q);
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: 520,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Select Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Search category',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final selected = item.id == widget.selectedId;
                    return ListTile(
                      title: Text(item.name),
                      subtitle: item.slug == null ? null : Text(item.slug!),
                      trailing:
                          selected ? const Icon(Icons.check_circle) : null,
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandPickerSheet extends StatefulWidget {
  const _BrandPickerSheet({
    required this.items,
    required this.selectedId,
  });

  final List<SellerBrandOptionModel> items;
  final String? selectedId;

  @override
  State<_BrandPickerSheet> createState() => _BrandPickerSheetState();
}

class _BrandPickerSheetState extends State<_BrandPickerSheet> {
  late List<SellerBrandOptionModel> filtered;
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    filtered = widget.items;
    controller.addListener(() {
      final q = controller.text.trim().toLowerCase();
      setState(() {
        filtered = widget.items.where((e) {
          return e.name.toLowerCase().contains(q) ||
              (e.slug ?? '').toLowerCase().contains(q);
        }).toList();
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: 520,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Select Brand',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Search brand',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final item = filtered[i];
                    final selected = item.id == widget.selectedId;
                    return ListTile(
                      title: Text(item.name),
                      subtitle: item.slug == null ? null : Text(item.slug!),
                      trailing:
                          selected ? const Icon(Icons.check_circle) : null,
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
