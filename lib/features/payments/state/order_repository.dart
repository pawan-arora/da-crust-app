import 'package:cloud_firestore/cloud_firestore.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Returns a stream of the order document so the UI can react to it
  Stream<DocumentSnapshot<Map<String, dynamic>>> listenToOrder(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots();
  }
}