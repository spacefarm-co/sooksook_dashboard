class JiraIssue {
  final String key; // 티켓 번호 (예: TS2-123)
  final String summary; // 티켓 제목
  final String status; // 상태 (진행중, 완료 등)
  final DateTime updated; // 수정일
  final String projectKey; // 프로젝트 구분 (TS2, OPEN25)

  JiraIssue({
    required this.key,
    required this.summary,
    required this.status,
    required this.updated,
    required this.projectKey,
  });

  factory JiraIssue.fromJson(Map<String, dynamic> json) {
    return JiraIssue(
      key: json['key'],
      summary: json['fields']['summary'],
      status: json['fields']['status']['name'],
      updated: DateTime.parse(json['fields']['updated']),
      projectKey: json['fields']['project']['key'],
    );
  }
}
