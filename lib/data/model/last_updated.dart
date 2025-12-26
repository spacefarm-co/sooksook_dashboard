import 'package:finger_farm/data/model/actuator.dart';

class LastUpdated {
  final String requestId;
  final String responseId;
  final String sookMasterToken;
  final bool success;
  final DateTime? updatedAt;
  // [수정] dynamic이나 별도 모델이 아닌, 사용자님의 'Actuator' 객체 리스트를 받습니다.
  final List<Actuator> actuators;

  LastUpdated({
    required this.requestId,
    required this.responseId,
    required this.sookMasterToken,
    required this.success,
    this.updatedAt,
    this.actuators = const [],
  });

  factory LastUpdated.fromJson(Map<dynamic, dynamic> json) {
    // 1. actuators 리스트 파싱
    List<Actuator> actuatorList = [];
    final dynamic actuatorsData = json['actuators'];

    if (actuatorsData is List) {
      for (int i = 0; i < actuatorsData.length; i++) {
        final item = actuatorsData[i];
        if (item is Map) {
          // Actuator.fromJson 형식이 (id, map) 이므로 index나 특정 id를 넘겨줌
          actuatorList.add(Actuator.fromJson(item['id'] ?? i.toString(), item));
        }
      }
    } else if (actuatorsData is Map) {
      // Firebase에서 0, 1, 2 키값으로 올 경우 대응
      actuatorsData.forEach((key, value) {
        if (value is Map) {
          actuatorList.add(Actuator.fromJson(value['id'] ?? key.toString(), value));
        }
      });
    }

    // 2. 시간 정보 (request_id 기반)
    final String reqId = json['request_id']?.toString() ?? '';
    DateTime? parsedDate;
    if (reqId.isNotEmpty) {
      try {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(int.parse(reqId));
      } catch (e) {
        print('LastUpdated 날짜 변환 실패: $e');
      }
    }

    return LastUpdated(
      requestId: reqId,
      responseId: json['response_id']?.toString() ?? '',
      sookMasterToken: json['sook_master_token']?.toString() ?? '',
      success: json['success'] ?? false,
      updatedAt: parsedDate,
      actuators: actuatorList,
    );
  }
}
