import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/realtime_database_repository.dart';
import '../model/last_updated.dart';

// 1. Repository Provider
final realtimeDatabaseRepositoryProvider = Provider((ref) {
  return RealtimeDatabaseRepository();
});

// 2. 선택된 시설의 최근 제어 이력을 관리하는 Provider (동적 호출용)
final lastUpdateProvider = StateProvider.family<LastUpdated?, String>((ref, facilityId) {
  return null; // 초기값은 null
});
