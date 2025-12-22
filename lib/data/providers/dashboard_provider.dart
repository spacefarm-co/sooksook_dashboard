import 'package:finger_farm/data/model/sensor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/combined_user_device.dart';
import 'customer_provider.dart';
import 'balena_device_provider.dart';
import '../repositories/connectivity_repository.dart';
import '../repositories/thingsboard_status_repository.dart';

final connectivityRepositoryProvider = Provider((ref) => ConnectivityRepository());
final tbStatusRepositoryProvider = Provider((ref) => ThingsBoardStatusRepository());

final dashboardProvider = StreamProvider<List<CombinedUserDevice>>((ref) async* {
  final connectivityRepo = ref.watch(connectivityRepositoryProvider);

  final customersAsync = ref.watch(customersProvider);
  final balenaAsync = ref.watch(balenaDevicesProvider);

  if (customersAsync.hasValue && balenaAsync.hasValue) {
    final customers = customersAsync.value!.docs;
    final balenaDocs = balenaAsync.value!.docs;

    final List<CombinedUserDevice> results = [];

    // 이제 TB API를 기다릴 필요가 없으므로 병렬 처리가 가능합니다.
    // Future.wait를 사용하여 Balena 정보만 빠르게 가져옵니다.
    final List<Future<CombinedUserDevice>> futures = [];

    for (var custDoc in customers) {
      final custData = custDoc.data() as Map<String, dynamic>;
      final customerName = custData['name'] ?? 'Unknown';
      final regionName = custData['region_name'] ?? '알수없음'; // 지역 정보 추가
      final sookMasterList = custData['sook_master'] as List? ?? [];

      for (var master in sookMasterList) {
        final mName = master['name'] ?? '';
        final token = master['token'] ?? '';

        final matchedDev =
            balenaDocs.where((d) => (d.data() as Map<String, dynamic>)['device_name'] == mName).firstOrNull;

        final uuid = (matchedDev?.data() as Map<String, dynamic>?)?['uuid'];

        // TB 호출을 제거한 가벼운 상태 조회 함수 호출
        futures.add(_fetchBasicStatuses(connectivityRepo, customerName, regionName, mName, uuid, token));
      }
    }

    final combinedResults = await Future.wait(futures);
    yield combinedResults;
  } else {
    yield [];
  }
});

/// ThingsBoard 호출을 제외하고 Balena 상태만 빠르게 가져오는 함수
Future<CombinedUserDevice> _fetchBasicStatuses(
  ConnectivityRepository balenaRepo,
  String customerName,
  String regionName,
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

  // 핵심: Sensors는 빈 리스트로 반환합니다.
  // 실제 데이터는 UI에서 Expand 할 때 가져옵니다.
  return CombinedUserDevice(
    customerName: customerName,
    deviceName: deviceName,
    uuid: uuid,
    token: token,
    isCloudlinkOnline: cloudlink,
    isHeartbeatOnline: heartbeat,
    sensors: [],
  );
}
