import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:da_crust_app/data/model/menu_item.dart';

class MenuRepository {
  final FirebaseFirestore db =
      FirebaseFirestore.instance;

  Stream<List<MenuItem>> streamMenuItems() {
    return db.collection('menu').snapshots().asyncMap(
      (snapshot) async {
        List<MenuItem> items = [];

        for (final doc in snapshot.docs) {
          final data = doc.data();

          final category =
              (data['category'] ?? doc.id)
                  .toString();

          final variants =
              data['variants'] as List<dynamic>? ??
                  [];

          for (final item in variants) {
            items.add(
              MenuItem.fromMap(
                Map<String, dynamic>.from(item),
                category,
              ),
            );
          }

          final extras =
              data['extras'] as List<dynamic>? ??
                  [];

          for (final item in extras) {
            items.add(
              MenuItem.fromMap(
                Map<String, dynamic>.from(item),
                category,
              ),
            );
          }
        }

        return items;
      },
    );
  }
}