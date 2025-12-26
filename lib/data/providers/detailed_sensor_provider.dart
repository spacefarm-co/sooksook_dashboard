import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/sensor.dart';
import 'dashboard_provider.dart'; // tbStatusRepositoryProvider가 정의된 곳

/// [상세 화면용] 특정 농가의 모든 기기 상세 텔레메트리를 가져오는 Provider
final detailedSensorProvider = FutureProvider.family<List<Sensor>, String>((ref, customerName) async {
  final tbRepo = ref.watch(tbStatusRepositoryProvider);

  // 리스트용 가벼운 조회가 아닌, 루프를 돌며 상세 수치를 가져오는 함수 호출
  return await tbRepo.getDetailedSensorTelemetry(customerName);
});
