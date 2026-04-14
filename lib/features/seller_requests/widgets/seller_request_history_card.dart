import 'package:flutter/material.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

import '../models/seller_product_request_model.dart';

class SellerRequestHistoryCard extends StatelessWidget {
  const SellerRequestHistoryCard({
    super.key,
    required this.request,
  });

  final SellerProductRequestModel request;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (request.requestedImageUrl ?? '').trim();
    final hasImage = imageUrl.isNotEmpty;
    final hasAdminNote = (request.adminNote ?? '').trim().isNotEmpty;
    final hasReviewSummary = (request.reviewSummary ?? '').trim().isNotEmpty;

    final statusStyle = _statusStyle(request.status);
    final duplicateStyle = _duplicateStyle(request.duplicateStatus);

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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumb(imageUrl: hasImage ? imageUrl : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Pill(
                            icon: statusStyle.icon,
                            label: _prettyLabel(request.status),
                            background: statusStyle.background,
                            foreground: statusStyle.foreground,
                          ),
                          _Pill(
                            icon: duplicateStyle.icon,
                            label: _prettyLabel(request.duplicateStatus),
                            background: duplicateStyle.background,
                            foreground: duplicateStyle.foreground,
                          ),
                          _Pill(
                            icon: Icons.analytics_outlined,
                            label:
                                '${request.duplicateConfidence.toStringAsFixed(0)}%',
                            background: const Color(0xFFF4EDFB),
                            foreground: const Color(0xFF5A2D82),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.issueFlags.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: request.issueFlags
                    .map(
                      (flag) => _Pill(
                        icon: Icons.flag_outlined,
                        label: _prettyLabel(flag),
                        background: const Color(0xFFFFF4E5),
                        foreground: const Color(0xFF8A5200),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (hasReviewSummary) ...[
              const SizedBox(height: 14),
              _InfoBlock(
                icon: Icons.auto_awesome_outlined,
                title: 'Review summary',
                text: request.reviewSummary!.trim(),
              ),
            ],
            if (hasAdminNote) ...[
              const SizedBox(height: 12),
              _InfoBlock(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Admin note',
                text: request.adminNote!.trim(),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetaTile(
                    label: 'Created',
                    value: _formatDateTime(request.createdAt),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetaTile(
                    label: 'Reviewed',
                    value: request.reviewedAt == null
                        ? '—'
                        : _formatDateTime(request.reviewedAt!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case 'pending':
        return const _StatusStyle(
          icon: Icons.hourglass_top_rounded,
          background: Color(0xFFFFF4E5),
          foreground: Color(0xFF8A5200),
        );
      case 'approved':
      case 'approved_merged':
        return const _StatusStyle(
          icon: Icons.check_circle_outline_rounded,
          background: Color(0xFFEFFAF2),
          foreground: Color(0xFF236B35),
        );
      case 'rejected':
        return const _StatusStyle(
          icon: Icons.cancel_outlined,
          background: Color(0xFFFFEFEF),
          foreground: Color(0xFFB3261E),
        );
      case 'cancelled':
        return const _StatusStyle(
          icon: Icons.block_outlined,
          background: Color(0xFFF2F2F2),
          foreground: Color(0xFF666666),
        );
      default:
        return const _StatusStyle(
          icon: Icons.info_outline_rounded,
          background: Color(0xFFF4EDFB),
          foreground: Color(0xFF5A2D82),
        );
    }
  }

  _StatusStyle _duplicateStyle(String status) {
    switch (status) {
      case 'exact_match_barcode':
        return const _StatusStyle(
          icon: Icons.qr_code_2_rounded,
          background: Color(0xFFFFEFEF),
          foreground: Color(0xFFB3261E),
        );
      case 'high_confidence_duplicate':
        return const _StatusStyle(
          icon: Icons.warning_amber_rounded,
          background: Color(0xFFFFF4E5),
          foreground: Color(0xFF8A5200),
        );
      case 'possible_duplicate':
        return const _StatusStyle(
          icon: Icons.help_outline_rounded,
          background: Color(0xFFFFF8E8),
          foreground: Color(0xFF8A6A00),
        );
      case 'no_match':
        return const _StatusStyle(
          icon: Icons.check_circle_outline_rounded,
          background: Color(0xFFEFFAF2),
          foreground: Color(0xFF236B35),
        );
      default:
        return const _StatusStyle(
          icon: Icons.search_outlined,
          background: Color(0xFFF4EDFB),
          foreground: Color(0xFF5A2D82),
        );
    }
  }

  String _prettyLabel(String value) {
    return value.replaceAll('_', ' ').split(' ').map((e) {
      if (e.isEmpty) return e;
      return e[0].toUpperCase() + e.substring(1);
    }).join(' ');
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year  $hour:$minute';
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return WmProductImage(
      imageUrl: imageUrl,
      width: 76,
      height: 76,
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

class _Pill extends StatelessWidget {
  const _Pill({
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

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE6F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
}
