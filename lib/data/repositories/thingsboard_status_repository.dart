import 'package:finger_farm/data/model/sensor.dart';
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
    for (int i = 0; i < 3; i++) {
      try {
        await _tbClient.login(LoginRequest('tenant@spacefarm.co.kr', 'HeetsCoffe1!'));
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

  /// 농가(고객)의 모든 센서 정보를 모델 리스트로 가져옵니다.
  Future<List<Sensor>> getCustomerSensorsStatus(String customerName) async {
    try {
      await _ensureLoggedIn();
      final customers = await _tbClient.getCustomerService().getCustomers(PageLink(200));
      final customer = customers.data.firstWhere((c) => c.title.trim() == customerName.trim());

      final devices = await _tbClient.getDeviceService().getCustomerDeviceInfos(customer.id!.id!, PageLink(500));

      return devices.data.map((d) {
        // d.active는 DeviceInfo의 필드이므로 직접 전달
        // 모델 정의에 맞춰서 인자 2개를 보냅니다.
        return Sensor.fromRawJson(d.toJson(), d.active ?? false);
      }).toList();
    } catch (e) {
      print('ThingsBoard 조회 에러: $e');
      return [];
    }
  }
}
