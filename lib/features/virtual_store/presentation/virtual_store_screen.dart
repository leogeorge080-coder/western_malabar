// lib/features/virtual_store/presentation/virtual_store_screen.dart
import 'package:flutter/material.dart';

// ✅ Use package imports so the analyzer is happy
import 'package:western_malabar/services/virtual_camera_orchestrator.dart';
import 'package:western_malabar/features/virtual_store/presentation/widgets/vs_product_card.dart';

class VirtualStoreScreen extends StatefulWidget {
  const VirtualStoreScreen({super.key});

  @override
  State<VirtualStoreScreen> createState() => _VirtualStoreScreenState();
}

class _VirtualStoreScreenState extends State<VirtualStoreScreen> {
  late final VirtualCameraOrchestrator _cam;

  @override
  void initState() {
    super.initState();
    _cam = VirtualCameraOrchestrator();
  }

  @override
  void dispose() {
    _cam.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF5A2D82);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Store'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: purple,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Container(
            height: 48,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3ECFF),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Swipe • Pinch • Tilt (coming soon)',
              style: TextStyle(color: purple, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .72,
              ),
              itemCount: 12,
              itemBuilder: (_, i) => VsProductCard.placeholder(index: i),
            ),
          ),
        ],
      ),
    );
  }
}
