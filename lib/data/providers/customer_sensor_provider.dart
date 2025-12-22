// 농가 이름을 인자로 받아 센서 리스트를 가져오는 Family Provider
import 'package:finger_farm/data/model/sensor.dart';
import 'package:finger_farm/data/providers/dashboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerSensorProvider = FutureProvider.family<List<Sensor>, ({String name, int index})>((ref, arg) async {
  final tbRepo = ref.watch(tbStatusRepositoryProvider);

  // Repository의 수정된 함수 호출 (이름과 인덱스 전달)
  final sensors = await tbRepo.getCustomerSensorsStatus(arg.name, arg.index);
  return sensors;
});
