import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:da_crust_app/data/repositories/menu_repository.dart';
import 'package:da_crust_app/features/home/screens/home_content.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = MenuRepository();

    return Scaffold(
      
      body: StreamBuilder<List<MenuItem>>(
        stream: repo.streamMenuItems(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          /// Group items
          final Map<String, List<MenuItem>> grouped = {};
          for (var item in items) {
            grouped.putIfAbsent(item.category, () => []);
            grouped[item.category]!.add(item);
          }

          return HomeContent(grouped: grouped);
        },
      ),
    );
  }
}