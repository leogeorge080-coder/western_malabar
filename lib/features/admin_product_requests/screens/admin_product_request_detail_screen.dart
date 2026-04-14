import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_product_request_model.dart';
import '../providers/admin_product_requests_provider.dart';
import '../utils/pricing_engine.dart';
import '../widgets/duplicate_candidate_tile.dart';

class AdminProductRequestDetailScreen extends ConsumerStatefulWidget {
  const AdminProductRequestDetailScreen({
    super.key,
    required this.request,
  });

  final AdminProductRequestModel request;

  @override
  ConsumerState<AdminProductRequestDetailScreen> createState() =>
      _AdminProductRequestDetailScreenState();
}

class _AdminProductRequestDetailScreenState
    extends ConsumerState<AdminProductRequestDetailScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _categoryIdController;
  late final TextEditingController _brandIdController;
  late final TextEditingController _priceController;
  late final TextEditingController _salePriceController;
  late final TextEditingController _skuController;
  late final TextEditingController _adminNoteController;

  bool _busy = false;
  bool _showAdvanced = false;
  int? _selectedPriceCents;

  void _applySelectedPrice(int cents) {
    final value = cents < 0 ? 0 : cents;
    final text = value <= 0 ? '' : (value / 100).toStringAsFixed(2);

    setState(() {
      _selectedPriceCents = value <= 0 ? null : value;
      _priceController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _handlePriceInputChanged(String value) {
    final parsed = double.tryParse(value.trim());

    setState(() {
      _selectedPriceCents =
          parsed == null || parsed <= 0 ? null : (parsed * 100).round();
    });
  }

  String _slugify(String input) {
    final lower = input.trim().toLowerCase();
    final normalized = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return normalized.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.request.productName);

    final initialSlug = (widget.request.slug ?? '').trim().isNotEmpty
        ? widget.request.slug!.trim()
        : _slugify(widget.request.productName);
    _slugController = TextEditingController(text: initialSlug);

    _categoryIdController =
        TextEditingController(text: widget.request.categoryId ?? '');
    _brandIdController =
        TextEditingController(text: widget.request.brandId ?? '');

    final requestedPriceCents = widget.request.requestedPriceCents ?? 0;
    _selectedPriceCents = requestedPriceCents > 0 ? requestedPriceCents : null;
    _priceController = TextEditingController(
      text: requestedPriceCents > 0
          ? (requestedPriceCents / 100).toStringAsFixed(2)
          : '',
    );
    _salePriceController = TextEditingController();

    _nameController.addListener(() {
      final currentSlug = _slugController.text.trim();
      final autoFromName = _slugify(_nameController.text);
      if (currentSlug.isEmpty ||
          currentSlug == _slugify(widget.request.productName)) {
        _slugController.value = TextEditingValue(
          text: autoFromName,
          selection: TextSelection.collapsed(offset: autoFromName.length),
        );
      }
    });
    _skuController = TextEditingController();
    _adminNoteController =
        TextEditingController(text: widget.request.adminNote ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _categoryIdController.dispose();
    _brandIdController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _skuController.dispose();
    _adminNoteController.dispose();
    super.dispose();
  }

  Future<void> _approveAsNew() async {
    final typedPrice = double.tryParse(_priceController.text.trim()) ?? 0;
    final selectedPriceCents =
        _selectedPriceCents ?? (typedPrice * 100).round();
    final price = selectedPriceCents / 100;
    final salePrice = _salePriceController.text.trim().isEmpty
        ? null
        : double.tryParse(_salePriceController.text.trim());

    if (_nameController.text.trim().isEmpty ||
        _slugController.text.trim().isEmpty ||
        price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name, slug, and valid price are required'),
        ),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(adminProductRequestsServiceProvider).approveAsNew(
            requestId: widget.request.id,
            finalName: _nameController.text.trim(),
            finalSlug: _slugController.text.trim(),
            finalCategoryId: _categoryIdController.text.trim().isEmpty
                ? null
                : _categoryIdController.text.trim(),
            finalBrandId: _brandIdController.text.trim().isEmpty
                ? null
                : _brandIdController.text.trim(),
            variantPriceCents: selectedPriceCents,
            variantSalePriceCents:
                salePrice == null ? null : (salePrice * 100).round(),
            variantSku: _skuController.text.trim().isEmpty
                ? null
                : _skuController.text.trim(),
          );

      ref.invalidate(adminPendingProductRequestsProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Approved as new product')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approve failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final note = _adminNoteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter rejection note')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(adminProductRequestsServiceProvider).reject(
            requestId: widget.request.id,
            adminNote: note,
          );

      ref.invalidate(adminPendingProductRequestsProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _mergeIntoExisting(String productId) async {
    setState(() => _busy = true);
    try {
      await ref.read(adminProductRequestsServiceProvider).mergeIntoExisting(
            requestId: widget.request.id,
            existingProductId: productId,
            adminNote: _adminNoteController.text.trim().isEmpty
                ? null
                : _adminNoteController.text.trim(),
          );

      ref.invalidate(adminPendingProductRequestsProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merged into existing product')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Merge failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync =
        ref.watch(duplicateCandidatesProvider(widget.request.id));
    final imageUrl = (widget.request.requestedImageUrl ?? '').trim();
    final sellerPrice = widget.request.requestedPriceCents ?? 0;
    final options = PricingEngine.generate(sellerPrice);
    final currentSelectedPrice = _selectedPriceCents ?? sellerPrice;
    final sliderMax = sellerPrice > 0 ? (sellerPrice * 1.5).round() : 0;
    final sliderValue = sellerPrice > 0
        ? currentSelectedPrice.clamp(sellerPrice, sliderMax).toDouble()
        : 0.0;
    final margin = calculateMargin(sellerPrice, currentSelectedPrice);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 14),
                    _RequestHeroCard(request: widget.request),
                    const SizedBox(height: 14),
                    _SellerInfoCard(request: widget.request),
                    const SizedBox(height: 14),
                    if (imageUrl.isNotEmpty)
                      _ImagePreviewCard(imageUrl: imageUrl),
                    if (imageUrl.isNotEmpty) const SizedBox(height: 14),
                    _SectionTitle(
                      title: 'Risk signals',
                      subtitle: 'Duplicate and issue analysis',
                    ),
                    const SizedBox(height: 10),
                    _SignalCard(request: widget.request),
                    const SizedBox(height: 14),
                    if ((widget.request.reviewSummary ?? '').trim().isNotEmpty)
                      _InfoBlock(
                        icon: Icons.auto_awesome_outlined,
                        title: 'Review summary',
                        text: widget.request.reviewSummary!.trim(),
                      ),
                    if ((widget.request.reviewSummary ?? '').trim().isNotEmpty)
                      const SizedBox(height: 14),
                    _SectionTitle(
                      title: 'Final product setup',
                      subtitle: 'Approve as a new catalog product',
                    ),
                    const SizedBox(height: 10),
                    _EditorCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Field(
                            controller: _nameController,
                            label: 'Final Name',
                            icon: Icons.inventory_2_outlined,
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _slugController,
                            label: 'Final Slug',
                            icon: Icons.link_rounded,
                          ),
                          const SizedBox(height: 12),
                          _Field(
                            controller: _priceController,
                            label: 'Price (£)',
                            icon: Icons.currency_pound_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: _handlePriceInputChanged,
                          ),
                          if (sellerPrice > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F4FB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE9E1F3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Seller submitted price: £${(sellerPrice / 100).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Choose a final customer price using quick options, slider, or manual entry.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: options.map((opt) {
                                      final selected =
                                          _selectedPriceCents == opt.priceCents;

                                      return ChoiceChip(
                                        label: Text(opt.label),
                                        selected: selected,
                                        onSelected: (_) {
                                          _applySelectedPrice(opt.priceCents);
                                        },
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 8),
                                  Slider(
                                    min: sellerPrice.toDouble(),
                                    max: sliderMax.toDouble(),
                                    value: sliderValue,
                                    onChanged: (v) {
                                      _applySelectedPrice(v.round());
                                    },
                                  ),
                                  Text(
                                    'Margin: £${margin.value.toStringAsFixed(2)} (${margin.percent.toStringAsFixed(1)}%)',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Quick approval only needs name, slug, and a valid price.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () =>
                                setState(() => _showAdvanced = !_showAdvanced),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F4FB),
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: const Color(0xFFE9E1F3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    size: 18,
                                    color: Color(0xFF5A2D82),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Advanced product setup',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _showAdvanced
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: const Color(0xFF5A2D82),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_showAdvanced) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _Field(
                                    controller: _categoryIdController,
                                    label: 'Category ID',
                                    icon: Icons.category_outlined,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _Field(
                                    controller: _brandIdController,
                                    label: 'Brand ID',
                                    icon: Icons.sell_outlined,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _Field(
                                    controller: _salePriceController,
                                    label: 'Sale Price (£)',
                                    icon: Icons.local_offer_outlined,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _Field(
                                    controller: _skuController,
                                    label: 'Variant SKU',
                                    icon: Icons.qr_code_2_rounded,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _Field(
                              controller: _adminNoteController,
                              label: 'Admin Note',
                              icon: Icons.edit_note_rounded,
                              maxLines: 4,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionTitle(
                      title: 'Possible duplicates',
                      subtitle: 'Merge into existing product if appropriate',
                    ),
                    const SizedBox(height: 10),
                    candidatesAsync.when(
                      loading: () => const _LoadingCard(),
                      error: (e, _) => _ErrorCard(
                        message: 'Failed to load candidates: $e',
                      ),
                      data: (candidates) {
                        if (candidates.isEmpty) {
                          return const _EmptyCard(
                            title: 'No likely duplicates found',
                            subtitle:
                                'This request can likely be approved as a new product.',
                          );
                        }

                        return Column(
                          children: candidates
                              .map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: DuplicateCandidateTile(
                                    candidate: c,
                                    onTap: _busy
                                        ? null
                                        : () => _mergeIntoExisting(c.productId),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: FilledButton.icon(
                              onPressed: _busy ? null : _approveAsNew,
                              icon: _busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check_circle_outline_rounded),
                              label: Text(
                                _busy ? 'Processing...' : 'Approve as New',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF5A2D82),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _reject,
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text(
                          'Reject Request',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFB3261E),
                          side: const BorderSide(color: Color(0xFFB3261E)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: onBack,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Moderate Request',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF5A2D82),
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF5A2D82)),
        ),
      ),
    );
  }
}

class _RequestHeroCard extends StatelessWidget {
  const _RequestHeroCard({
    required this.request,
  });

  final AdminProductRequestModel request;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5A2D82),
            Color(0xFF8B57C8),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            request.productName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Seller request • moderation pending',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                icon: Icons.radar_outlined,
                label: _pretty(request.duplicateStatus),
              ),
              _HeroPill(
                icon: Icons.analytics_outlined,
                label:
                    '${request.duplicateConfidence.toStringAsFixed(0)}% confidence',
              ),
              _HeroPill(
                icon: Icons.access_time_rounded,
                label: _formatDate(request.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _pretty(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
        .join(' ');
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AspectRatio(
          aspectRatio: 1.2,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 40,
                color: Colors.black38,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SellerInfoCard extends StatelessWidget {
  const _SellerInfoCard({
    required this.request,
  });

  final AdminProductRequestModel request;

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seller details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.storefront_outlined,
            label: 'Seller',
            value: request.sellerDisplayName,
          ),
          if ((request.sellerEmail ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.mail_outline_rounded,
              label: 'Email',
              value: request.sellerEmail!,
            ),
          ],
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Seller ID',
            value: request.sellerId,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B5A7A)),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({
    required this.request,
  });

  final AdminProductRequestModel request;

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SignalPill(
                label: _pretty(request.duplicateStatus),
                background: const Color(0xFFFFF4E5),
                foreground: const Color(0xFF8A5200),
                icon: Icons.warning_amber_rounded,
              ),
              _SignalPill(
                label:
                    '${request.duplicateConfidence.toStringAsFixed(0)}% confidence',
                background: const Color(0xFFF4EDFB),
                foreground: const Color(0xFF5A2D82),
                icon: Icons.analytics_outlined,
              ),
            ],
          ),
          if (request.issueFlags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: request.issueFlags
                  .map(
                    (e) => _SignalPill(
                      label: _pretty(e),
                      background: const Color(0xFFFFEFEF),
                      foreground: const Color(0xFFB3261E),
                      icon: Icons.flag_outlined,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  String _pretty(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
        .join(' ');
  }
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF6B5A7A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
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

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines > 1
            ? Padding(
                padding: const EdgeInsets.only(bottom: 52),
                child: Icon(icon),
              )
            : Icon(icon),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: const Color(0xFFFCFBFE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE9E1F3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE9E1F3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFF5A2D82),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _EditorCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: Color(0xFF5A2D82),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _EditorCard(
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF236B35),
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
