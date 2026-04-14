import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:western_malabar/features/seller/models/seller_product_model.dart';
import 'package:western_malabar/features/seller/widgets/seller_price_request_sheet.dart';
import 'package:western_malabar/features/seller/widgets/seller_product_edit_sheet.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

class SellerProductCard extends ConsumerWidget {
  const SellerProductCard({
    super.key,
    required this.product,
  });

  final SellerProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = product.primaryVariant;

    final currentPriceText = variant == null
        ? 'No variant'
        : '£${(variant.effectivePriceCents / 100).toStringAsFixed(2)}';

    final basePriceText = variant == null
        ? null
        : variant.salePriceCents != null
            ? '£${(variant.priceCents / 100).toStringAsFixed(2)}'
            : null;

    final notes = (product.sellerNotes ?? '').trim();
    final imageUrl = _resolveImageUrl(product);
    final barcode = (product.barcode ?? '').trim();
    final hasBarcode = barcode.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductTopRow(
              name: product.name,
              slug: product.slug,
              imageUrl: imageUrl,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PriceBlock(
                    currentPriceText: currentPriceText,
                    basePriceText: basePriceText,
                  ),
                ),
                const SizedBox(width: 12),
                _ProductMetaColumn(
                  isAvailable: product.isAvailable,
                  availableQty: product.availableQty,
                  hasLockedPrice: !product.canRequestPriceChange,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SoftInfoChip(
                  icon: product.isAvailable
                      ? Icons.check_circle_outline_rounded
                      : Icons.pause_circle_outline_rounded,
                  label: product.isAvailable ? 'Available' : 'Unavailable',
                  background: product.isAvailable
                      ? const Color(0xFFEFFAF2)
                      : const Color(0xFFF5F5F5),
                  foreground: product.isAvailable
                      ? const Color(0xFF236B35)
                      : const Color(0xFF616161),
                ),
                _SoftInfoChip(
                  icon: product.availableQty <= 0
                      ? Icons.remove_shopping_cart_outlined
                      : product.availableQty <= 5
                          ? Icons.warning_amber_rounded
                          : Icons.inventory_2_outlined,
                  label: 'Qty ${product.availableQty}',
                  background: product.availableQty <= 0
                      ? const Color(0xFFFFEFEF)
                      : product.availableQty <= 5
                          ? const Color(0xFFFFF4E5)
                          : const Color(0xFFF4EDFB),
                  foreground: product.availableQty <= 0
                      ? const Color(0xFFB3261E)
                      : product.availableQty <= 5
                          ? const Color(0xFF8A5200)
                          : const Color(0xFF5A2D82),
                ),
                if (hasBarcode)
                  _SoftInfoChip(
                    icon: Icons.qr_code_2_rounded,
                    label: barcode,
                    background: const Color(0xFFF8F7FB),
                    foreground: const Color(0xFF5B5B66),
                  ),
                _SoftInfoChip(
                  icon: Icons.sell_outlined,
                  label: currentPriceText,
                  background: const Color(0xFFFFF8E7),
                  foreground: const Color(0xFF8A6A00),
                ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              _NotesBox(notes: notes),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _PrimaryActionButton(
                    icon: Icons.inventory_outlined,
                    label: 'Update stock',
                    onTap: () async {
                      await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            SellerProductEditSheet(product: product),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SecondaryActionButton(
                    icon: Icons.request_quote_outlined,
                    label: 'Request price',
                    enabled: product.canRequestPriceChange,
                    onTap: product.canRequestPriceChange
                        ? () async {
                            await showModalBottomSheet<bool>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) =>
                                  SellerPriceRequestSheet(product: product),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _resolveImageUrl(SellerProductModel product) {
    final images = product.images;
    if (images == null || images.isEmpty) return null;
    final first = images.first.trim();
    return first.isEmpty ? null : first;
  }
}

class _ProductTopRow extends StatelessWidget {
  const _ProductTopRow({
    required this.name,
    required this.slug,
    required this.imageUrl,
  });

  final String name;
  final String slug;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProductThumb(imageUrl: imageUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  slug,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B5A7A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return WmProductImage(
      imageUrl: imageUrl,
      width: 74,
      height: 74,
      borderRadius: 20,
      placeholderIcon: Icons.inventory_2_outlined,
    );
  }
}

class _FallbackThumb extends StatelessWidget {
  const _FallbackThumb();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        color: Color(0xFF5A2D82),
        size: 30,
      ),
    );
  }
}

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({
    required this.currentPriceText,
    required this.basePriceText,
  });

  final String currentPriceText;
  final String? basePriceText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current price',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            currentPriceText,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF5A2D82),
              letterSpacing: -0.3,
            ),
          ),
          if (basePriceText != null) ...[
            const SizedBox(height: 4),
            Text(
              basePriceText!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black45,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductMetaColumn extends StatelessWidget {
  const _ProductMetaColumn({
    required this.isAvailable,
    required this.availableQty,
    required this.hasLockedPrice,
  });

  final bool isAvailable;
  final int availableQty;
  final bool hasLockedPrice;

  @override
  Widget build(BuildContext context) {
    final stockLabel = availableQty <= 0
        ? 'Out'
        : availableQty <= 5
            ? 'Low'
            : 'Healthy';

    final stockColor = availableQty <= 0
        ? const Color(0xFFB3261E)
        : availableQty <= 5
            ? const Color(0xFF8A5200)
            : const Color(0xFF236B35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _MiniMetaBadge(
          label: isAvailable ? 'Live' : 'Hidden',
          foreground:
              isAvailable ? const Color(0xFF236B35) : const Color(0xFF616161),
          background:
              isAvailable ? const Color(0xFFEFFAF2) : const Color(0xFFF2F2F2),
        ),
        const SizedBox(height: 8),
        _MiniMetaBadge(
          label: stockLabel,
          foreground: stockColor,
          background: availableQty <= 0
              ? const Color(0xFFFFEFEF)
              : availableQty <= 5
                  ? const Color(0xFFFFF4E5)
                  : const Color(0xFFEFFAF2),
        ),
        const SizedBox(height: 8),
        _MiniMetaBadge(
          label: hasLockedPrice ? 'Locked' : 'Requestable',
          foreground: hasLockedPrice
              ? const Color(0xFF5A2D82)
              : const Color(0xFF236B35),
          background: hasLockedPrice
              ? const Color(0xFFF4EDFB)
              : const Color(0xFFEFFAF2),
        ),
      ],
    );
  }
}

class _MiniMetaBadge extends StatelessWidget {
  const _MiniMetaBadge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

class _SoftInfoChip extends StatelessWidget {
  const _SoftInfoChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
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

class _NotesBox extends StatelessWidget {
  const _NotesBox({
    required this.notes,
  });

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE6F3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.sticky_note_2_outlined,
              size: 18,
              color: Color(0xFF6B5A7A),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notes,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          label,
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
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF5A2D82),
          side: BorderSide(
            color: enabled ? const Color(0xFF5A2D82) : const Color(0xFFD8D2E2),
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
