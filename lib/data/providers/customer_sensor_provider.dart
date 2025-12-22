// 농가 이름을 인자로 받아 센서 리스트를 가져오는 Family Provider
import 'package:finger_farm/data/model/sensor.dart';
import 'package:finger_farm/data/providers/dashboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final customerSensorProvider = FutureProvider.family<List<Sensor>, String>((ref, customerName) async {
  final tbRepo = ref.watch(tbStatusRepositoryProvider);
  // API 호출
  final sensors = await tbRepo.getCustomerSensorsStatus(customerName);
  return sensors;
});
