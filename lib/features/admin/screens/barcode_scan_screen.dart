import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:western_malabar/core/feedback/scan_feedback.dart';
import 'package:western_malabar/shared/theme/theme.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  static const double _scanBoxWidth = 280;
  static const double _scanBoxHeight = 180;

  Future<void> _finish(String value) async {
    if (_handled || !mounted) return;
    _handled = true;

    await ScanFeedback.soft();

    try {
      await _controller.stop();
    } catch (_) {}

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Rect _buildScanWindow(Size size) {
    final left = (size.width - _scanBoxWidth) / 2;
    final top = (size.height - _scanBoxHeight) / 2;

    return Rect.fromLTWH(
      left,
      top,
      _scanBoxWidth,
      _scanBoxHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanWindow = _buildScanWindow(
            Size(constraints.maxWidth, constraints.maxHeight),
          );

          return Stack(
            children: [
              MobileScanner(
                controller: _controller,
                scanWindow: scanWindow,
                onDetect: (capture) async {
                  if (_handled) return;

                  final barcodes = capture.barcodes;
                  if (barcodes.isEmpty) return;

                  final raw = barcodes.first.rawValue;
                  if (raw == null || raw.trim().isEmpty) return;

                  await _finish(raw.trim());
                },
              ),
              _ScannerOverlay(
                scanWindow: scanWindow,
                borderColor: WMTheme.royalPurple,
              ),
              const Positioned(
                left: 24,
                right: 24,
                bottom: 32,
                child: Text(
                  'Align product barcode inside the frame',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  final Rect scanWindow;
  final Color borderColor;

  const _ScannerOverlay({
    required this.scanWindow,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ScannerOverlayPainter(
          scanWindow: scanWindow,
          borderColor: borderColor,
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final Color borderColor;

  _ScannerOverlayPainter({
    required this.scanWindow,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.55);

    final clearPaint = Paint()..blendMode = BlendMode.clear;

    final layerRect = Offset.zero & size;
    canvas.saveLayer(layerRect, Paint());

    canvas.drawRect(layerRect, overlayPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(20)),
      clearPaint,
    );

    canvas.restore();

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanWindow, const Radius.circular(20)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanWindow != scanWindow ||
        oldDelegate.borderColor != borderColor;
  }
}
