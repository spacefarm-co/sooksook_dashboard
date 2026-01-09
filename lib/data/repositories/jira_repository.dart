import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../model/jira_issue.dart';

class JiraRepository {
  final String domain = "soungno.atlassian.net";
  final String email = "noah@spacefarm.co.kr";
  final String apiToken = dotenv.get('JIRA_API_TOKEN', fallback: "");

  Future<List<JiraIssue>> searchIssuesByCustomer(String customerName) async {
    if (customerName.isEmpty) return [];

    // 최신 API 경로: /rest/api/3/search/jql
    // 쿼리 파라미터로 jql을 전달합니다.
    final queryParameters = {
      'jql':
          'project IN ("TSFSS2", "OPEN25") AND (summary ~ "$customerName" OR text ~ "$customerName") ORDER BY updated DESC',
    };

    final Uri url = Uri.https(domain, '/rest/api/3/search/jql', queryParameters);
    final String auth = 'Basic ${base64Encode(utf8.encode('$email:$apiToken'))}';

    try {
      final response = await http.get(url, headers: {'Authorization': auth, 'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List issues = data['issues'] ?? [];
        return issues.map((json) => JiraIssue.fromJson(json)).toList();
      } else {
        // 410 에러 방지를 위해 경로가 제대로 바뀌었는지 확인 로그 출력
        debugPrint('Jira API Error (${response.statusCode}): ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Jira Request Exception: $e');
      return [];
    }
  }
}
