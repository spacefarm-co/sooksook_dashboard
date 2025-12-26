import 'package:finger_farm/data/model/last_updated.dart';
import 'package:finger_farm/data/model/sensor.dart';

class CombinedUserDevice {
  // 1. 계층 정보 (Firestore 구조 반영)
  final String customerId; // 고객 문서 ID
  final String customerName; // 고객명
  final String farmId; // 농장 문서 ID
  final String facilityId; // [핵심] 시설 문서 ID (RTDB 조회용 키)
  final String facilityName; // 시설명 (예: 시설1)

  // 2. 장비 연결 정보 (Balena 및 SookMaster 기반)
  final String deviceName; // 기기명 (예: PUS-KSP-KDW-001-CTL-001)
  final String? uuid; // Balena UUID
  final String? token; // 쑥마스터 토큰
  final bool isCloudlinkOnline;
  final bool isHeartbeatOnline;

  // 3. 상태 데이터
  final List<Sensor> sensors;
  // final LastUpdated? lastUpdated;

  CombinedUserDevice({
    required this.customerId,
    required this.customerName,
    required this.farmId,
    required this.facilityId,
    required this.facilityName,
    required this.deviceName,
    this.uuid,
    this.token,
    this.isCloudlinkOnline = false,
    this.isHeartbeatOnline = false,
    this.sensors = const [],
    // this.lastUpdated,
  });

  /// [기능] 디바이스 이름을 분석하여 지역명 반환
  String get regionName {
    final name = deviceName.toUpperCase();
    if (name.contains('PUS-KSP')) return '대저';
    if (name.contains('MRY')) return '밀양';
    if (name.contains('KCG')) return '거창';
    return '기타';
  }

  // 센서 가동 상태 로직
  List<Sensor> get pureSensors => sensors.where((s) => !s.name.toLowerCase().contains('sook master')).toList();
  int get activeSensorCount => pureSensors.where((s) => s.isActive).length;
  int get totalSensorCount => pureSensors.length;
  bool get isAllSensorsNormal => pureSensors.isNotEmpty && activeSensorCount == totalSensorCount;

  // 데이터 업데이트를 위한 copyWith
  CombinedUserDevice copyWith({LastUpdated? lastUpdated}) {
    return CombinedUserDevice(
      customerId: customerId,
      customerName: customerName,
      farmId: farmId,
      facilityId: facilityId,
      facilityName: facilityName,
      deviceName: deviceName,
      uuid: uuid,
      token: token,
      isCloudlinkOnline: isCloudlinkOnline,
      isHeartbeatOnline: isHeartbeatOnline,
      sensors: sensors,
      // lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
