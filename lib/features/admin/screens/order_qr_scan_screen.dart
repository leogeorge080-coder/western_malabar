import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:western_malabar/core/feedback/scan_feedback.dart';
import 'package:western_malabar/shared/theme/theme.dart';

class OrderQrScanScreen extends StatefulWidget {
  const OrderQrScanScreen({super.key});

  @override
  State<OrderQrScanScreen> createState() => _OrderQrScanScreenState();
}

class _OrderQrScanScreenState extends State<OrderQrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;
  bool _popping = false;

  Future<void> _handleRawValue(String raw) async {
    if (_handled || _popping || !mounted) return;

    _handled = true;
    _popping = true;

    try {
      await _controller.stop();
    } catch (_) {}

    await ScanFeedback.soft();

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(raw.trim());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Order QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              if (_handled || _popping) return;

              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final raw = barcodes.first.rawValue;
              if (raw == null || raw.trim().isEmpty) return;

              await _handleRawValue(raw);
            },
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: WMTheme.royalPurple,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Text(
              'Align the printed order QR inside the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




