import 'package:firebase_database/firebase_database.dart';
import '../model/last_updated.dart';

class RealtimeDatabaseRepository {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  Future<LastUpdated?> getLastUpdate(String facilityId) async {
    try {
      // 스크린샷의 경로 구조에 맞춰 'facilities/$facilityId/last_updated' 호출
      final snapshot = await _rtdb.ref('facilities/$facilityId/last_updated').get();

      if (snapshot.exists && snapshot.value is Map) {
        return LastUpdated.fromJson(snapshot.value as Map);
      }
      return null;
    } catch (e) {
      print('RTDB 조회 실패 ($facilityId): $e');
      return null;
    }
  }
}
