import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/providers/user_detail_provider.dart';
import '../../data/providers/detailed_sensor_provider.dart';
import '../../data/providers/actuators_provider.dart';
import '../../data/model/sensor.dart';
import '../../data/model/actuator.dart';

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
    final actuatorsAsync = ref.watch(actuatorsProvider(user.facilityId));

    return Scaffold(
      appBar: AppBar(
        title: Text('${user.customerName} 상세 관제'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 시설 및 기기 기본 정보 섹션 (UUID 클릭 기능 포함)
              _buildDataSection("시설 및 기기 상세 정보", {
                "고객명": user.customerName,
                "지역명": user.regionName,
                "시설명": user.facilityName ?? "N/A",
                "기기명 (Device Name)": user.deviceName,
                "Balena UUID": user.uuid ?? "N/A",
                "쑥마스터 토큰": user.token ?? "N/A",
                "시설 ID": user.facilityId,
              }, uuid: user.uuid),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [좌측 영역] 실시간 센서 텔레메트리 (ThingsBoard)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubHeader("실시간 센서 텔레메트리 (TB)", Colors.blueGrey[900]!),
                          detailedAsync.when(
                            data: (sensors) {
                              final telemetrySensors = sensors.where((s) => s.telemetry != null).toList();
                              return telemetrySensors.isEmpty
                                  ? _buildEmptyText("수신된 센서 데이터가 없습니다.")
                                  : Column(children: telemetrySensors.map((s) => _buildTelemetryCard(s)).toList());
                            },
                            loading:
                                () => const Center(
                                  child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                                ),
                            error: (err, _) => _buildEmptyText("센서 로드 실패: $err"),
                          ),
                        ],
                      ),
                    ),

                    Container(width: 1, color: Colors.grey[300]),

                    // [우측 영역] 등록 된 Actuator 리스트 (RTDB)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubHeader("등록 된 Actuator 리스트 (RTDB)", Colors.indigo[900]!),
                          actuatorsAsync.when(
                            data: (actuators) {
                              return actuators.isEmpty
                                  ? _buildEmptyText("등록된 액추에이터가 없습니다.")
                                  : Column(children: actuators.map((a) => _buildActuatorCard(a)).toList());
                            },
                            loading:
                                () => const Center(
                                  child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                                ),
                            error: (err, _) => _buildEmptyText("액추에이터 로드 실패: $err"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI 컴포넌트 메서드 ---

  Widget _buildSubHeader(String title, Color bgColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: bgColor,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
    );
  }

  Widget _buildTelemetryCard(Sensor sensor) {
    final telemetry = sensor.telemetry;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  sensor.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue),
                ),
              ),
              _statusBadge(sensor.isActive ? 'active' : 'inactive', sensor.isActive ? "정상" : "체크"),
            ],
          ),
          const SizedBox(height: 10),
          if (telemetry != null) ...[
            Wrap(
              spacing: 8,
              children: [
                if (telemetry.battery != null) _miniTag("🔋 배터리: ${telemetry.battery}%"),
                if (telemetry.rssi != null) _miniTag("📶 신호: ${telemetry.rssi}dBm"),
              ],
            ),
            const SizedBox(height: 12),
            ...telemetry.measurements
                .map(
                  (data) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(data.name, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("${data.value}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text(
                              DateFormat('HH:mm:ss').format(data.date),
                              style: const TextStyle(fontSize: 9, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildActuatorCard(Actuator actuator) {
    final isMotor = actuator.type == '모터';
    final currentStatusKo = Actuator.statusKo(actuator);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(isMotor ? Icons.settings_remote : Icons.power_settings_new, size: 18, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(actuator.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              _statusBadge(actuator.status, currentStatusKo),
            ],
          ),
          const SizedBox(height: 12),
          Text(Actuator.channelKo(actuator), style: const TextStyle(fontSize: 11, color: Colors.black87)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("장치 타입: ${actuator.type}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              if (isMotor && actuator.openRate != null)
                Text(
                  "개도율: ${actuator.openRate}%",
                  style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          if (isMotor && actuator.openRate != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (actuator.openRate! / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              color: Colors.indigo,
              minHeight: 4,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataSection(String title, Map<String, String> data, {String? uuid}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: Colors.grey[100],
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
        ...data.entries.map((e) {
          final isUuidField = e.key == "Balena UUID" && e.value != "N/A";
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(width: 150, child: Text(e.key, style: const TextStyle(color: Colors.black54, fontSize: 13))),
                Expanded(
                  child:
                      isUuidField
                          ? GestureDetector(
                            onTap: () => _launchBalenaDashboard(uuid),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Text(
                                e.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          )
                          : Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          );
        }).toList(),
        const Divider(height: 1),
      ],
    );
  }

  Widget _statusBadge(String status, String label) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (status) {
      case 'open':
      case 'active':
        bgColor = Colors.green[50]!;
        textColor = Colors.green[700]!;
        borderColor = Colors.green[200]!;
        break;
      case 'stop':
        bgColor = Colors.orange[50]!;
        textColor = Colors.orange[700]!;
        borderColor = Colors.orange[200]!;
        break;
      case 'close':
      case 'inactive':
      default:
        bgColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        borderColor = Colors.red[200]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _launchBalenaDashboard(String? uuid) async {
    if (uuid == null || uuid.isEmpty) return;
    final Uri url = Uri.parse('https://dashboard.balena-cloud.com/devices/$uuid/summary');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Widget _miniTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
    );
  }

  Widget _buildEmptyText(String text) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}
