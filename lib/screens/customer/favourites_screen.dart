import 'package:flutter/material.dart';
import 'package:western_malabar/theme.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: WMTheme.lightGold,
      body: Center(
        child: Text(
          'Favourites',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
