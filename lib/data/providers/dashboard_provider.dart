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
    final customerDocs = customersAsync.value!.docs;
    final balenaDocs = balenaAsync.value!.docs;
    final List<Future<CombinedUserDevice>> futures = [];

    for (var custDoc in customerDocs) {
      final custData = custDoc.data() as Map<String, dynamic>;
      final customerId = custDoc.id;
      final customerName = custData['name'] ?? 'Unknown';
      final sookMasterList = custData['sook_master'] as List? ?? [];

      // 하위 컬렉션 'farms' 가져오기
      final farmsSnapshot = await custDoc.reference.collection('farms').get();

      for (var farmDoc in farmsSnapshot.docs) {
        final farmId = farmDoc.id;

        // 하위 컬렉션 'facilities' 가져오기
        final facilitiesSnapshot = await farmDoc.reference.collection('facilities').get();

        for (var facDoc in facilitiesSnapshot.docs) {
          final facData = facDoc.data();
          final facilityId = facDoc.id; // RTDB 매칭용 ID
          final facilityName = facData['name'] ?? '시설명 없음';
          final facilityToken = facData['sook_master_token'];

          // 시설 토큰과 일치하는 쑥마스터 정보 매핑
          final matchedMaster = sookMasterList.firstWhere((m) => m['token'] == facilityToken, orElse: () => null);

          if (matchedMaster != null) {
            final mName = matchedMaster['name'] ?? '';
            final mToken = matchedMaster['token'] ?? '';

            // Balena 기기 UUID 매핑
            final matchedDev =
                balenaDocs.where((d) {
                  final dData = d.data() as Map<String, dynamic>;
                  return dData['device_name'] == mName;
                }).firstOrNull;

            final uuid = (matchedDev?.data() as Map<String, dynamic>?)?['uuid'];

            futures.add(
              _fetchBasicStatuses(
                connectivityRepo,
                customerId,
                customerName,
                farmId,
                facilityId,
                facilityName,
                mName,
                uuid,
                mToken,
              ),
            );
          }
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
