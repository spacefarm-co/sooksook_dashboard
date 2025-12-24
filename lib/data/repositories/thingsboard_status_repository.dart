import 'package:finger_farm/data/model/sensor.dart';
import 'package:finger_farm/data/model/sensor_data.dart';
import 'package:finger_farm/data/model/sensor_telemetry.dart';
import 'package:thingsboard_client/thingsboard_client.dart';
import '../../config/app_config.dart';

class ThingsBoardStatusRepository {
  late final ThingsboardClient _tbClient;
  Future<void>? _loginFuture;

  ThingsBoardStatusRepository() {
    _tbClient = ThingsboardClient(AppConfig().thingsBoardApiEndpoint);
  }

  Future<void> _ensureLoggedIn() async {
    if (_tbClient.isAuthenticated()) return;
    if (_loginFuture != null) return _loginFuture;

    _loginFuture = _performLogin();
    try {
      await _loginFuture;
    } finally {
      _loginFuture = null;
    }
  }

  Future<void> _performLogin() async {
    Object? lastError;
    final String username = "tenant@spacefarm.co.kr";
    final String password = "HeetsCoffe1!";

    print('[TB] 로그인 시도 중...');
    for (int i = 0; i < 3; i++) {
      try {
        await _tbClient.login(LoginRequest(username, password));
        print('[TB] 로그인 성공');
        return;
      } catch (e) {
        lastError = e;
        print('[TB] 로그인 실패 (시도 ${i + 1}/3): $e');
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
    throw lastError ?? Exception('TB 로그인 최종 실패');
  }

  /// 농가(고객)의 모든 센서 정보와 최신 텔레메트리를 함께 가져옵니다.
  /// 농가(고객)의 모든 센서 정보와 최신 텔레메트리를 함께 가져옵니다.
  Future<List<Sensor>> getCustomerSensorsStatus(String customerName, int index) async {
    try {
      await _ensureLoggedIn();
      await Future.delayed(Duration(milliseconds: 500 * index));

      // 1. 고객 정보 조회
      final customers = await _tbClient.getCustomerService().getCustomers(PageLink(200));
      final customer = customers.data.firstWhere(
        (c) => c.title.trim() == customerName.trim(),
        orElse: () => throw Exception('고객을 찾을 수 없습니다: $customerName'),
      );

      // 2. 해당 고객의 모든 기기 정보 조회
      final devices = await _tbClient.getDeviceService().getCustomerDeviceInfos(customer.id!.id!, PageLink(500));
      final filteredDevices = devices.data.where((d) => !d.type.contains('Sook Master')).toList();

      List<Sensor> sensorList = [];

      // 3. 각 기기별 텔레메트리 조회 및 매핑
      // getCustomerSensorsStatus 메서드 내부 루프 수정
      for (var device in filteredDevices) {
        try {
          final List<TsKvEntry> latestTelemetry = await _tbClient.getAttributeService().getLatestTimeseries(
            device.id!,
            [],
          );

          List<SensorData> extractedMeasurements = [];
          int? battery;
          int? rssi;

          // 1. 전체 리스트를 돌며 'Name'이 포함된 키를 먼저 찾습니다.
          for (var entry in latestTelemetry) {
            String key = entry.getKey();

            // 통신/상태 데이터 처리
            if (key == 'rssi') rssi = entry.getValue();
            if (key.contains('battery') && !key.contains('unavailable')) {
              battery = entry.getValue();
            }

            // 센서 데이터 동적 매핑 (Name과 Value 쌍 찾기)
            if (key.contains('measurementName')) {
              // 이름 키: data_messages_0_measurementName
              // 값 키 생성: data_messages_0_measurementValue (Name을 Value로 치환)
              String valueKey = key.replaceAll('Name', 'Value');

              try {
                // 동일한 인덱스의 Value 항목을 찾습니다.
                var valueEntry = latestTelemetry.firstWhere((e) => e.getKey() == valueKey);

                extractedMeasurements.add(
                  SensorData(
                    name: entry.getValue().toString(), // 예: "temperature"
                    value: valueEntry.getValue(), // 예: 29.45
                    date: DateTime.fromMillisecondsSinceEpoch(entry.getTs()),
                  ),
                );
              } catch (e) {
                // 매칭되는 Value 키가 없는 경우 (TSR 센서 등 구조가 다른 경우 대응)
                print('Value match not found for $key');
              }
            }
          }

          // 2. 최종 결과물 모델에 담기
          sensorList.add(
            Sensor.fromJson(
              device.toJson(),
              device.active ?? false,
            ).copyWith(telemetry: SensorTelemetry(measurements: extractedMeasurements, battery: battery, rssi: rssi)),
          );
        } catch (e) {
          print('Error parsing device ${device.name}: $e');
        }
      }

      print('[TB] $index번 농가($customerName) 완료: 기기 ${sensorList.length}개');
      return sensorList;
    } catch (e) {
      print('[TB] $customerName 최종 조회 에러: $e');
      return [];
    }
  }
}
