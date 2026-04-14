import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:western_malabar/shared/widgets/mh_monogram_animation.dart';

const _wmSuccessBg = Color(0xFFF7F7F7);
const _wmSuccessSurface = Colors.white;
const _wmSuccessBorder = Color(0xFFE5E7EB);

const _wmSuccessTextStrong = Color(0xFF111827);
const _wmSuccessTextSoft = Color(0xFF6B7280);
const _wmSuccessTextMuted = Color(0xFF9CA3AF);

const _wmSuccessPrimary = Color(0xFF2A2F3A);
const _wmSuccessPrimaryDark = Color(0xFF171A20);

const _wmSuccessGreen = Color(0xFF15803D);
const _wmSuccessGreenSoft = Color(0xFFECFDF5);

class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  final String orderNumber;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
  });

  String get qrCodeValue => 'WM|ORDER|$orderId|$orderNumber';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _wmSuccessBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              MhMonogramAnimation(
                size: 100,
                backgroundColor: Colors.transparent,
                showTile: false,
              ),
              const SizedBox(height: 24),
              const Text(
                'Order Placed Successfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _wmSuccessTextStrong,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Thank you for shopping with Western Malabar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _wmSuccessTextSoft,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              const _SuccessStatusBanner(
                icon: Icons.verified_outlined,
                text:
                    'Your order has been created successfully. You can use the order number and QR code for tracking and store operations.',
              ),
              const SizedBox(height: 18),
              _InfoCard(
                child: Column(
                  children: [
                    const Text(
                      'Order Number',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _wmSuccessTextSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      orderNumber,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: _wmSuccessPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: _wmSuccessBorder),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Internal Order ID',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _wmSuccessTextMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _wmSuccessBorder),
                      ),
                      child: SelectableText(
                        orderId,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _wmSuccessTextSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _InfoCard(
                child: Column(
                  children: [
                    const Text(
                      'Order QR',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _wmSuccessTextStrong,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This QR code is used across packing, admin scanning, and delivery verification.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _wmSuccessTextSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _wmSuccessSurface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: _wmSuccessBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: qrCodeValue,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _wmSuccessBorder),
                      ),
                      child: SelectableText(
                        qrCodeValue,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _wmSuccessTextSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: _wmSuccessPrimary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'What happens next',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _wmSuccessTextStrong,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14),
                    _NextStepRow(
                      title: 'Order confirmation',
                      subtitle:
                          'Your order is now recorded in the system and ready for the next processing step.',
                    ),
                    SizedBox(height: 10),
                    _NextStepRow(
                      title: 'Store processing',
                      subtitle:
                          'The team will prepare, pack, and verify items using the same order QR.',
                    ),
                    SizedBox(height: 10),
                    _NextStepRow(
                      title: 'Delivery or collection',
                      subtitle:
                          'You can use your order details later for delivery tracking or pickup verification.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _wmSuccessPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;

  const _InfoCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _wmSuccessSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _wmSuccessBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SuccessStatusBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SuccessStatusBanner({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _wmSuccessGreenSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: _wmSuccessGreen,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF166534),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepRow extends StatelessWidget {
  final String title;
  final String subtitle;

  const _NextStepRow({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _wmSuccessBorder),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.check,
            size: 14,
            color: _wmSuccessPrimary,
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
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: _wmSuccessTextStrong,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _wmSuccessTextSoft,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
