import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finger_farm/data/repositories/thingsboard_status_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/combined_user_device.dart';
import '../model/balena_device_model.dart'; // 모델 import 확인
import 'customer_provider.dart';
import '../repositories/balena_repository.dart';

final balenaRepositoryProvider = Provider((ref) => BalenaRepository());
final tbStatusRepositoryProvider = Provider((ref) => ThingsBoardStatusRepository());

final dashboardProvider = StreamProvider<List<CombinedUserDevice>>((ref) async* {
  final connectivityRepo = ref.watch(balenaRepositoryProvider);
  final customersAsync = ref.watch(customersProvider);

  if (customersAsync.hasValue) {
    final customers = customersAsync.value!.docs;
    final customerMap = {for (var doc in customers) doc.id: doc};

    // 1. [Balena 로드] 모델 리스트로 가져오기
    final List<BalenaDeviceModel> balenaDevices = await connectivityRepo.fetchDevicesWithFacilityId();

    // 2. [Firestore 로드] 모든 시설 정보 메모리 적재
    final allFacilitiesSnapshot = await FirebaseFirestore.instance.collectionGroup('facilities').get();
    final facilityMap = {for (var doc in allFacilitiesSnapshot.docs) doc.id: doc};

    final List<CombinedUserDevice> combinedResults = [];

    // 3. [매칭] Balena 모델 리스트를 기준으로 순회
    for (var bDev in balenaDevices) {
      final String? bFacilityId = bDev.facilityId;

      // 유효하지 않은 ID 값 필터링
      if (bFacilityId == null || bFacilityId == 'FacilityId' || bFacilityId.isEmpty) continue;

      // 메모리 맵에서 시설 조회
      final facDoc = facilityMap[bFacilityId];
      if (facDoc == null) {
        debugPrint('⚠️ [매칭 실패] Balena ID($bFacilityId)가 Firestore 시설 목록에 없음');
        continue;
      }

      try {
        final facData = facDoc.data();

        // 계층 구조 추적
        final farmRef = facDoc.reference.parent.parent;
        final custRef = farmRef?.parent.parent;

        if (custRef != null && customerMap.containsKey(custRef.id)) {
          final custDoc = customerMap[custRef.id]!;
          final custData = custDoc.data() as Map<String, dynamic>;

          combinedResults.add(
            CombinedUserDevice(
              customerId: custRef.id,
              customerName: custData['name'] ?? 'Unknown',
              farmId: farmRef!.id,
              facilityId: facDoc.id,
              facilityName: facData['name'] ?? '시설명 없음',
              deviceName: bDev.deviceName, // 모델 속성 사용
              uuid: bDev.uuid, // 모델 속성 사용
              token: '',
              isCloudlinkOnline: bDev.isOnline, // 모델 속성 사용
              isHeartbeatOnline: bDev.status == 'online', // 모델 속성 사용
              sensors: [],
            ),
          );
        }
      } catch (e) {
        debugPrint('🔥 [${bDev.deviceName}] 데이터 구성 중 예외 발생: $e');
      }
    }

    debugPrint('📊 [결과] 최종 ${combinedResults.length}개의 매칭 데이터 생성 완료');
    yield combinedResults;
  } else {
    yield [];
  }
});
