import 'dart:async';
import 'package:flutter/material.dart';
import 'package:western_malabar/services/weather_service.dart';

class WeatherTasteBannerLive extends StatefulWidget {
  const WeatherTasteBannerLive({
    super.key,
    this.city = 'Scunthorpe',
    this.country = 'GB',
    this.apiKey,
  });
  final String city;
  final String country;
  final String? apiKey;

  @override
  State<WeatherTasteBannerLive> createState() => _WeatherTasteBannerLiveState();
}

class _WeatherTasteBannerLiveState extends State<WeatherTasteBannerLive>
    with SingleTickerProviderStateMixin {
  WeatherNow? _wx;
  Timer? _rot;
  int _i = 0;

  static final Map<String, List<_TasteCard>> _pool = {
    'hot': [
      const _TasteCard('Chai & Pazham Pori', 'Rainy day treats',
          'assets/banners/tea_vada.jpg'),
      const _TasteCard('Parotta & Beef Roast', 'Comfort combo',
          'assets/banners/parotta_beef.jpg'),
    ],
    'cold': [
      const _TasteCard(
          'Mutton Soup', 'Warm & hearty', 'assets/banners/soup.jpg'),
      const _TasteCard('Pepper Chicken', 'Spicy & warming',
          'assets/banners/pepper_chicken.jpg'),
    ],
    'refreshing': [
      const _TasteCard(
          'Tender Coconut', 'Cool & fresh', 'assets/banners/coconut_drink.jpg'),
      const _TasteCard(
          'Falooda & Kulfi', 'Sweet chill', 'assets/banners/falooda.jpg'),
    ],
    'light': [
      const _TasteCard(
          'Idli & Sambar', 'Light & classic', 'assets/banners/idli.jpg'),
      const _TasteCard(
          'Appam & Stew', 'Soft & mild', 'assets/banners/appam_stew.jpg'),
    ],
  };

  String _mood(WeatherNow w) {
    final t = w.tempC;
    final main = w.main.toLowerCase();
    if (main.contains('rain') ||
        main.contains('drizzle') ||
        main.contains('thunder')) return 'hot';
    if (main.contains('snow')) return 'cold';
    if (t <= 7) return 'cold';
    if (t >= 20 && (main.contains('clear') || main.contains('cloud')))
      return 'refreshing';
    if (t >= 14 && t < 20) return 'light';
    return 'light';
  }

  Future<void> _load() async {
    final wx = await WeatherService.fetchCurrent(
      city: widget.city,
      country: widget.country,
      apiKey: widget.apiKey,
    );
    if (!mounted) return;
    setState(() => _wx = wx);
  }

  @override
  void initState() {
    super.initState();
    _load();
    _rot = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      setState(() => _i++);
    });
  }

  @override
  void dispose() {
    _rot?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wx = _wx;
    if (wx == null) {
      return _skeleton();
    }

    final mood = _mood(wx);
    final list = _pool[mood] ?? _pool['light']!;
    final card = list[_i % list.length];
    final headline =
        '${wx.tempC.toStringAsFixed(0)}°C · ${wx.main} in ${widget.city}';

    return _banner(headline: headline, card: card);
  }

  Widget _skeleton() => Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6B3FA6), Color(0xFF9C6ADE)],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
      );

  Widget _banner({required String headline, required _TasteCard card}) =>
      Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 6))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(card.asset, fit: BoxFit.cover),
            Container(color: Colors.black.withOpacity(0.38)),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x00000000), Color(0x33000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(color: Colors.white),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(headline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 14)),
                          const SizedBox(height: 6),
                          Text(card.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(card.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5A2D82),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Show: ${card.title}')),
                      );
                    },
                    child: const Text('Shop Now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TasteCard {
  final String title;
  final String subtitle;
  final String asset;
  const _TasteCard(this.title, this.subtitle, this.asset);
}
