import 'package:da_crust_app/data/model/menu_option.dart';

class MenuItem {
  final String menuId;
  final String name;
  final String category;

  final String? dishType;
  final String? proteinType;
  final String? subCategory;
  final String? configType;

  final String imagePath;
  final String description;

  final bool isAvailable;
  final bool isPopular;
  final int sortOrder;

  final double? price;
  final Map<String, dynamic>? foodLabel;
  final List<MenuOption> sizes;
  
  final List<String> spiceLevels; 

  // 🌟 1. NEW FIELDS: Discounting logic
  final bool isDiscounted;
  final double? originalPrice;

  MenuItem({
    required this.menuId,
    required this.name,
    required this.category,
    required this.imagePath,
    required this.description,
    required this.isAvailable,
    required this.isPopular,
    required this.sortOrder,
    this.dishType,
    this.proteinType,
    this.subCategory,
    this.configType,
    this.price,
    this.foodLabel,
    required this.sizes,
    this.spiceLevels = const [], 
    // 🌟 2. Initialize new fields (defaulting to false)
    this.isDiscounted = false,
    this.originalPrice,
  });

  factory MenuItem.fromMap(
    Map<String, dynamic> map,
    String category,
  ) {
    List<MenuOption> parsedSizes = [];

    if (map['sizes'] != null) {
      parsedSizes = (map['sizes'] as List)
          .map((e) => MenuOption.fromMap(
              Map<String, dynamic>.from(e)))
          .toList();
    }

    return MenuItem(
      menuId: (map['menuId'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      category: category,
      dishType: map['dishType']?.toString(),
      proteinType: map['proteinType']?.toString(),
      subCategory: map['subCategory']?.toString(),
      configType: map['configType']?.toString(),
      imagePath: (map['imagePath'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      isAvailable: map['isAvailable'] ?? true,
      isPopular: map['isPopular'] ?? false,
      sortOrder: map['sortOrder'] ?? 0,
      price: map['price'] != null ? (map['price']).toDouble() : null,
      foodLabel: map['foodLabel'] != null 
          ? Map<String, dynamic>.from(map['foodLabel']) 
          : null,
      sizes: parsedSizes,
      spiceLevels: map['spiceLevels'] != null 
          ? List<String>.from(map['spiceLevels']) 
          : [], 
      // 🌟 3. Safely parse discount fields from Firestore
      isDiscounted: map['isDiscounted'] ?? false,
      originalPrice: map['originalPrice'] != null ? (map['originalPrice']).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuId': menuId,
      'name': name,
      'category': category,
      'dishType': dishType,
      'proteinType': proteinType,
      'subCategory': subCategory,
      'configType': configType,
      'imagePath': imagePath,
      'description': description,
      'isAvailable': isAvailable,
      'isPopular': isPopular,
      'sortOrder': sortOrder,
      'price': price,
      'foodLabel': foodLabel,
      'sizes': sizes.map((x) => x.toMap()).toList(),
      'spiceLevels': spiceLevels, 
      // 🌟 4. Serialize discount fields
      'isDiscounted': isDiscounted,
      'originalPrice': originalPrice,
    };
  }

  double get displayPrice {
    if (price != null) return price!;
    if (sizes.isNotEmpty) return sizes.first.price;
    return 0;
  }
}