import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/balena_device_repository.dart';

final balenaDeviceRepositoryProvider = Provider((ref) => BalenaDeviceRepository());

final balenaDevicesProvider = StreamProvider((ref) {
  final repository = ref.watch(balenaDeviceRepositoryProvider);
  return repository.getBalenaDevicesStream();
});
