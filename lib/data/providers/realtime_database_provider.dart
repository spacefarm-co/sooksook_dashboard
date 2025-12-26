import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/realtime_database_repository.dart';

// 1. Repository Provider
final realtimeDatabaseRepositoryProvider = Provider((ref) {
  return RealtimeDatabaseRepository();
});
