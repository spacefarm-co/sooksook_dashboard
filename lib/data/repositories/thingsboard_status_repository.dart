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

    // 파일에서 정보를 읽어옵니다.
    // final String username = dotenv.get('TB_USERNAME');
    // final String password = dotenv.get('TB_PASSWORD');
    final String username = "tenant@spacefarm.co.kr";
    final String password = "HeetsCoffe1!";
    print('[TB] 로그인 시도 중...');
    print('[TB] 사용자명: $username');
    print('[TB] 비밀번호 길이: ${password.length}');
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

  /// 농가(고객)의 모든 센서 정보를 모델 리스트로 가져옵니다.
  Future<List<Sensor>> getCustomerSensorsStatus(String customerName, int index) async {
    try {
      await _ensureLoggedIn();

      // 1. 순차적 로딩을 위한 인덱스 기반 딜레이
      // 위에서부터 차례대로 로딩되는 시각적 효과와 서버 부하 분산 효과를 동시에 얻습니다.
      await Future.delayed(Duration(milliseconds: 500 * index));

      final customers = await _tbClient.getCustomerService().getCustomers(PageLink(200));

      final customer = customers.data.firstWhere(
        (c) => c.title.trim() == customerName.trim(),
        orElse: () => throw Exception('고객을 찾을 수 없습니다: $customerName'),
      );

      final devices = await _tbClient.getDeviceService().getCustomerDeviceInfos(customer.id!.id!, PageLink(500));

      print('[TB] $index번 농가($customerName) 로딩 완료');

      return devices.data
          .where((d) => !(d.type).contains('Sook Master'))
          .map((d) => Sensor.fromJson(d.toJson(), d.active ?? false))
          .toList();
    } catch (e) {
      // 429 에러 발생 시 로그 출력
      if (e.toString().contains('429')) {
        print('[TB] $customerName 로딩 실패: 요청이 너무 많습니다(429). 딜레이를 조절하세요.');
      } else {
        print('[TB] $customerName 조회 에러: $e');
      }
      return [];
    }
  }
}
