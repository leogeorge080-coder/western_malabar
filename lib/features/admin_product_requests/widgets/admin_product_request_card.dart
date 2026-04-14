import 'package:flutter/material.dart';
import 'package:western_malabar/shared/widgets/wm_product_image.dart';

import '../models/admin_product_request_model.dart';

class AdminProductRequestCard extends StatelessWidget {
  const AdminProductRequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  final AdminProductRequestModel request;
  final VoidCallback onTap;

  bool get isHighRisk =>
      request.duplicateConfidence >= 80 || request.issueFlags.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final imageUrl = (request.requestedImageUrl ?? '').trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductImage(imageUrl: imageUrl),
              const SizedBox(width: 12),

              /// RIGHT CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            request.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RiskBadge(isHighRisk: isHighRisk),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Seller: ${request.sellerDisplayName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Pill(
                          icon: Icons.analytics_outlined,
                          label:
                              '${request.duplicateConfidence.toStringAsFixed(0)}%',
                          color: const Color(0xFFF4EDFB),
                          textColor: const Color(0xFF5A2D82),
                        ),
                        _Pill(
                          icon: Icons.radar_outlined,
                          label: _pretty(request.duplicateStatus),
                          color: const Color(0xFFFFF4E5),
                          textColor: const Color(0xFF8A5200),
                        ),
                        ...request.issueFlags.take(2).map(
                              (e) => _Pill(
                                icon: Icons.flag_outlined,
                                label: _pretty(e),
                                color: const Color(0xFFFFEFEF),
                                textColor: const Color(0xFFB3261E),
                              ),
                            ),
                      ],
                    ),
                    if ((request.reviewSummary ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        request.reviewSummary!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(request.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.badge_outlined,
                          size: 14,
                          color: Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            request.sellerShortId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black38,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

/// IMAGE
class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return WmProductImage(
      imageUrl: imageUrl,
      width: 68,
      height: 68,
      borderRadius: 18,
      placeholderIcon: Icons.image_outlined,
    );
  }
}

/// RISK BADGE
class _RiskBadge extends StatelessWidget {
  const _RiskBadge({
    required this.isHighRisk,
  });

  final bool isHighRisk;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isHighRisk ? const Color(0xFFFFEFEF) : const Color(0xFFEFFAF3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          isHighRisk ? 'High Risk' : 'Low Risk',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color:
                isHighRisk ? const Color(0xFFB3261E) : const Color(0xFF236B35),
          ),
        ),
      ),
    );
  }
}

/// GENERIC PILL
class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
