import 'package:finger_farm/data/providers/customer_sensor_provider.dart';
import 'package:finger_farm/data/providers/expanded_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/model/combined_user_device.dart';
import '../../../../data/model/sensor.dart';

class DeviceExpandableRow extends ConsumerWidget {
  final CombinedUserDevice device;
  final int index;

  const DeviceExpandableRow({super.key, required this.device, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 센서 데이터 구독: 위젯이 빌드(그려지기 시작)될 때 자동으로 API 호출 및 캐싱
    final sensorAsync = ref.watch(customerSensorProvider(device.customerName));

    // 2. 확장 상태 구독: 스크롤해도 상태가 유지됨
    final isExpanded = ref.watch(expandedStateProvider(device.customerName));

    return Column(
      children: [
        InkWell(
          onTap: () {
            // 클릭 시 확장 상태만 토글
            ref.read(expandedStateProvider(device.customerName).notifier).state = !isExpanded;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              color: isExpanded ? Colors.blue.withOpacity(0.04) : Colors.transparent,
            ),
            child: Row(
              children: [
                SizedBox(width: 30, child: Text('$index', style: const TextStyle(fontSize: 10))),
                Expanded(
                  flex: 1,
                  child: Text(
                    device.customerName,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(device.regionName, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                ),
                Expanded(
                  flex: 2,
                  child: Text(device.deviceName, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
                ),
                Expanded(flex: 1, child: _buildSimpleStatus(device.isCloudlinkOnline)),
                Expanded(flex: 1, child: _buildSimpleStatus(device.isHeartbeatOnline)),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 센서 요약 정보 표시 (캐싱된 데이터 활용)
                      sensorAsync.when(
                        data: (sensors) {
                          final activeCount = sensors.where((s) => s.isActive).length;
                          return Text(
                            sensors.isEmpty ? 'N/A' : '$activeCount/${sensors.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color:
                                  sensors.isEmpty
                                      ? Colors.grey
                                      : (activeCount == sensors.length ? Colors.blue : Colors.orange),
                            ),
                          );
                        },
                        loading:
                            () =>
                                const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (_, __) => const Icon(Icons.error_outline, size: 12, color: Colors.red),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 확장 영역 표시
        if (isExpanded)
          sensorAsync.when(
            data: (sensors) => _buildExpandedDetails(sensors),
            loading: () => _buildLoadingExpandedDetails(),
            error:
                (err, _) => Container(
                  padding: const EdgeInsets.all(10),
                  child: Text("에러 발생: $err", style: const TextStyle(fontSize: 10, color: Colors.red)),
                ),
          ),
      ],
    );
  }

  Widget _buildExpandedDetails(List<Sensor> sensors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 15, 10),
      color: Colors.grey[50],
      child:
          sensors.isEmpty
              ? const Text("연결된 센서 정보가 없습니다.", style: TextStyle(fontSize: 11, color: Colors.grey))
              : Column(children: sensors.map((sensor) => _buildSensorItem(sensor)).toList()),
    );
  }

  Widget _buildLoadingExpandedDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      color: Colors.grey[50],
      child: const Center(child: Text("센서 정보를 가져오는 중...", style: TextStyle(fontSize: 11, color: Colors.blue))),
    );
  }

  Widget _buildSensorItem(Sensor sensor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right, size: 12, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(child: Text(sensor.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
          Text('(${sensor.type})', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
          const SizedBox(width: 12),
          _buildStatusBadge(sensor.isActive),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isActive ? Colors.green[200]! : Colors.red[200]!),
      ),
      child: Text(
        isActive ? 'ON' : 'OFF',
        style: TextStyle(
          color: isActive ? Colors.green[700] : Colors.red[700],
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSimpleStatus(bool isOnline) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 6, color: isOnline ? Colors.green : Colors.red),
        const SizedBox(width: 4),
        Text(
          isOnline ? 'ON' : 'OFF',
          style: TextStyle(
            color: isOnline ? Colors.green[700] : Colors.red[700],
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
