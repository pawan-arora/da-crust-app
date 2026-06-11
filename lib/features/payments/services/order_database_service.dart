import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:da_crust_app/data/model/order_details.dart';

class OrderDatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'australia-southeast1');

  /// Returns a stream of parsed OrderDetails
  Stream<OrderDetails> listenToOrder(String orderId) {
    return _firestore     
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((snapshot) => OrderDetails.fromFirestore(snapshot));
  }

  /// 🌟 NEW: Manually triggers the backend to verify EFTPOS status
  Future<String?> verifyEftposStatus(String orderId) async {
    final result = await _functions
        .httpsCallable('verifyEftposStatus')
        .call({'orderId': orderId});

    return result.data['status'] as String?;
  }
}