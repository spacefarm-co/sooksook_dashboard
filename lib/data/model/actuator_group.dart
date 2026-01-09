class ActuatorGroup {
  String id;
  String name;
  String? status;
  int order;
  List<String> actuatorIds;
  double? openRate;
  double? previousOpenRate;
  int? remainingTime;

  ActuatorGroup({
    required this.id,
    required this.name,
    this.status,
    required this.order,
    required this.actuatorIds,
    required this.openRate,
    required this.previousOpenRate,
    required this.remainingTime,
  });

  ActuatorGroup copyWith({
    String? id,
    String? name,
    String? status,
    int? order,
    List<String>? actuatorIds,
    double? openRate,
    double? previousOpenRate,
    int? remainingTime,
  }) {
    return ActuatorGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      order: order ?? this.order,
      actuatorIds: actuatorIds ?? this.actuatorIds,
      openRate: openRate ?? this.openRate,
      previousOpenRate: previousOpenRate ?? this.previousOpenRate,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }

  factory ActuatorGroup.fromJson(Map<String, dynamic> json, String id) {
    // actuator_ids가 null이거나 List가 아닐 경우 안전하게 처리
    final actuatorIdsRaw = json['actuator_ids'];
    List<String> nonNullActuatorIds = [];

    if (actuatorIdsRaw is List) {
      nonNullActuatorIds = actuatorIdsRaw
          .where((e) => e != null) // null 필터링
          .map((e) => e.toString()) // String 변환
          .toList();
    }

    return ActuatorGroup(
      id: id,
      name: json['name'] ?? '',
      status: json['status'] ?? 'open',
      order: json['order'] ?? 0,
      actuatorIds: nonNullActuatorIds,
      openRate: json['open_rate'] != null ? (json['open_rate'] as num).toDouble() : 0.0,
      previousOpenRate: json['previous_open_rate'] != null ? (json['previous_open_rate'] as num).toDouble() : 0.0,
      remainingTime: json['remaining_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'status': status,
      'order': order,
      'actuator_ids': actuatorIds,
      'open_rate': openRate,
      'previous_open_rate': previousOpenRate,
      'remaining_time': remainingTime,
    };
  }
}
