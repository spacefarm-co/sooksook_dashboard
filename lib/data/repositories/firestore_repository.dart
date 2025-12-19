import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // balenaDevices 컬렉션 가져오기
  Stream<QuerySnapshot> getBalenaDevices() {
    return _firestore.collection('balenaDevices').snapshots();
  }

  // customers 컬렉션 가져오기
  Stream<QuerySnapshot> getCustomers() {
    return _firestore.collection('customers').snapshots();
  }
}
