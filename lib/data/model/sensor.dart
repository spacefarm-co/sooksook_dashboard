import 'package:finger_farm/data/model/sensor_telemetry.dart';

class Sensor {
  final String id;
  final String name;
  final String type;
  final String deviceProfileId;
  final int createdTime;
  final bool isActive;
  // [추가] SensorTelemetry 필드가 클래스 멤버로 선언되어야 합니다.
  final SensorTelemetry? telemetry;

  Sensor({
    required this.id,
    required this.name,
    required this.type,
    required this.deviceProfileId,
    required this.createdTime,
    required this.isActive,
    this.telemetry, // 생성자에 추가
  });

  bool get isSookMaster => type.contains('Sook Master');

  // [수정] copyWith에서 모든 필드를 유지하도록 변경
  Sensor copyWith({String? id, String? name, bool? isActive, SensorTelemetry? telemetry}) {
    return Sensor(
      id: id ?? this.id,
      name: name ?? this.name,
      type: this.type, // 기존 값 유지
      deviceProfileId: this.deviceProfileId, // 기존 값 유지
      createdTime: this.createdTime, // 기존 값 유지
      isActive: isActive ?? this.isActive,
      telemetry: telemetry ?? this.telemetry,
    );
  }

  factory Sensor.fromJson(Map<String, dynamic> json, bool activeStatus) {
    return Sensor(
      id: json['id']?['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      deviceProfileId: json['deviceProfileId']?['id'] ?? '',
      createdTime: json['createdTime'] ?? 0,
      isActive: activeStatus,
      // telemetry는 나중에 Repository에서 copyWith로 넣어줄 것이므로 기본값은 null입니다.
    );
  }
}
