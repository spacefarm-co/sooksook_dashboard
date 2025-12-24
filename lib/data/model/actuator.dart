class Actuator {
  final String id;
  final Map<String, int> channel;
  String name;
  final String status;
  final String? type;
  final int unit;
  int order;
  int? priority;
  String? priorityInterval;
  bool favorite;
  int? limitTime;
  int? travelTime;
  double? openRate;
  double? previousOpenRate;
  int? remainingTime;
  bool isCalibrating;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Actuator({
    required this.id,
    required this.channel,
    required this.name,
    required this.status,
    required this.type,
    required this.unit,
    required this.order,
    this.priority,
    this.priorityInterval,
    this.favorite = false,
    this.limitTime,
    this.travelTime,
    this.openRate,
    this.previousOpenRate,
    this.remainingTime,
    this.isCalibrating = false,
    this.createdAt,
    this.updatedAt,
  });

  Actuator copyWith({
    String? id,
    Map<String, int>? channel,
    String? name,
    String? status,
    String? type,
    int? unit,
    int? order,
    int? priority,
    String? priorityInterval,
    bool? favorite,
    int? limitTime,
    int? travelTime,
    double? openRate,
    double? previousOpenRate,
    int? remainingTime,
    bool? isCalibrating,
  }) {
    return Actuator(
      id: id ?? this.id,
      channel: channel ?? this.channel,
      name: name ?? this.name,
      status: status ?? this.status,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      order: order ?? this.order,
      priority: priority ?? this.priority,
      priorityInterval: priorityInterval ?? this.priorityInterval,
      favorite: favorite ?? this.favorite,
      limitTime: limitTime ?? this.limitTime,
      travelTime: travelTime ?? this.travelTime,
      openRate: openRate ?? this.openRate,
      previousOpenRate: previousOpenRate ?? this.previousOpenRate,
      remainingTime: remainingTime ?? this.remainingTime,
      isCalibrating: isCalibrating ?? this.isCalibrating,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Actuator.fromJson(String id, Map json) {
    final channelData = json['channel'];
    Map<String, int> channelMap = {};

    if (channelData is Map) {
      channelMap = Map<String, int>.from(channelData);
    } else {
      print('Error Actuator fromJson');
    }

    return Actuator(
      id: id,
      channel: channelMap,
      name: json['name'],
      status: json['status'] ?? 'close',
      type: json['type'],
      unit: json['unit'],
      order: json['order'] ?? 0,
      priority: json['priority'],
      priorityInterval: convertSecondsToPriorityInterval(json['priority_interval']),
      favorite: json['favorite'] ?? false,
      limitTime: json['limit_time'],
      travelTime: json['travel_time'],
      openRate: json['open_rate'] != null ? (json['open_rate'] as num).toDouble() : 0.0,
      previousOpenRate: json['previous_open_rate'] != null ? (json['previous_open_rate'] as num).toDouble() : 0.0,
      remainingTime: json['remaining_time'],
      createdAt: json['created_at']?.toDate(),
      updatedAt: json['updated_at']?.toDate(),
    );
  }

  Map<String, dynamic> toJson({status}) {
    return {
      'id': id,
      'channel': channel,
      'name': name,
      'status': status ?? this.status,
      'type': type,
      'unit': unit,
      'order': order,
      'priority': priority,
      'priority_interval': convertPriorityIntervalToSeconds(priorityInterval),
      'favorite': favorite,
      'limit_time': limitTime,
      'travel_time': travelTime,
      'open_rate': openRate,
      'previous_open_rate': previousOpenRate,
      'remaining_time': remainingTime,
    };
  }

  static int? convertPriorityIntervalToSeconds(String? priorityInterval) {
    switch (priorityInterval) {
      case '1분':
        return 60;
      case '2분':
        return 120;
      case '3분':
        return 180;
      case '4분':
        return 240;
      case '5분':
        return 300;
      default:
        return null;
    }
  }

  static String? convertSecondsToPriorityInterval(int? seconds) {
    switch (seconds) {
      case 60:
        return '1분';
      case 120:
        return '2분';
      case 180:
        return '3분';
      case 240:
        return '4분';
      case 300:
        return '5분';
      default:
        return null;
    }
  }

  static String channelKo(actuator) {
    return actuator.type == '모터'
        ? '열기: ${actuator.channel['open']}, 닫기: ${actuator.channel['close']}'
        : '전원: ${actuator.channel['power']}';
  }

  static String statusKo(String status) {
    switch (status) {
      case 'open':
        return '열림';
      case 'close':
        return '닫힘';
      case 'stop':
        return '정지';
      default:
        return '';
    }
  }
}
