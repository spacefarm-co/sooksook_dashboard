import 'package:cloud_firestore/cloud_firestore.dart';

class BalenaDeviceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // balenaDevices 컬렉션 스트림
  Stream<QuerySnapshot> getBalenaDevicesStream() {
    return _firestore.collection('balenaDevices').snapshots();
  }
}
