class BalenaDeviceModel {
  final String uuid;
  final String deviceName; // (예: PUS-KSP-KDW-001-CTL-001)
  final DateTime? updatedAt;

  BalenaDeviceModel({required this.uuid, required this.deviceName, this.updatedAt});

  factory BalenaDeviceModel.fromFirestore(Map<String, dynamic> data) {
    return BalenaDeviceModel(
      uuid: data['uuid'] ?? '',
      deviceName: data['device_name'] ?? '',
      updatedAt: data['updated_at']?.toDate(),
    );
  }
}
