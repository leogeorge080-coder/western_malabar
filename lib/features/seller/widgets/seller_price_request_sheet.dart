import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/seller_product_model.dart';
import '../providers/seller_session_provider.dart';

class SellerPriceRequestSheet extends ConsumerStatefulWidget {
  const SellerPriceRequestSheet({
    super.key,
    required this.product,
  });

  final SellerProductModel product;

  @override
  ConsumerState<SellerPriceRequestSheet> createState() =>
      _SellerPriceRequestSheetState();
}

class _SellerPriceRequestSheetState
    extends ConsumerState<SellerPriceRequestSheet> {
  late TextEditingController _priceController;
  late TextEditingController _reasonController;
  bool _submitting = false;

  SellerVariantModel? get _variant => widget.product.primaryVariant;

  @override
  void initState() {
    super.initState();
    final current = _variant?.effectivePriceCents ?? 0;
    _priceController =
        TextEditingController(text: (current / 100).toStringAsFixed(2));
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final variant = _variant;
    if (variant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No variant found for this product')),
      );
      return;
    }

    final value = double.tryParse(_priceController.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid requested price')),
      );
      return;
    }

    final requestedPriceCents = (value * 100).round();

    setState(() => _submitting = true);

    try {
      await ref.read(sellerServiceProvider).requestPriceChange(
            productId: widget.product.id,
            variantId: variant.id,
            requestedPriceCents: requestedPriceCents,
            sellerReason: _reasonController.text.trim().isEmpty
                ? null
                : _reasonController.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price request submitted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final variant = _variant;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentPrice = variant == null
        ? '—'
        : '£${(variant.effectivePriceCents / 100).toStringAsFixed(2)}';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F4FB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                _PriceSheetHeaderCard(
                  title: 'Request Price Change',
                  subtitle: widget.product.name,
                  currentPrice: currentPrice,
                  sku: variant?.sku,
                ),
                const SizedBox(height: 14),
                Container(
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
                  child: Column(
                    children: [
                      TextField(
                        controller: _priceController,
                        enabled: !_submitting,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Requested price (£)',
                          hintText: 'Example: 2.49',
                          prefixIcon: const Icon(Icons.currency_pound_rounded),
                          filled: true,
                          fillColor: const Color(0xFFFCFBFE),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                const BorderSide(color: Color(0xFFE9E1F3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                const BorderSide(color: Color(0xFFE9E1F3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFF5A2D82),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reasonController,
                        enabled: !_submitting,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Reason',
                          hintText:
                              'Wholesale cost increased / seasonal shortage / supplier change / etc.',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 54),
                            child: Icon(Icons.edit_note_rounded),
                          ),
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: const Color(0xFFFCFBFE),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                const BorderSide(color: Color(0xFFE9E1F3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide:
                                const BorderSide(color: Color(0xFFE9E1F3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFF5A2D82),
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5A2D82),
                            side: const BorderSide(color: Color(0xFF5A2D82)),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _submitting ? 'Submitting...' : 'Submit Request',
                            style: const TextStyle(fontWeight: FontWeight.w800),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceSheetHeaderCard extends StatelessWidget {
  const _PriceSheetHeaderCard({
    required this.title,
    required this.subtitle,
    required this.currentPrice,
    required this.sku,
  });

  final String title;
  final String subtitle;
  final String currentPrice;
  final String? sku;

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
            Color(0xFF8A56C9),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.request_quote_outlined,
              color: Colors.white,
              size: 28,
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
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PriceHeaderPill(
                      label: 'Current $currentPrice',
                    ),
                    if (sku != null && sku!.trim().isNotEmpty)
                      _PriceHeaderPill(
                        label: 'SKU ${sku!.trim()}',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceHeaderPill extends StatelessWidget {
  const _PriceHeaderPill({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
