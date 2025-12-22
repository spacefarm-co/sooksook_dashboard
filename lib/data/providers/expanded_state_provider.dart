import 'package:flutter_riverpod/flutter_riverpod.dart';

final expandedStateProvider = StateProvider.family<bool, String>((ref, customerName) => false);
