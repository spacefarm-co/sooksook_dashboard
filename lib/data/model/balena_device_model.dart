class BalenaDeviceModel {
  final String uuid;
  final String deviceName;
  final bool isOnline;
  final String status; // api_heartbeat_state
  final String? facilityId; // Balena 환경변수에서 추출한 마스터 키
  final DateTime? updatedAt;

  BalenaDeviceModel({
    required this.uuid,
    required this.deviceName,
    required this.isOnline,
    required this.status,
    this.facilityId,
    this.updatedAt,
  });

  // Balena API 응답(JSON)을 모델로 변환하는 팩토리 메서드
  factory BalenaDeviceModel.fromApi(Map<String, dynamic> json) {
    // 환경 변수 배열에서 FacilityId 추출 로직
    final vars = json['device_environment_variable'] as List? ?? [];
    final String? fId = vars.isNotEmpty ? vars.first['value'] : null;

    return BalenaDeviceModel(
      uuid: json['uuid'] ?? '',
      deviceName: json['device_name'] ?? 'Unknown',
      isOnline: json['is_online'] ?? false,
      status: json['api_heartbeat_state'] ?? 'offline',
      facilityId: fId,
      updatedAt: DateTime.now(), // 로드 시점 기록
    );
  }

  // 기존 Firestore용 팩토리 메서드 (필요시 유지)
  factory BalenaDeviceModel.fromFirestore(Map<String, dynamic> data) {
    return BalenaDeviceModel(
      uuid: data['uuid'] ?? '',
      deviceName: data['device_name'] ?? '',
      isOnline: data['is_online'] ?? false,
      status: data['status'] ?? 'offline',
      facilityId: data['facilityId'],
      updatedAt: data['updated_at']?.toDate(),
    );
  }
}
