import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:da_crust_app/core/utils/date_time_utils.dart';
import 'package:da_crust_app/data/model/cart_item.dart';
import 'package:da_crust_app/data/model/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartManager extends ChangeNotifier {
  static final CartManager instance = CartManager._internal();

  String orderNote = "";
  String? currentOrderId;
  DateTime? scheduledTime;

  // ========== Customer Details ==========
  String firstName = "";
  String lastName = "";
  String email = "";
  String phone = "";
  bool wantsSms = true;

  List<CartItem> _items = [];
  List<CartItem> get items => _items;

  int get totalItemCount =>
      _items.fold(0, (sums, item) => sums + item.quantity);

  double get totalCartPrice =>
      _items.fold(0.0, (sums, item) => sums + item.totalPrice);

  CartManager._internal();

  Future<void> initialize() async {
    await _loadCart();
  }

  // ========== Scheduled Time ==========
  void updateScheduledTime(DateTime? newTime) {
    scheduledTime = newTime;
    notifyListeners();
    _saveScheduledTime();
  }

  Future<void> _saveScheduledTime() async {
    final prefs = await SharedPreferences.getInstance();
    if (scheduledTime == null) {
      await prefs.remove('scheduled_time');
    } else {
      await prefs.setString('scheduled_time', scheduledTime!.toIso8601String());
    }
  }

  // ========== Pending Order ==========
  /// Call this as soon as a new order document is created.
  Future<void> setPendingOrderId(String orderId) async {
    currentOrderId = orderId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_order_id', orderId);
    notifyListeners();
  }

  /// Clear only the pending order (keep cart items & customer details).
  Future<void> clearPendingOrderId() async {
    currentOrderId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_order_id');
    notifyListeners();
  }

  // ========== Add Item ==========
  void addItem(MenuItem item, {int quantity = 1, String? size, String? spice}) {
    final existingIndex = _items.indexWhere(
      (i) =>
          i.item.menuId == item.menuId &&
          i.selectedSize == size &&
          i.selectedSpice == spice,
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
          selectedSpice: spice,
          unitPriceAtAddition: snapshotPrice,
        ),
      );
    }

    notifyListeners();
    _saveCart();
  }

  // ========== Order Note ==========
  void updateOrderNote(String newNote) {
    orderNote = newNote;
    notifyListeners();
    _saveOrderNote();
  }

  Future<void> _saveOrderNote() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('order_note', orderNote);
  }

  // ========== Quantity ==========
  void updateQuantity(CartItem cartItem, int newQuantity) {
    if (newQuantity <= 0) {
      _items.remove(cartItem);
    } else {
      cartItem.quantity = newQuantity;
    }
    notifyListeners();
    _saveCart();
  }

  void removeItem(CartItem cartItem) {
    _items.remove(cartItem);
    notifyListeners();
    _saveCart();
  }

  // ========== Customer Details ==========
  void updateCustomerDetails({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    bool? wantsSms,
  }) {
    if (firstName != null) this.firstName = firstName;
    if (lastName != null) this.lastName = lastName;
    if (email != null) this.email = email;
    if (phone != null) this.phone = phone;
    if (wantsSms != null) this.wantsSms = wantsSms;

    notifyListeners();
    _saveCustomerDetails();
  }

  Future<void> _saveCustomerDetails() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('customer_first_name', firstName);
    await prefs.setString('customer_last_name', lastName);
    await prefs.setString('customer_email', email);
    await prefs.setString('customer_phone', phone);
    await prefs.setBool('customer_wants_sms', wantsSms);
  }

  Future<void> _loadCustomerDetails() async {
    final prefs = await SharedPreferences.getInstance();
    firstName = prefs.getString('customer_first_name') ?? "";
    lastName = prefs.getString('customer_last_name') ?? "";
    email = prefs.getString('customer_email') ?? "";
    phone = prefs.getString('customer_phone') ?? "";
    wantsSms = prefs.getBool('customer_wants_sms') ?? true;
  }

  // ========== Save / Load Cart ==========
  Future<void> _saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedData = jsonEncode(_items.map((e) => e.toMap()).toList());
    await prefs.setString('saved_cart', encodedData);
  }

  Future<void> _loadCart() async {
    final prefs = await SharedPreferences.getInstance();

    currentOrderId = prefs.getString('pending_order_id');
    orderNote = prefs.getString('order_note') ?? "";
    await _loadCustomerDetails();

    // Load & validate scheduled time
    final savedTimeStr = prefs.getString('scheduled_time');
    if (savedTimeStr != null) {
      try {
        final savedTime = DateTime.parse(savedTimeStr);
        final nzNow = DateTimeUtils.getNzTime();

        if (savedTime.isAfter(nzNow)) {
          scheduledTime = savedTime;
        } else {
          scheduledTime = null;
          await prefs.remove('scheduled_time');
        }
      } catch (e) {
        debugPrint("Error parsing saved scheduled time: $e");
        scheduledTime = null;
      }
    }

    final savedData = prefs.getString('saved_cart');
    if (savedData != null) {
      try {
        final List<dynamic> decodedData = jsonDecode(savedData);
        _items = decodedData
            .map((e) => CartItem.fromMap(e as Map<String, dynamic>))
            .toList();

        if (currentOrderId != null && _items.isNotEmpty) {
          _verifyAbandonedCartStatus();
        }
      } catch (e) {
        debugPrint("Error parsing saved cart data: $e");
      }
    }

    notifyListeners();
  }

  Future<void> _verifyAbandonedCartStatus() async {
    if (currentOrderId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(currentOrderId)
          .get();

      if (!doc.exists) {
        // Order was deleted or never created properly
        await clearPendingOrderId();
        return;
      }

      final status = doc.data()?['status'];
      if (status == 'PAID') {
        debugPrint("✅ Background order was paid. Clearing cart.");
        clearCart();
      }
      // If status is still PENDING / CREATED → keep the same orderId
    } catch (e) {
      debugPrint("Error verifying background cart status: $e");
    }
  }

  // ========== Clear Cart ==========
  Future<void> clearCart() async {
    _items.clear();
    orderNote = "";
    scheduledTime = null;
    currentOrderId = null;

    notifyListeners();
    await _saveCart();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scheduled_time');
    await prefs.remove('pending_order_id');
    await prefs.remove('order_note');
  }
}