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
  final tbRepo = ref.watch(tbStatusRepositoryProvider);

  final customersAsync = ref.watch(customersProvider);
  final balenaAsync = ref.watch(balenaDevicesProvider);

  if (customersAsync.hasValue && balenaAsync.hasValue) {
    final customers = customersAsync.value!.docs;
    final balenaDocs = balenaAsync.value!.docs;

    final List<Future<CombinedUserDevice>> futures = [];

    for (var custDoc in customers) {
      final custData = custDoc.data() as Map<String, dynamic>;
      final customerName = custData['name'] ?? 'Unknown';
      final sookMasterList = custData['sook_master'] as List? ?? [];

      for (var master in sookMasterList) {
        final mName = master['name'] ?? '';
        final token = master['token'] ?? '';

        // Balena UUID 매칭
        final matchedDev =
            balenaDocs.where((d) => (d.data() as Map<String, dynamic>)['device_name'] == mName).firstOrNull;

        final uuid = (matchedDev?.data() as Map<String, dynamic>?)?['uuid'];

        // 개별 디바이스 상태 조회 및 통합 작업을 Future 리스트에 추가
        futures.add(_fetchAllStatuses(connectivityRepo, tbRepo, customerName, mName, uuid, token));
      }
    }

    // 모든 비동기 작업(Balena API + ThingsBoard API)을 병렬로 대기
    final results = await Future.wait(futures);
    yield results;
  } else {
    // 데이터 로딩 중이거나 값이 없을 때 빈 리스트 반환
    yield [];
  }
});

// 모든 플랫폼 상태 통합 호출 함수 (Balena + ThingsBoard)
Future<CombinedUserDevice> _fetchAllStatuses(
  ConnectivityRepository balenaRepo,
  ThingsBoardStatusRepository tbRepo,
  String customerName,
  String deviceName,
  String? uuid,
  String token,
) async {
  // 1. Balena 상태 조회 (Cloudlink, Heartbeat)
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

  // 2. ThingsBoard 상세 센서 정보 조회 (SensorModel 리스트 반환)
  // 이제 단순한 bool 리스트가 아닌 상세 정보가 담긴 SensorModel 객체들을 가져옵니다.
  final List<Sensor> sensors = await tbRepo.getCustomerSensorsStatus(customerName);

  return CombinedUserDevice(
    customerName: customerName,
    deviceName: deviceName,
    uuid: uuid,
    token: token,
    isCloudlinkOnline: cloudlink,
    isHeartbeatOnline: heartbeat,
    sensors: sensors, // List<SensorModel> 타입으로 주입
  );
}
