import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/customer_repository.dart';

final customerRepositoryProvider = Provider((ref) => CustomerRepository());

final customersProvider = StreamProvider((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getCustomersStream();
});
