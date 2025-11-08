import 'package:flutter/material.dart';
import 'package:western_malabar/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: WMTheme.lightGold,
      body: Center(
        child: Text(
          'Profile Screen',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
