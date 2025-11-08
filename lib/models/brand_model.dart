// lib/models/brand_model.dart
class BrandModel {
  final String id; // uuid as string
  final String name;
  final String slug;
  final String? icon; // url or icon name
  final bool isActive;

  const BrandModel({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    required this.isActive,
  });

  factory BrandModel.fromMap(Map<String, dynamic> m) {
    return BrandModel(
      id: _asString(m['id']) ?? '',
      name: _asString(m['name']) ?? '',
      slug: _asString(m['slug']) ?? '',
      icon: _asString(m['icon']),
      isActive: _asBool(m['is_active']),
    );
  }

  static String? _asString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
    // (If you prefer strict typing, return null instead of toString()).
  }

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      if (s == 'true' || s == 't' || s == '1') return true;
      if (s == 'false' || s == 'f' || s == '0') return false;
    }
    return false;
  }
}
