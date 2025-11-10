import 'package:flutter/material.dart';
import 'dart:math' as math;

class WeatherTasteBanner extends StatefulWidget {
  const WeatherTasteBanner({super.key});

  @override
  State<WeatherTasteBanner> createState() => _WeatherTasteBannerState();
}

class _WeatherTasteBannerState extends State<WeatherTasteBanner>
    with SingleTickerProviderStateMixin {
  final List<_BannerData> _banners = [
    const _BannerData(
      emoji: '☀️',
      text: 'Sunny in Scotland – Enjoy Tender Coconut & Cool Drinks',
      image: 'assets/banners/coconut_drink.jpg',
      color1: Color(0xFF6B3FA6),
      color2: Color(0xFF9C6ADE),
    ),
    const _BannerData(
      emoji: '🌧️',
      text: 'Rainy evening – Try Hot Tea & Banana Fritters',
      image: 'assets/banners/tea_vada.jpg',
      color1: Color(0xFF5A2D82),
      color2: Color(0xFFB57EDC),
    ),
    const _BannerData(
      emoji: '❄️',
      text: 'Cold day – Kerala Parotta & Beef Roast Combo',
      image: 'assets/banners/parotta_beef.jpg',
      color1: Color(0xFF4B0082),
      color2: Color(0xFF8E24AA),
    ),
  ];

  int _index = 0;
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 6));
      if (!mounted) return false;
      setState(() => _index = (_index + 1) % _banners.length);
      return true;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = _banners[_index];
    return Container(
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [b.color1, b.color2],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(b.image,
                fit: BoxFit.cover, opacity: const AlwaysStoppedAnimation(0.2)),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${b.emoji}  ${b.text}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: b.color1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Opening: ${b.text}')),
                      );
                    },
                    child: const Text('Shop Now'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerData {
  final String emoji;
  final String text;
  final String image;
  final Color color1;
  final Color color2;
  const _BannerData({
    required this.emoji,
    required this.text,
    required this.image,
    required this.color1,
    required this.color2,
  });
}
