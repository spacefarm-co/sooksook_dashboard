import 'package:finger_farm/data/model/jira_issue.dart';
import 'package:finger_farm/data/repositories/jira_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final jiraRepositoryProvider = Provider((ref) => JiraRepository());

// 고객 이름을 매개변수로 받아 실시간(Future)으로 티켓 목록을 가져옵니다.
final jiraIssuesProvider = FutureProvider.family<List<JiraIssue>, String>((ref, customerName) async {
  if (customerName.isEmpty) return [];
  final repo = ref.watch(jiraRepositoryProvider);
  return await repo.searchIssuesByCustomer(customerName);
});
