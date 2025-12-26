// 농가 이름을 인자로 받아 센서 리스트를 가져오는 Family Provider
import 'package:finger_farm/data/model/sensor.dart';
import 'package:finger_farm/data/providers/dashboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerSensorProvider = FutureProvider.family<List<Sensor>, ({String customerId, int index})>((ref, arg) async {
  final tbRepo = ref.watch(tbStatusRepositoryProvider);
  // 수정된 ID 기반 함수 호출
  return await tbRepo.getCustomerSensorsStatus(arg.customerId, arg.index);
});
