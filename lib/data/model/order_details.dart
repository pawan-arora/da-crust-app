import 'package:cloud_firestore/cloud_firestore.dart';

// 🌟 1. Create a clean data model so the UI doesn't have to parse raw maps
class OrderDetails {
  final bool exists;
  final String? status;
  final String? scheduledTime;
  final String? customerEmail;
  final String? customerPhone;

  OrderDetails({
    required this.exists,
    this.status,
    this.scheduledTime,
    this.customerEmail,
    this.customerPhone,
  });

  factory OrderDetails.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) {
      return OrderDetails(exists: false);
    }
    
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return OrderDetails(
      exists: true,
      status: data['status'] as String?,
      scheduledTime: data['scheduledTime'] as String?,
      customerEmail: data['customerEmail'] as String?,
      customerPhone: data['customerPhone'] as String?,
    );
  }
}
