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

  if (customersAsync.hasValue && balenaAsync.hasValue) {
    final customers = customersAsync.value!.docs;
    final balenaDocs = balenaAsync.value!.docs;
    final customerMap = {for (var doc in customers) doc.id: doc};

    final allFacilities = await FirebaseFirestore.instance.collectionGroup('facilities').get();
    final List<Future<CombinedUserDevice>> futures = [];

    for (var facDoc in allFacilities.docs) {
      final facData = facDoc.data();
      final facilityId = facDoc.id;
      final facilityName = facData['name'] ?? '시설명 없음';
      final facilityToken = facData['sook_master_token'];

      final farmRef = facDoc.reference.parent.parent;
      final custRef = farmRef?.parent.parent;

      if (custRef != null && customerMap.containsKey(custRef.id)) {
        final custDoc = customerMap[custRef.id]!;
        final custData = custDoc.data() as Map<String, dynamic>;
        final customerName = custData['name'] ?? 'Unknown'; // 고객명 추출
        final sookMasterList = custData['sook_master'] as List? ?? [];

        final matchedMaster = sookMasterList.firstWhere((m) => m['token'] == facilityToken, orElse: () => null);

        if (matchedMaster != null) {
          final mName = matchedMaster['name'] ?? '';

          // [로그 추가] 현재 로드 중인 유저와 시설 정보를 터미널에 출력합니다.
          print('🔍 유저 로드 중: 고객명($customerName) | 시설($facilityName) | 장치($mName)');

          final matchedDev =
              balenaDocs.where((d) {
                final dData = d.data() as Map<String, dynamic>;
                return dData['device_name'] == mName;
              }).firstOrNull;

          final uuid = (matchedDev?.data() as Map<String, dynamic>?)?['uuid'];

          // [로그 추가] Balena UUID 매칭 결과 출력
          if (uuid != null) {
            print('   ✅ Balena UUID 매칭 성공: $uuid');
          } else {
            print('   ⚠️ Balena UUID 매칭 실패 (Device Name 불일치 가능성)');
          }

          futures.add(
            _fetchBasicStatuses(
              connectivityRepo,
              custRef.id,
              customerName,
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
