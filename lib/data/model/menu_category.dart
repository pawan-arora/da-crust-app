import 'package:da_crust_app/data/model/menu_item.dart';

class MenuCategory {
  final String category;
  final String sectionName;
  final List<MenuItem> items;

  MenuCategory({
    required this.category,
    required this.sectionName,
    required this.items,
  });
}