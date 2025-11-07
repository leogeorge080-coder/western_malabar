import 'package:flutter/material.dart';
import '../theme.dart';

class WMSearchBar extends StatelessWidget {
  final String hint;
  const WMSearchBar({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search, color: WMTheme.royalPurple),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
          ),
          Icon(Icons.mic_none, color: Colors.grey.shade500),
        ],
      ),
    );
  }
}
