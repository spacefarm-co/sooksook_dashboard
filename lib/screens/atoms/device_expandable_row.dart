import 'package:finger_farm/data/providers/customer_sensor_provider.dart';
import 'package:finger_farm/data/providers/expanded_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/model/combined_user_device.dart';
import '../../../../data/model/sensor.dart';

class DeviceExpandableRow extends ConsumerWidget {
  final CombinedUserDevice device;
  final int index;

  const DeviceExpandableRow({super.key, required this.device, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorAsync = ref.watch(customerSensorProvider(device.customerName));
    final isExpanded = ref.watch(expandedStateProvider(device.customerName));

    return Column(
      children: [
        InkWell(
          onTap: () => ref.read(expandedStateProvider(device.customerName).notifier).state = !isExpanded,
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
                  flex: 2,
                  child: Text(device.customerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
        if (isExpanded)
          sensorAsync.when(
            data: (sensors) => _buildExpandedDetails(sensors),
            loading: () => _buildLoadingExpandedDetails(),
            error:
                (err, _) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Text("데이터 로드 실패: $err", style: const TextStyle(fontSize: 11, color: Colors.red)),
                ),
          ),
      ],
    );
  }

  Widget _buildExpandedDetails(List<Sensor> sensors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      color: Colors.grey[50],
      child:
          sensors.isEmpty
              ? const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "연결된 센서 정보가 없습니다.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Row(
                      children: const [
                        // 비율 1:2:2 (상태:타입:센서명) + 값(1) + 시간(2)
                        Expanded(flex: 1, child: Text("상태", style: TextStyle(fontSize: 9, color: Colors.grey))),
                        Expanded(flex: 2, child: Text("타입", style: TextStyle(fontSize: 9, color: Colors.grey))),
                        Expanded(flex: 2, child: Text("센서명", style: TextStyle(fontSize: 9, color: Colors.grey))),
                        Expanded(
                          flex: 1,
                          child: Text(
                            "현재값",
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "최근 업데이트",
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  const SizedBox(height: 5),
                  ...sensors.map((sensor) => _buildSensorItem(sensor)).toList(),
                ],
              ),
    );
  }

  Widget _buildSensorItem(Sensor sensor) {
    final updateTime = DateTime.fromMillisecondsSinceEpoch(sensor.createdTime);
    final formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(updateTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          // 비율 1 (상태)
          Expanded(flex: 1, child: _buildStatusBadge(sensor.isActive)),

          // 비율 2 (타입)
          Expanded(
            flex: 2,
            child: Text(
              sensor.type,
              style: TextStyle(fontSize: 10, color: Colors.blueGrey[600], fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 비율 2 (센서명)
          Expanded(
            flex: 2,
            child: Text(
              sensor.name,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 비율 1 (현재값)
          Expanded(
            flex: 1,
            child: Text(
              "연동 중", // TODO: 실제 데이터 연동
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
          ),

          // 비율 2 (시간)
          Expanded(
            flex: 2,
            child: Text(
              formattedTime,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

  Widget _buildLoadingExpandedDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.grey[50],
      child: const Center(
        child: Column(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(height: 10),
            Text("센서 데이터를 불러오는 중...", style: TextStyle(fontSize: 11, color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}
