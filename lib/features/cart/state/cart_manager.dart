import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:da_crust_app/data/model/cart_item.dart';
import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartManager extends ChangeNotifier {
  static final CartManager instance = CartManager._internal();
  String orderNote = "";
  
  String? currentOrderId; 

  CartManager._internal() {
    _loadCart();
  }

  List<CartItem> _items = [];
  List<CartItem> get items => _items;
  DateTime? scheduledTime;
  
  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalCartPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  void updateScheduledTime(DateTime? newTime) {
    scheduledTime = newTime;
    notifyListeners();
  }
  
  Future<void> setPendingOrderId(String orderId) async {
    currentOrderId = orderId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_order_id', orderId);
  }

  // 🌟 FIX 1: Accept the optional spice parameter
  void addItem(MenuItem item, {int quantity = 1, String? size, String? spice}) {
    
    // 🌟 FIX 2: Ensure we don't merge items with different spice levels!
    final existingIndex = _items.indexWhere((i) => 
        i.item.menuId == item.menuId && 
        i.selectedSize == size && 
        i.selectedSpice == spice 
    );

    double snapshotPrice = item.price ?? 0.0; 
    
    if (size != null && item.sizes.isNotEmpty) {
      final sizeObj = item.sizes.firstWhere(
        (s) => s.name == size, 
        orElse: () => item.sizes.first, 
      );
      snapshotPrice = sizeObj.price;
    }

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(
        CartItem(
          item: item, 
          quantity: quantity, 
          selectedSize: size,
          selectedSpice: spice, // 🌟 FIX 3: Pass the spice into the CartItem
          unitPriceAtAddition: snapshotPrice, 
        )
      );
    }
    
    notifyListeners();
    _saveCart(); 
  }

  void updateOrderNote(String newNote) {
    orderNote = newNote;
    notifyListeners();
  }

  void updateQuantity(CartItem cartItem, int newQuantity) {
    if (newQuantity <= 0) {
      _items.remove(cartItem);
    } else {
      cartItem.quantity = newQuantity;
    }
    notifyListeners();
    _saveCart();
  }

  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_items.map((e) => e.toMap()).toList());
    await prefs.setString('saved_cart', encodedData);
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('saved_cart');
    
    currentOrderId = prefs.getString('pending_order_id');
    
    if (savedData != null) {
      try {
        final List<dynamic> decodedData = jsonDecode(savedData);
        _items = decodedData.map((e) => CartItem.fromMap(e as Map<String, dynamic>)).toList();
        notifyListeners(); 
        
        if (currentOrderId != null && _items.isNotEmpty) {
          _verifyAbandonedCartStatus();
        }
      } catch (e) {
        debugPrint("Error parsing saved cart data: $e");
      }
    }
  }

  Future<void> _verifyAbandonedCartStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(currentOrderId)
          .get();

      if (doc.exists) {
        final status = doc.data()?['status'];
        if (status == 'PAID') {
          debugPrint("✅ Background order was paid. Clearing cart.");
          clearCart(); 
        }
      }
    } catch (e) {
      debugPrint("Error verifying background cart status: $e");
    }
  }

  void clearCart() async {
    _items.clear();
    orderNote = "";
    scheduledTime = null;
    currentOrderId = null;
    notifyListeners();
    _saveCart();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_order_id');
  }

  void removeItem(CartItem cartItem) {
    _items.remove(cartItem);
    notifyListeners();
    _saveCart();
  }
}