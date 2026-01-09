import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finger_farm/data/model/actuator.dart';
import 'package:finger_farm/data/model/actuator_group.dart';
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

  Stream<List<Actuator>> watchActuators(String facilityId) {
    if (facilityId.isEmpty) return Stream.value([]);

    // 스크린샷 경로: facilities/$facilityId/actuators
    return _dbRef
        .child('facilities')
        .child(facilityId)
        .child('actuators')
        .onValue // 데이터 변경 시마다 이벤트 발생
        .map((event) {
          final Map<dynamic, dynamic>? rawData = event.snapshot.value as Map?;
          if (rawData == null) return [];

          final List<Actuator> actuators = [];
          rawData.forEach((key, value) {
            if (value is Map) {
              // 제공해주신 Actuator.fromJson 사용
              actuators.add(Actuator.fromJson(key.toString(), value));
            }
          });

          // 정렬 순서대로 정렬해서 반환
          actuators.sort((a, b) => a.order.compareTo(b.order));
          return actuators;
        });
  }

  Stream<List<ActuatorGroup>> watchActuatorGroups(String facilityId) {
    if (facilityId.isEmpty) return Stream.value([]);

    // 경로: facilities/$facilityId/actuator_groups
    return _dbRef.child('facilities').child(facilityId).child('actuator_groups').onValue.map((event) {
      final Map<dynamic, dynamic>? rawData = event.snapshot.value as Map?;
      if (rawData == null) return [];

      final List<ActuatorGroup> groups = [];
      rawData.forEach((key, value) {
        if (value is Map) {
          // 제공해주신 ActuatorGroup.fromJson 사용 (Map<String, dynamic>으로 변환)
          groups.add(ActuatorGroup.fromJson(Map<String, dynamic>.from(value), key.toString()));
        }
      });

      // 스크린샷의 order 값(-1, -3 등)을 기준으로 정렬
      groups.sort((a, b) => a.order.compareTo(b.order));
      return groups;
    });
  }

  // 스트림 리소스 해제를 위한 dispose 메서드 (필요시 호출)
  void dispose() {
    _responseSubscription?.cancel();
  }
}
