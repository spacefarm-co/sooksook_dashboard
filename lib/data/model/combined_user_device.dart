import 'sensor.dart';

class CombinedUserDevice {
  final String customerName;
  final String deviceName;
  final String? uuid;
  final String token;
  final bool isCloudlinkOnline;
  final bool isHeartbeatOnline;
  final List<Sensor> sensors;

  CombinedUserDevice({
    required this.customerName,
    required this.deviceName,
    this.uuid,
    required this.token,
    this.isCloudlinkOnline = false,
    this.isHeartbeatOnline = false,
    this.sensors = const [],
  });

  /// [추가] 디바이스 이름을 분석하여 지역명을 반환합니다.
  String get regionName {
    final name = deviceName.toUpperCase();

    // 1. 부산 대저 (PUS-KSP)
    if (name.contains('PUS-KSP')) return '대저';

    // 2. 밀양 (무안 MUA 포함 통합)
    if (name.contains('MRY')) return '밀양';

    // 3. 거창 (KCG)
    if (name.contains('KCG')) return '거창';

    return '기타';
  }

  // 쑥마스터 제외 로직
  List<Sensor> get pureSensors => sensors.where((s) => !s.name.toLowerCase().contains('sook master')).toList();

  int get activeSensorCount => pureSensors.where((s) => s.isActive).length;
  int get totalSensorCount => pureSensors.length;

  bool get isAllSensorsNormal => pureSensors.isNotEmpty && activeSensorCount == totalSensorCount;
}
