import 'package:finger_farm/data/model/last_updated.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/realtime_database_repository.dart';

// 1. Repository Provider
final realtimeDatabaseRepositoryProvider = Provider((ref) {
  return RealtimeDatabaseRepository();
});
// 실시간성 보장을 위해 StreamProvider로 변경하는 것을 추천합니다.
final lastUpdateStateProvider = FutureProvider.family<LastUpdated?, String>((ref, facilityId) async {
  final repo = ref.watch(realtimeDatabaseRepositoryProvider);
  return await repo.getLastUpdate(facilityId);
});
