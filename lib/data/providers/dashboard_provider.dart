import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finger_farm/data/repositories/thingsboard_status_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/combined_user_device.dart';
import 'customer_provider.dart';
import 'balena_device_provider.dart';
import '../repositories/connectivity_repository.dart';

final connectivityRepositoryProvider = Provider((ref) => ConnectivityRepository());
final tbStatusRepositoryProvider = Provider((ref) => ThingsBoardStatusRepository()); // [핵심] 이 줄이 있어야 에러가 사라집니다.

final dashboardProvider = StreamProvider<List<CombinedUserDevice>>((ref) async* {
  final connectivityRepo = ref.watch(connectivityRepositoryProvider);
  final customersAsync = ref.watch(customersProvider);
  final balenaAsync = ref.watch(balenaDevicesProvider);

  // 1. 필요한 기본 데이터가 로드될 때까지 대기
  if (customersAsync.hasValue && balenaAsync.hasValue) {
    final customers = customersAsync.value!.docs;
    final balenaDocs = balenaAsync.value!.docs;

    // 2. 고객 데이터를 ID 기반 Map으로 변환 (검색 속도 최적화)
    final customerMap = {for (var doc in customers) doc.id: doc};

    // 3. Collection Group을 사용하여 모든 시설 정보를 한 번에 가져옴 (성능 핵심)
    // 주의: Firebase 콘솔에서 facilities 컬렉션 그룹 인덱스 설정이 필요할 수 있습니다.
    final allFacilities = await FirebaseFirestore.instance.collectionGroup('facilities').get();

    final List<Future<CombinedUserDevice>> futures = [];

    for (var facDoc in allFacilities.docs) {
      final facData = facDoc.data();
      final facilityId = facDoc.id;
      final facilityName = facData['name'] ?? '시설명 없음';
      final facilityToken = facData['sook_master_token'];

      // 경로 분석: facilities/{facId} -> farms/{farmId} -> customers/{custId}
      // 문서 참조 경로를 통해 상위 ID들을 추출합니다.
      final farmRef = facDoc.reference.parent.parent;
      final custRef = farmRef?.parent.parent;

      if (custRef != null && customerMap.containsKey(custRef.id)) {
        final custDoc = customerMap[custRef.id]!;
        final custData = custDoc.data() as Map<String, dynamic>;
        final sookMasterList = custData['sook_master'] as List? ?? [];

        final matchedMaster = sookMasterList.firstWhere((m) => m['token'] == facilityToken, orElse: () => null);

        if (matchedMaster != null) {
          final mName = matchedMaster['name'] ?? '';

          final matchedDev =
              balenaDocs.where((d) {
                final dData = d.data() as Map<String, dynamic>;
                return dData['device_name'] == mName;
              }).firstOrNull;

          final uuid = (matchedDev?.data() as Map<String, dynamic>?)?['uuid'];

          // 4. 병렬 처리를 위해 Future 리스트에 추가
          futures.add(
            _fetchBasicStatuses(
              connectivityRepo,
              custRef.id,
              custData['name'] ?? 'Unknown',
              farmRef!.id,
              facilityId,
              facilityName,
              mName,
              uuid,
              facilityToken,
            ),
          );
        }
      }
    }

    // 5. 모든 Balena API 호출을 동시에 실행
    final combinedResults = await Future.wait(futures);
    yield combinedResults;
  } else {
    yield [];
  }
});
Future<CombinedUserDevice> _fetchBasicStatuses(
  ConnectivityRepository balenaRepo,
  String customerId,
  String customerName,
  String farmId,
  String facilityId,
  String facilityName,
  String deviceName,
  String? uuid,
  String token,
) async {
  bool cloudlink = false;
  bool heartbeat = false;

  if (uuid != null) {
    try {
      final status = await balenaRepo.getDeviceByUUID(uuid);
      if (status != null && status.isNotEmpty) {
        cloudlink = status['is_online'] ?? false;
        heartbeat = status['api_heartbeat_state'] == 'online';
      }
    } catch (e) {
      print('Balena API Error ($deviceName): $e');
    }
  }

  return CombinedUserDevice(
    customerId: customerId,
    customerName: customerName,
    farmId: farmId,
    facilityId: facilityId,
    facilityName: facilityName,
    deviceName: deviceName,
    uuid: uuid,
    token: token,
    isCloudlinkOnline: cloudlink,
    isHeartbeatOnline: heartbeat,
    sensors: [], // 센서는 나중에 Expand 시 로드
  );
}
