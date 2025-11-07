import 'package:flutter/material.dart';
import 'package:western_malabar/theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WMTheme.lightGold,
      body: const Center(
        child: Text(
          "Cart Screen",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
