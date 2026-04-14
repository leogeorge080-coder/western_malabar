import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/seller_product_model.dart';
import '../providers/seller_products_provider.dart';
import '../providers/seller_session_provider.dart';

class SellerProductEditSheet extends ConsumerStatefulWidget {
  const SellerProductEditSheet({
    super.key,
    required this.product,
  });

  final SellerProductModel product;

  @override
  ConsumerState<SellerProductEditSheet> createState() =>
      _SellerProductEditSheetState();
}

class _SellerProductEditSheetState
    extends ConsumerState<SellerProductEditSheet> {
  late bool _isAvailable;
  late TextEditingController _qtyController;
  late TextEditingController _notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.product.isAvailable;
    _qtyController =
        TextEditingController(text: widget.product.availableQty.toString());
    _notesController =
        TextEditingController(text: widget.product.sellerNotes ?? '');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid non-negative quantity')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(sellerServiceProvider).updateProductOps(
            productId: widget.product.id,
            isAvailable: _isAvailable,
            availableQty: qty,
            sellerNotes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );

      ref.invalidate(sellerProductsProvider);

      if (!mounted) return;
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller product settings updated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                _SheetHeaderCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Update Seller Operations',
                  subtitle: widget.product.name,
                  tag: widget.product.isAvailable
                      ? 'Live seller item'
                      : 'Hidden seller item',
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4FB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE9E1F3)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 18,
                              color: Color(0xFF5A2D82),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You can update visibility, soft quantity, and seller notes for your own assigned product only.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ModernSwitchTile(
                        value: _isAvailable,
                        enabled: !_saving,
                        title: 'Product visibility',
                        subtitle: _isAvailable
                            ? 'Customers can currently see this item'
                            : 'This item is hidden from customers',
                        activeLabel: 'Available',
                        inactiveLabel: 'Unavailable',
                        onChanged: (value) {
                          setState(() {
                            _isAvailable = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        enabled: !_saving,
                        decoration: InputDecoration(
                          labelText: 'Soft quantity',
                          hintText: 'Example: 12',
                          prefixIcon: const Icon(Icons.inventory_outlined),
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
                        controller: _notesController,
                        enabled: !_saving,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Seller notes',
                          hintText:
                              'Fresh batch tomorrow / keep hidden / limited stock / etc.',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 54),
                            child: Icon(Icons.sticky_note_2_outlined),
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
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5A2D82),
                            side: const BorderSide(color: Color(0xFF5A2D82)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            backgroundColor: Colors.white,
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
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _saving ? 'Saving...' : 'Save Changes',
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

class _SheetHeaderCard extends StatelessWidget {
  const _SheetHeaderCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;

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
            child: Icon(icon, color: Colors.white, size: 28),
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
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
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

class _ModernSwitchTile extends StatelessWidget {
  const _ModernSwitchTile({
    required this.value,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final String title;
  final String subtitle;
  final String activeLabel;
  final String inactiveLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentLabel = value ? activeLabel : inactiveLabel;
    final currentBg = value ? const Color(0xFFEFFAF2) : const Color(0xFFF3F3F3);
    final currentFg = value ? const Color(0xFF236B35) : const Color(0xFF666666);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE4F5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
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
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: currentBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    currentLabel,
                    style: TextStyle(
                      color: currentFg,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}
