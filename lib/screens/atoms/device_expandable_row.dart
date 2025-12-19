import 'package:flutter/material.dart';
import '../../data/model/combined_user_device.dart';
import '../../../../data/model/sensor.dart';

class DeviceExpandableRow extends StatefulWidget {
  final CombinedUserDevice device;
  final int index;
  const DeviceExpandableRow({super.key, required this.device, required this.index});

  @override
  State<DeviceExpandableRow> createState() => _DeviceExpandableRowState();
}

class _DeviceExpandableRowState extends State<DeviceExpandableRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              color: _isExpanded ? Colors.blue.withOpacity(0.02) : Colors.transparent,
            ),
            child: Row(
              children: [
                SizedBox(width: 30, child: Text('${widget.index}', style: TextStyle(fontSize: 10))),
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
                      Text(
                        device.sensors.isEmpty ? 'N/A' : '${device.activeSensorCount}/${device.totalSensorCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              device.sensors.isEmpty
                                  ? Colors.grey
                                  : (device.isAllSensorsNormal ? Colors.blue : Colors.orange),
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
        if (_isExpanded) _buildExpandedDetails(device),
      ],
    );
  }

  Widget _buildExpandedDetails(CombinedUserDevice device) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 15, 10),
      color: Colors.grey[50],
      child:
          device.sensors.isEmpty
              ? const Text("연결된 센서 정보가 없습니다.", style: TextStyle(fontSize: 11, color: Colors.grey))
              : Column(children: device.sensors.map((sensor) => _buildSensorItem(sensor)).toList()),
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
