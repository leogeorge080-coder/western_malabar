import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ---------- FIXED HEADER ----------
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: const Color(0xFFFFF9EE), // soft warm background
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'WESTERN MALABAR',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Color(0xFF5A2D82),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.shopping_bag_outlined,
                          color: Color(0xFF5A2D82)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF5A2D82), size: 18),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Deliver to Leo – Scunthorpe DN15',
                        style: TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search box
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search Masalas & Spices 🔍',
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF5A2D82)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.mic_none_outlined,
                            color: Color(0xFF5A2D82)),
                        onPressed: () {},
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------- SCROLLABLE BODY ----------
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banners
                  _promoBanner(
                    color: const Color(0xFFFFD54F),
                    icon: Icons.local_fire_department_outlined,
                    title: 'Weekend Double Points',
                    subtitle: 'on Frozen Foods',
                  ),
                  _promoBanner(
                    color: const Color(0xFFFFD54F),
                    icon: Icons.favorite_border_outlined,
                    title: 'Free Delivery over £30',
                    subtitle: 'Limited time',
                  ),
                  _promoBanner(
                    color: const Color(0xFFFFD54F),
                    icon: Icons.card_giftcard_outlined,
                    title: '100 Welcome Points',
                    subtitle: 'for New Members',
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Today's Picks",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5A2D82),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Two products
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        child: _ProductCard(
                          name: 'Kerala Matta Rice 5kg',
                          price: '£12.99',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _ProductCard(
                          name: 'Sambar Powder 200g',
                          price: '£2.49',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Browse by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5A2D82),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: const [
                      _CategoryChip(label: 'Rice'),
                      _CategoryChip(label: 'Masalas'),
                      _CategoryChip(label: 'Frozen'),
                      _CategoryChip(label: 'Beverages'),
                      _CategoryChip(label: 'Dairy'),
                      _CategoryChip(label: 'Snacks'),
                      _CategoryChip(label: 'Vegetables'),
                      _CategoryChip(label: 'Household'),
                    ],
                  ),
                  const SizedBox(height: 80), // bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Helper Widgets ----------

Widget _promoBanner({
  required Color color,
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
      ],
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.orange[800]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
      ],
    ),
  );
}

class _ProductCard extends StatelessWidget {
  final String name;
  final String price;
  const _ProductCard({required this.name, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.image, size: 50, color: Colors.black26),
            ),
          ),
          const SizedBox(height: 8),
          Text(name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(price, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5A2D82),
              minimumSize: const Size.fromHeight(38),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {},
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
