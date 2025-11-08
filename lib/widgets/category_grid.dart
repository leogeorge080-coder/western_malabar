import 'package:flutter/material.dart';
import 'package:western_malabar/models/category_model.dart';
import 'package:western_malabar/theme.dart';

class CategoryGrid extends StatelessWidget {
  final List<CategoryModel> categories;
  final void Function(CategoryModel) onTap;
  const CategoryGrid(
      {super.key, required this.categories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length.clamp(0, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisExtent: 96,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12),
      itemBuilder: (_, i) {
        final c = categories[i];
        return InkWell(
          onTap: () => onTap(c),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF2),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: .04),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.category_outlined, color: WMTheme.royalPurple),
              const SizedBox(height: 8),
              Text(c.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF3B3B3B),
                      fontSize: 12.5,
                      height: 1.15,
                      fontWeight: FontWeight.w600))
            ]),
          ),
        );
      },
    );
  }
}
