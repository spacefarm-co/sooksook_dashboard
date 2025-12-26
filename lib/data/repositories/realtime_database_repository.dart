import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../model/last_updated.dart';

class RealtimeDatabaseRepository {
  // 제공해주신 3가지 필드 유지
  final firestore = FirebaseFirestore.instance;

  // [수정] 싱가포르 리전 URL을 명시하여 레퍼런스 생성
  final DatabaseReference _dbRef =
      FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://fingerfarm-default-rtdb.asia-southeast1.firebasedatabase.app',
      ).ref();

  StreamSubscription? _responseSubscription;

  Future<LastUpdated?> getLastUpdate(String facilityId) async {
    if (facilityId.isEmpty) return null;

    try {
      // _dbRef를 사용하여 'facilities/$facilityId/last_updated' 경로 조회
      // child를 사용하여 경로를 명확히 지정합니다.
      final snapshot = await _dbRef.child('facilities').child(facilityId).child('last_updated').get();

      if (snapshot.exists && snapshot.value != null) {
        // RTDB 데이터를 Map<String, dynamic>으로 안전하게 캐스팅
        final rawData = snapshot.value as Map;
        final data = Map<String, dynamic>.from(rawData);

        return LastUpdated.fromJson(data);
      }
      return null;
    } catch (e) {
      // 권한 에러 발생 시 로그 출력
      print('[RTDB 상세조회 실패] ID: $facilityId / Error: $e');
      return null;
    }
  }

  // 스트림 리소스 해제를 위한 dispose 메서드 (필요시 호출)
  void dispose() {
    _responseSubscription?.cancel();
  }
}
