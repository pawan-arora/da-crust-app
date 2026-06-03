import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:da_crust_app/data/model/menu_category.dart';
import '../../../data/model/menu_item.dart';

class MenuService {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  Future<List<MenuCategory>> fetchMenu() async {
    final snapshot = await _db.collection('menu').get();

    List<MenuCategory> result = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final category =
          (data['category'] ?? doc.id).toString();

      final section =
          (data['sectionName'] ?? category).toString();

      List<MenuItem> items = [];

      /// variants
      if (data['variants'] != null) {
        final variants =
            data['variants'] as List<dynamic>;

        items.addAll(
          variants.map((e) {
            return MenuItem.fromMap(
              Map<String, dynamic>.from(e),
              category,
            );
          }),
        );
      }

      /// extras (for biryani etc)
      if (data['extras'] != null) {
        final extras =
            data['extras'] as List<dynamic>;

        items.addAll(
          extras.map((e) {
            return MenuItem.fromMap(
              Map<String, dynamic>.from(e),
              category,
            );
          }),
        );
      }

      items.sort(
        (a, b) =>
            a.sortOrder.compareTo(b.sortOrder),
      );

      result.add(
        MenuCategory(
          category: category,
          sectionName: section,
          items: items,
        ),
      );
    }

    return result;
  }
}