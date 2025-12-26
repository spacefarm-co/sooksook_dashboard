import 'dart:ui';
import 'package:finger_farm/data/providers/customer_sensor_provider.dart';
import 'package:finger_farm/data/providers/expanded_state_provider.dart';
import 'package:finger_farm/data/providers/realtime_database_provider.dart';
import 'package:finger_farm/data/providers/user_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/model/combined_user_device.dart';
import '../../data/model/last_updated.dart';
import '../../../../data/model/sensor.dart';

class DeviceExpandableRow extends ConsumerWidget {
  final CombinedUserDevice device;
  final int index;

  const DeviceExpandableRow({super.key, required this.device, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorAsync = ref.watch(customerSensorProvider((name: device.customerName, index: index)));
    final isExpanded = ref.watch(expandedStateProvider(device.customerName));

    return Column(
      children: [
        InkWell(
          onTap: () {
            final notifier = ref.read(expandedStateProvider(device.customerName).notifier);
            notifier.state = !isExpanded;
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              color: isExpanded ? Colors.blue.withOpacity(0.04) : Colors.transparent,
            ),
            child: Row(
              children: [
                SizedBox(width: 30, child: Text('$index', style: const TextStyle(fontSize: 10, color: Colors.grey))),
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(userDetailProvider.notifier).state = device;
                      context.go('/user_detail');
                    },
                    child: Text(device.customerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(device.regionName, style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                ),
                Expanded(flex: 2, child: Text(device.deviceName, style: const TextStyle(fontSize: 11))),
                Expanded(flex: 1, child: _buildSimpleStatus(device.isCloudlinkOnline)),
                Expanded(flex: 1, child: _buildSimpleStatus(device.isHeartbeatOnline)),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) _buildExpandedDetails(ref, sensorAsync),
      ],
    );
  }

  Widget _buildExpandedDetails(WidgetRef ref, AsyncValue<List<Sensor>> sensorAsync) {
    // RTDB 제어 이력 구독
    final lastUpdateAsync = ref.watch(lastUpdateStateProvider(device.facilityId));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      color: Colors.grey[50],
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [왼쪽] 센서 정보 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubSectionTitle("실시간 센서 정보", Icons.sensors),
                  sensorAsync.when(
                    data:
                        (sensors) =>
                            sensors.isEmpty
                                ? _buildEmptyText("연결된 센서가 없습니다.")
                                : Column(children: sensors.map((s) => _buildSensorItem(s)).toList()),
                    loading:
                        () => const Center(
                          child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                    error: (err, _) => _buildEmptyText("센서 로드 실패"),
                  ),
                ],
              ),
            ),

            const VerticalDivider(width: 20, thickness: 1, color: Colors.black12),

            // [오른쪽] 최근 제어 이력 영역 (제공해주신 Repository 기반 호출)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubSectionTitle("최근 제어 이력", Icons.history),
                  lastUpdateAsync.when(
                    data:
                        (history) =>
                            history == null ? _buildEmptyText("최근 제어 기록이 없습니다.") : _buildControlHistory(history),
                    loading:
                        () => const Center(
                          child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                    error: (err, _) => _buildEmptyText("기록 조회 실패"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 소규모 헬퍼 위젯들 ---

  Widget _buildSubSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: Colors.blueGrey),
          const SizedBox(width: 5),
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildSensorItem(Sensor sensor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _buildStatusBadge(sensor.isActive),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sensor.name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(sensor.type, style: TextStyle(fontSize: 8, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildControlHistory(LastUpdated history) {
    final formattedTime = history.updatedAt != null ? DateFormat('MM/dd HH:mm:ss').format(history.updatedAt!) : "-";
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: history.success ? Colors.green.withOpacity(0.06) : Colors.red.withOpacity(0.06),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                history.success ? "제어 성공" : "제어 실패",
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: history.success ? Colors.green : Colors.red,
                ),
              ),
              Text(formattedTime, style: const TextStyle(fontSize: 8, color: Colors.grey)),
            ],
          ),
        ),
        ...history.actuators
            .map(
              (a) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(a.name, style: const TextStyle(fontSize: 10, color: Colors.black87)),
                    Text(
                      "${a.openRate}% (${a.status})",
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: isActive ? Colors.green[200]! : Colors.red[200]!),
      ),
      child: Text(
        isActive ? 'ON' : 'OFF',
        style: TextStyle(
          color: isActive ? Colors.green[700] : Colors.red[700],
          fontSize: 8,
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

  Widget _buildEmptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey)),
    );
  }
}
