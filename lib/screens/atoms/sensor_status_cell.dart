import 'package:finger_farm/data/model/sensor.dart';
import 'package:finger_farm/data/providers/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SensorStatusCell extends ConsumerStatefulWidget {
  final String customerName;
  const SensorStatusCell({super.key, required this.customerName});

  @override
  ConsumerState<SensorStatusCell> createState() => _SensorStatusCellState();
}

class _SensorStatusCellState extends ConsumerState<SensorStatusCell> {
  List<Sensor>? _sensors;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSensorData();
  }

  Future<void> _loadSensorData() async {
    final tbRepo = ref.read(tbStatusRepositoryProvider);
    try {
      final data = await tbRepo.getCustomerSensorsStatus(widget.customerName);
      if (mounted) {
        setState(() {
          _sensors = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_sensors == null || _sensors!.isEmpty) return const Text('N/A');

    final activeCount = _sensors!.where((s) => s.isActive).length;
    return Text('$activeCount / ${_sensors!.length} ON');
  }
}
