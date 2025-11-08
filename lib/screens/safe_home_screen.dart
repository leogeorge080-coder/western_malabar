import 'package:flutter/material.dart';

class SafeHomeScreen extends StatelessWidget {
  const SafeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (_, __) => [
          const SliverAppBar(
            backgroundColor: Color(0xFFFFF6D9),
            elevation: 0,
            pinned: true,
            floating: true,
            snap: true,
            expandedHeight: 96,
            collapsedHeight: 64,
            flexibleSpace: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'WESTERN MALABAR',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF5A2D82),
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            letterSpacing: 1.05,
                          ),
                        ),
                      ),
                      Icon(Icons.local_mall_outlined, color: Color(0xFF5A2D82)),
                      SizedBox(width: 8),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16, top: 4, right: 16),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 18, color: Color(0xFF5A2D82)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Deliver to Leo – Scunthorpe DN15',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Simple search bar (no TextField to keep it dependency-free)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 12,
                        offset: Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF5A2D82)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Search Masalas & Spices 🔎',
                          style: TextStyle(
                              color: Color(0xFF808080), fontSize: 14)),
                    ),
                    Icon(Icons.mic_none, color: Colors.grey.shade500),
                  ],
                ),
              ),
            ),
          ),
        ],

        // BODY: guaranteed scrollable demo content
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
          children: [
            _offer('Weekend Double Points', 'on Frozen Foods',
                Icons.local_fire_department),
            const SizedBox(height: 8),
            _offer('Free Delivery over £30', 'Limited time',
                Icons.favorite_border),
            const SizedBox(height: 8),
            _offer(
                '100 Welcome Points', 'for New Members', Icons.card_giftcard),
            const SizedBox(height: 16),
            const Text('Today’s Picks',
                style: TextStyle(
                  color: Color(0xFF5A2D82),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 10),
            SizedBox(
              height: 228,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _demoCard(title: 'Kerala Matta Rice 5kg', price: '£12.99'),
                  SizedBox(width: 12),
                  _demoCard(title: 'Sambar Powder 200g', price: '£2.49'),
                  SizedBox(width: 12),
                  _demoCard(title: 'Mango Pickle 400g', price: '£2.99'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Browse by Category',
                style: TextStyle(
                  color: Color(0xFF5A2D82),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 10),
            SizedBox(
              height: 108,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _cat('Rice'),
                  SizedBox(width: 12),
                  _cat('Masalas & Spices'),
                  SizedBox(width: 12),
                  _cat('Vegetables'),
                  SizedBox(width: 12),
                  _cat('Frozen Foods'),
                  SizedBox(width: 12),
                  _cat('Beverages'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _offer(String title, String sub, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFF0C53E), Color(0xFFE7BD3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepOrange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3B3B3B))),
                const SizedBox(height: 2),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF3B3B3B))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF3B3B3B)),
        ],
      ),
    );
  }
}

class _demoCard extends StatelessWidget {
  final String title;
  final String price;
  const _demoCard({required this.title, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 176,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(child: Icon(Icons.image_outlined)),
          ),
          const SizedBox(height: 8),
          Text(title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 13.5, height: 1.15)),
          const SizedBox(height: 6),
          Text(price,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_shopping_cart_outlined, size: 16),
              label: const Text('Add', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(32),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF5A2D82),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _cat extends StatelessWidget {
  final String name;
  const _cat(this.name);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3B3B3B),
            ),
          ),
        ),
      ),
    );
  }
}
