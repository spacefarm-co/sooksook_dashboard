import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/actuator.dart';
import '../repositories/realtime_database_repository.dart';

// 레포지토리 프로바이더 (이미 있다면 기존 것 사용)
final realtimeDatabaseRepositoryProvider = Provider((ref) => RealtimeDatabaseRepository());

// [핵심] RTDB의 액추에이터 리스트를 실시간으로 받아오는 스트림 프로바이더
final actuatorsProvider = StreamProvider.family<List<Actuator>, String>((ref, facilityId) {
  final repo = ref.watch(realtimeDatabaseRepositoryProvider);

  // RTDB의 특정 경로(facilities/ID/actuators)를 스트림으로 구독
  return repo.watchActuators(facilityId);
});
