import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:flutter/foundation.dart';

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

        // menuId is expected to be unique, but it's a plain field on each
        // item (not the Firestore document ID) with nothing enforcing that
        // in the data, so a data-entry duplicate is possible. Widgets use
        // menuId as a widget key, and Flutter throws if siblings share a
        // key, so de-dupe here rather than letting a data issue crash the UI.
        final seenIds = <String>{};
        final deduped = <MenuItem>[];
        for (final item in items) {
          if (seenIds.add(item.menuId)) {
            deduped.add(item);
          } else {
            debugPrint(
              '⚠️ Duplicate menuId "${item.menuId}" found in category '
              '"${item.category}" — keeping the first occurrence and '
              'dropping this one.',
            );
          }
        }

        return deduped;
      },
    );
  }
}