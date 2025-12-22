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

      // 해당 농가 찾기
      final customer = customers.data.firstWhere(
        (c) => c.title.trim() == customerName.trim(),
        orElse: () => throw Exception('고객을 찾을 수 없습니다: $customerName'),
      );

      // 해당 농가의 모든 디바이스 정보 가져오기
      final devices = await _tbClient.getDeviceService().getCustomerDeviceInfos(customer.id!.id!, PageLink(500));
      print('[TB] $customerName 센서 조회 성공, 총 디바이스 수: ${devices.totalElements}');
      // [수정 포인트] map으로 변환 후 where를 사용하여 쑥마스터를 제외합니다.
      return devices.data
          .map((d) => Sensor.fromJson(d.toJson(), d.active ?? false))
          .where((sensor) => !sensor.isSookMaster) // 👈 여기서 쑥마스터(Sook Master) 제거
          .toList();
    } catch (e) {
      print('[TB] $customerName 센서 조회 에러: $e');
      return [];
    }
  }
}
