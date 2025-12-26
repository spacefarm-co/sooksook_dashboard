class Facility {
  final String id; // Firestore Document ID (RTDB의 facilities 하위 키와 동일)
  final String name;
  final String? sookMasterToken;
  final DateTime? createdAt;

  Facility({required this.id, required this.name, this.sookMasterToken, this.createdAt});

  factory Facility.fromFirestore(String id, Map<String, dynamic> json) {
    return Facility(
      id: id, // 이 ID가 질문하신 '패실리티 id'입니다.
      name: json['name'] ?? '',
      sookMasterToken: json['sook_master_token'],
      createdAt: json['created_at'] != null ? (json['created_at'] as DateTime) : null,
    );
  }
}
