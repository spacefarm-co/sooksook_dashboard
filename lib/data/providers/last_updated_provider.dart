// 실시간성 보장을 위해 StreamProvider로 변경하는 것을 추천합니다.
import 'package:finger_farm/data/model/last_updated.dart';
import 'package:finger_farm/data/providers/realtime_database_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lastUpdateStateProvider = FutureProvider.family<LastUpdated?, String>((ref, facilityId) async {
  final repo = ref.watch(realtimeDatabaseRepositoryProvider);
  return await repo.getLastUpdate(facilityId);
});
