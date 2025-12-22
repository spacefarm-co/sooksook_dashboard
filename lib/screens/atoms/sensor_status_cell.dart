import 'package:finger_farm/data/providers/customer_sensor_provider.dart'; // 수정된 provider 경로
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SensorStatusCell extends ConsumerWidget {
  final String customerName;
  final int index;

  const SensorStatusCell({super.key, required this.customerName, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 위젯이 화면에 그려지는 순간, 본인의 index에 맞는 예약된 시간에 API를 호출합니다.
    final sensorAsync = ref.watch(customerSensorProvider((name: customerName, index: index)));

    return sensorAsync.when(
      data: (sensors) {
        if (sensors.isEmpty) return const Text('N/A', style: TextStyle(fontSize: 11));
        final activeCount = sensors.where((s) => s.isActive).length;
        return Text(
          '$activeCount / ${sensors.length} ON',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        );
      },
      loading: () => const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const Icon(Icons.error_outline, size: 14, color: Colors.red),
    );
  }
}
