class LastUpdated {
  final String requestId;
  final String responseId;
  final String sookMasterToken;
  final bool success;
  final DateTime? updatedAt; // 추가된 컬럼

  LastUpdated({
    required this.requestId,
    required this.responseId,
    required this.sookMasterToken,
    required this.success,
    this.updatedAt,
  });

  factory LastUpdated.fromJson(Map<dynamic, dynamic> json) {
    final actuators = json['actuators'] ?? {};
    final String reqId = actuators['request_id']?.toString() ?? '';

    // requestId(ms 문자열)를 DateTime으로 변환
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
      responseId: actuators['response_id']?.toString() ?? '',
      sookMasterToken: actuators['sook_master_token']?.toString() ?? '',
      success: actuators['success'] ?? false,
      updatedAt: parsedDate, // 변환된 날짜 저장
    );
  }
}
