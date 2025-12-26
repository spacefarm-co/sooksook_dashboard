class SookMaster {
  final String id;
  final String name;
  final String token;

  SookMaster({required this.id, required this.name, required this.token});

  factory SookMaster.fromJson(Map<String, dynamic> json) {
    return SookMaster(id: json['id'] ?? '', name: json['name'] ?? '', token: json['token'] ?? '');
  }
}
