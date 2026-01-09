// lib/data/providers/actuator_groups_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/actuator_group.dart';
import '../repositories/realtime_database_repository.dart';

// 레포지토리 인스턴스 (이미 있다면 기존 것 사용)
final realtimeDatabaseRepositoryProvider = Provider((ref) => RealtimeDatabaseRepository());

// 시설 ID별 액추에이터 그룹 스트림 프로바이더
final actuatorGroupsProvider = StreamProvider.family<List<ActuatorGroup>, String>((ref, facilityId) {
  final repo = ref.watch(realtimeDatabaseRepositoryProvider);
  return repo.watchActuatorGroups(facilityId);
});
