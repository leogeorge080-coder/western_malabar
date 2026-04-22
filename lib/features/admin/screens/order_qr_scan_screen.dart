import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:western_malabar/core/feedback/scan_feedback.dart';
import 'package:western_malabar/shared/theme/theme.dart';

typedef OrderQrValidator = String? Function(String rawValue);

class OrderQrScanScreen extends StatefulWidget {
  const OrderQrScanScreen({
    super.key,
    this.title = 'Scan Order QR',
    this.instruction = 'Align the printed order QR inside the frame',
    this.validator,
  });

  final String title;
  final String instruction;
  final OrderQrValidator? validator;

  @override
  State<OrderQrScanScreen> createState() => _OrderQrScanScreenState();
}

class _OrderQrScanScreenState extends State<OrderQrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;
  bool _popping = false;
  bool _processing = false;
  String? _statusMessage;
  Color? _statusColor;

  Future<void> _showInlineStatus(
    String message, {
    required Color color,
    required Future<void> Function() feedback,
  }) async {
    if (!mounted) return;

    setState(() {
      _statusMessage = message;
      _statusColor = color;
    });

    await feedback();

    await Future<void>.delayed(const Duration(milliseconds: 1100));

    if (!mounted || _handled || _popping) return;

    setState(() {
      _statusMessage = null;
      _statusColor = null;
    });
  }

  Future<void> _handleRawValue(String raw) async {
    if (_handled || _popping || _processing || !mounted) return;

    _processing = true;
    final trimmed = raw.trim();

    final validationMessage = widget.validator?.call(trimmed);
    if (validationMessage != null) {
      await _showInlineStatus(
        validationMessage,
        color: Colors.redAccent,
        feedback: ScanFeedback.error,
      );
      _processing = false;
      return;
    }

    _handled = true;
    _popping = true;
    _processing = false;

    try {
      await _controller.stop();
    } catch (_) {}

    await ScanFeedback.soft();

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(trimmed);
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
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              if (_handled || _popping || _processing) return;

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
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _statusMessage == null
                      ? const SizedBox.shrink()
                      : Container(
                          key: ValueKey(_statusMessage),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: (_statusColor ?? Colors.black87)
                                .withOpacity(0.92),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _statusMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
                Text(
                  widget.instruction,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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




