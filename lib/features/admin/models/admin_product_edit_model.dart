class AdminProductEditModel {
  final String id;
  final String name;
  final String slug;
  final String? brandId;
  final String? categoryId;
  final List<String> images;
  final String? description;
  final bool isActive;
  final bool isFrozen;
  final String? barcode;

  const AdminProductEditModel({
    required this.id,
    required this.name,
    required this.slug,
    this.brandId,
    this.categoryId,
    required this.images,
    this.description,
    required this.isActive,
    required this.isFrozen,
    this.barcode,
  });

  factory AdminProductEditModel.fromMap(Map<String, dynamic> map) {
    final rawImages = map['images'];
    final List<String> parsedImages;

    if (rawImages is List) {
      parsedImages = rawImages.map((e) => e.toString()).toList();
    } else {
      parsedImages = const [];
    }

    return AdminProductEditModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      brandId: map['brand_id'] as String?,
      categoryId: map['category_id'] as String?,
      images: parsedImages,
      description: map['description'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      isFrozen: map['is_frozen'] as bool? ?? false,
      barcode: map['barcode'] as String?,
    );
  }

  AdminProductEditModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? brandId,
    String? categoryId,
    List<String>? images,
    String? description,
    bool? isActive,
    bool? isFrozen,
    String? barcode,
  }) {
    return AdminProductEditModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      brandId: brandId ?? this.brandId,
      categoryId: categoryId ?? this.categoryId,
      images: images ?? this.images,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isFrozen: isFrozen ?? this.isFrozen,
      barcode: barcode ?? this.barcode,
    );
  }

  bool get hasImage => images.isNotEmpty && images.first.trim().isNotEmpty;
  bool get hasBarcode => (barcode ?? '').trim().isNotEmpty;

  int get completenessScore {
    int score = 0;
    if (hasImage) score++;
    if (hasBarcode) score++;
    return score;
  }
}

class AdminBrandOption {
  final String id;
  final String name;
  final String slug;

  const AdminBrandOption({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory AdminBrandOption.fromMap(Map<String, dynamic> map) {
    return AdminBrandOption(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
    );
  }
}

class AdminCategoryOption {
  final String id;
  final String name;
  final String slug;
  final String? parentId;

  const AdminCategoryOption({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
  });

  factory AdminCategoryOption.fromMap(Map<String, dynamic> map) {
    return AdminCategoryOption(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      parentId: map['parent_id'] as String?,
    );
  }
}
