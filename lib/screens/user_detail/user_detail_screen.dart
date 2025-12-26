import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/providers/user_detail_provider.dart';
import '../../data/providers/detailed_sensor_provider.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  const UserDetailScreen({super.key});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userDetailProvider);

    if (user == null) {
      return Scaffold(appBar: AppBar(title: const Text("상세 정보")), body: const Center(child: Text("데이터가 없습니다.")));
    }

    final detailedAsync = ref.watch(detailedSensorProvider(user.customerName));

    return Scaffold(
      appBar: AppBar(
        title: Text('${user.customerName} 상세 관제'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 시설 및 기기 기본 정보
            _buildDataSection("시설 및 기기 상세 정보", {
              "고객명": user.customerName,
              "지역명": user.regionName,
              "시설명": user.facilityName,
              "기기명 (Device Name)": user.deviceName,
              "고객 ID": user.customerId,
              "농장 ID": user.farmId,
              "시설 ID (facilityId)": user.facilityId,
              "Balena UUID": user.uuid ?? "N/A",
              "쑥마스터 토큰": user.token ?? "N/A",
            }),

            // 2. 실시간 센서 텔레메트리 상세 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.blueGrey[900],
              child: const Text(
                "실시간 센서 텔레메트리 (수신 날짜 포함)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
            ),

            detailedAsync.when(
              data: (sensors) {
                if (sensors.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(30), child: Text("조회된 상세 데이터가 없습니다.")));
                }

                return Column(
                  children:
                      sensors.map((sensor) {
                        final telemetry = sensor.telemetry;

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 기기 헤더
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    sensor.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  _statusBadge(sensor.isActive),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // 하드웨어 상태
                              if (telemetry != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      if (telemetry.battery != null) _miniTag("🔋 배터리: ${telemetry.battery}%"),
                                      if (telemetry.rssi != null) _miniTag("📶 신호: ${telemetry.rssi}dBm"),
                                    ],
                                  ),
                                ),

                              // 상세 측정 데이터 및 수신 날짜
                              if (telemetry != null && telemetry.measurements.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children:
                                        telemetry.measurements.map((data) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      data.name,
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                                    ),
                                                    Text(
                                                      "${data.value}",
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.blueGrey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                // [수정] 수신 날짜와 시간을 전체 표기 (yyyy-MM-dd HH:mm:ss)
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    const Icon(Icons.access_time, size: 10, color: Colors.grey),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "수신: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(data.date)}",
                                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                    ),
                                                  ],
                                                ),
                                                const Divider(height: 12, thickness: 0.5),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                )
                              else
                                const Text("측정된 상세 수치가 없습니다.", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        );
                      }).toList(),
                );
              },
              loading:
                  () => const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator())),
              error: (err, _) => Center(child: Text("데이터 로드 실패: $err")),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- 기존 UI 헬퍼 메서드 유지 ---

  Widget _buildDataSection(String title, Map<String, String> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.grey[200],
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        ...data.entries
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: Text(e.key, style: const TextStyle(color: Colors.black54, fontSize: 13))),
                    Expanded(
                      flex: 6,
                      child: Text(
                        e.value,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        const Divider(height: 1),
      ],
    );
  }

  Widget _statusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isActive ? Colors.green[200]! : Colors.red[200]!),
      ),
      child: Text(
        isActive ? "정상" : "점검필요",
        style: TextStyle(
          color: isActive ? Colors.green[700] : Colors.red[700],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _miniTag(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
    );
  }
}
