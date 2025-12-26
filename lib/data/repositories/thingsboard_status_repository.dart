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
      // 농가별 초기 진입 지연
      await Future.delayed(Duration(milliseconds: 200 * index));

      // 1. 고객 정보 조회
      final customers = await _tbClient.getCustomerService().getCustomers(PageLink(200));
      final customer = customers.data.firstWhere(
        (c) => c.title.trim() == customerName.trim(),
        orElse: () => throw Exception('고객을 찾을 수 없습니다: $customerName'),
      );

      // 2. 해당 고객의 기기 정보 조회 (페이지네이션)
      // 센서 값을 가져오지 않으므로 한 페이지 당 개수를 조금 더 늘려도 안전합니다.
      final devices = await _tbClient.getDeviceService().getCustomerDeviceInfos(customer.id!.id!, PageLink(10));

      // 3. 'Sook Master' 제외 및 Sensor 객체로 변환
      // 텔레메트리 루프를 돌지 않고 바로 매핑하여 처리 속도가 매우 빠릅니다.
      final List<Sensor> sensorList =
          devices.data
              .where((d) => !d.type.contains('Sook Master'))
              .map((device) => Sensor.fromJson(device.toJson(), device.active ?? false))
              .toList();

      print('[TB] $index번 농가($customerName) 기기 목록 로드 완료: ${sensorList.length}개');
      return sensorList;
    } catch (e) {
      print('[TB] $customerName 목록 조회 에러: $e');
      return [];
    }
  }

  Future<List<Sensor>> getDetailedSensorTelemetry(String customerName) async {
    try {
      await _ensureLoggedIn();

      // 1. 고객 정보 조회
      final customers = await _tbClient.getCustomerService().getCustomers(PageLink(200));
      final customer = customers.data.firstWhere(
        (c) => c.title.trim() == customerName.trim(),
        orElse: () => throw Exception('고객을 찾을 수 없습니다: $customerName'),
      );

      // 2. 해당 고객의 기기 목록 조회
      final devices = await _tbClient.getDeviceService().getCustomerDeviceInfos(customer.id!.id!, PageLink(100));
      final filteredDevices = devices.data.where((d) => !d.type.contains('Sook Master')).toList();

      List<Sensor> detailedSensors = [];

      // 3. 각 기기별 텔레메트리 상세 조회 루프
      for (var device in filteredDevices) {
        try {
          // 너무 빠른 요청으로 인한 에러 방지를 위해 미세한 지연 추가
          await Future.delayed(Duration(milliseconds: 50));

          // 해당 기기의 최신 텔레메트리 전부 가져오기
          final List<TsKvEntry> latestTelemetry = await _tbClient.getAttributeService().getLatestTimeseries(
            device.id!,
            [],
          );

          List<SensorData> extractedMeasurements = [];
          int? battery;
          int? rssi;

          for (var entry in latestTelemetry) {
            String key = entry.getKey();

            // 공통 정보 파싱
            if (key == 'rssi') rssi = (entry.getValue() as num?)?.toInt();
            if (key.contains('battery') && !key.contains('unavailable')) {
              battery = (entry.getValue() as num?)?.toInt();
            }

            // SensorData 매핑 로직 (measurementName과 measurementValue 쌍 찾기)
            if (key.contains('measurementName')) {
              String valueKey = key.replaceAll('Name', 'Value');
              try {
                var valueEntry = latestTelemetry.firstWhere((e) => e.getKey() == valueKey);
                extractedMeasurements.add(
                  SensorData(
                    name: entry.getValue().toString(),
                    value: valueEntry.getValue(),
                    date: DateTime.fromMillisecondsSinceEpoch(entry.getTs()),
                  ),
                );
              } catch (e) {
                // 매칭되는 Value가 없는 경우 스킵
              }
            }
          }

          // Sensor 객체 생성 및 Telemetry 주입
          detailedSensors.add(
            Sensor.fromJson(
              device.toJson(),
              device.active ?? false,
            ).copyWith(telemetry: SensorTelemetry(measurements: extractedMeasurements, battery: battery, rssi: rssi)),
          );
        } catch (e) {
          print('[TB] 기기 상세 파싱 에러 (${device.name}): $e');
          // 에러 시 기본 정보라도 담아서 추가
          detailedSensors.add(Sensor.fromJson(device.toJson(), device.active ?? false));
        }
      }

      print('[TB] $customerName 상세 데이터 로드 완료: ${detailedSensors.length}개');
      return detailedSensors;
    } catch (e) {
      print('[TB] $customerName 상세 조회 중 최종 에러: $e');
      return [];
    }
  }
}
