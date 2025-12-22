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

    final List<CombinedUserDevice> results = [];

    // [핵심 수정] Future.wait 대신 for 루프를 사용하여 순차적으로 처리합니다.
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

        // 개별 디바이스 상태 조회 (await를 사용하여 하나가 끝날 때까지 기다림)
        final combinedDevice = await _fetchAllStatuses(connectivityRepo, tbRepo, customerName, mName, uuid, token);

        results.add(combinedDevice);

        // [429 에러 방지] 서버 부하를 줄이기 위해 요청 사이에 아주 짧은 지연(50ms)을 둡니다.
        // 농가 수가 많다면 이 시간을 100ms 정도로 늘려보세요.
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    yield results;
  } else {
    yield [];
  }
});

// 모든 플랫폼 상태 통합 호출 함수 (내용은 동일하되 안정성 강화)
Future<CombinedUserDevice> _fetchAllStatuses(
  ConnectivityRepository balenaRepo,
  ThingsBoardStatusRepository tbRepo,
  String customerName,
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

  // ThingsBoard API 호출 (Rate Limit에 가장 취약한 부분)
  List<Sensor> sensors = [];
  try {
    sensors = await tbRepo.getCustomerSensorsStatus(customerName);
  } catch (e) {
    print('ThingsBoard API Error ($customerName): $e');
  }

  return CombinedUserDevice(
    customerName: customerName,
    deviceName: deviceName,
    uuid: uuid,
    token: token,
    isCloudlinkOnline: cloudlink,
    isHeartbeatOnline: heartbeat,
    sensors: sensors,
  );
}
