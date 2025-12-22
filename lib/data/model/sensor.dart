class Sensor {
  final String id;
  final String name;
  final String type; // 'Sook Master' 등이 들어옴
  final String deviceProfileId;
  final int createdTime;
  final bool isActive;

  Sensor({
    required this.id,
    required this.name,
    required this.type,
    required this.deviceProfileId,
    required this.createdTime,
    required this.isActive,
  });

  // 쑥마스터인지 확인하는 게터
  bool get isSookMaster => type.contains('Sook Master');

  factory Sensor.fromJson(Map<String, dynamic> json, bool activeStatus) {
    return Sensor(
      id: json['id']?['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      deviceProfileId: json['deviceProfileId']?['id'] ?? '',
      createdTime: json['createdTime'] ?? 0,
      isActive: activeStatus,
    );
  }
}
