import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/providers/user_detail_provider.dart';
import '../../data/providers/detailed_sensor_provider.dart';
import '../../data/providers/actuators_provider.dart';
import '../../data/providers/actuator_groups_provider.dart';
import '../../data/providers/jira_provider.dart';
import '../../data/model/sensor.dart';
import '../../data/model/actuator.dart';
import '../../data/model/actuator_group.dart';
import '../../data/model/jira_issue.dart';

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

    // 데이터 구독
    final detailedAsync = ref.watch(detailedSensorProvider(user.customerName));
    final actuatorsAsync = ref.watch(actuatorsProvider(user.facilityId));
    final groupsAsync = ref.watch(actuatorGroupsProvider(user.facilityId));
    final jiraAsync = ref.watch(jiraIssuesProvider(user.customerName));

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
              // 1. 상단 기본 정보 섹션
              _buildDataSection("시설 및 기기 상세 정보", {
                "고객명": user.customerName,
                "지역명": user.regionName,
                "시설명": user.facilityName ?? "N/A",
                "기기명 (Device Name)": user.deviceName,
                "Balena UUID": user.uuid ?? "N/A",
                "쑥마스터 토큰": user.token ?? "N/A",
                "시설 ID": user.facilityId,
              }, uuid: user.uuid),

              // 2. 3분할 관제 영역
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [좌측: 1/4] 실시간 센서 (TB)
                    Expanded(
                      flex: 1,
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
                            error: (err, _) => _buildEmptyText("센서 로드 실패"),
                          ),
                        ],
                      ),
                    ),

                    Container(width: 1, color: Colors.grey[300]),

                    // [중앙: 2/4] 액추에이터 제어 섹션 (개별 vs 그룹 2분할)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSubHeader("등록 된 Actuator 리스트 (RTDB)", Colors.indigo[900]!),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // [중앙-좌] 개별 제어
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildInternalHeader("개별 제어"),
                                      actuatorsAsync.when(
                                        data:
                                            (actuators) =>
                                                Column(children: actuators.map((a) => _buildActuatorCard(a)).toList()),
                                        loading: () => const Center(child: CircularProgressIndicator()),
                                        error: (err, _) => _buildEmptyText("로드 실패"),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1, color: Colors.grey[200]),
                                // [중앙-우] 그룹 제어
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildInternalHeader("그룹 제어"),
                                      groupsAsync.when(
                                        data:
                                            (groups) =>
                                                Column(children: groups.map((g) => _buildGroupCard(g)).toList()),
                                        loading: () => const Center(child: CircularProgressIndicator()),
                                        error: (err, _) => _buildEmptyText("로드 실패"),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Container(width: 1, color: Colors.grey[300]),

                    // [우측: 1/4] Jira 티켓 이력
                    // Expanded(
                    //   flex: 1,
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       _buildSubHeader("기술 지원 및 개통 이력 (Jira)", const Color(0xFF0052CC)),
                    //       jiraAsync.when(
                    //         data:
                    //             (issues) =>
                    //                 issues.isEmpty
                    //                     ? _buildEmptyText("관련 티켓이 없습니다.")
                    //                     : Column(children: issues.map((i) => _buildJiraCard(i)).toList()),
                    //         loading:
                    //             () => const Center(
                    //               child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                    //             ),
                    //         error: (err, _) => _buildEmptyText("Jira 로드 실패"),
                    //       ),
                    //     ],
                    //   ),
                    // ),
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

  Widget _buildInternalHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[100],
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.indigo),
      ),
    );
  }

  Widget _buildTelemetryCard(Sensor sensor) {
    final telemetry = sensor.telemetry;
    return Container(
      padding: const EdgeInsets.all(12),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                ),
              ),
              _statusBadge(sensor.isActive ? 'active' : 'inactive', sensor.isActive ? "정상" : "체크"),
            ],
          ),
          if (telemetry != null) ...[
            const SizedBox(height: 8),
            ...telemetry.measurements
                .map(
                  (data) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(data.name, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        Text("${data.value}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(actuator.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(actuator.status, Actuator.statusKo(actuator)),
              if (actuator.openRate != null)
                Text("${actuator.openRate}%", style: const TextStyle(fontSize: 11, color: Colors.indigo)),
            ],
          ),
          if (actuator.openRate != null) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (actuator.openRate! / 100).clamp(0, 1),
              minHeight: 3,
              color: Colors.indigo,
              backgroundColor: Colors.grey[200],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupCard(ActuatorGroup group) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(group.status ?? 'stop', (group.status ?? 'stop').toUpperCase()),
              Text(
                "${group.openRate}%",
                style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (group.openRate! / 100).clamp(0, 1),
            minHeight: 4,
            color: Colors.indigo,
            backgroundColor: Colors.grey[200],
          ),
          if (group.remainingTime != null && group.remainingTime! > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "${group.remainingTime}초 남음",
                style: const TextStyle(fontSize: 9, color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJiraCard(JiraIssue issue) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _miniTag(issue.projectKey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  issue.summary,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(issue.status == 'Done' || issue.status == '완료' ? 'open' : 'stop', issue.status),
              Text(
                DateFormat('yy-MM-dd').format(issue.updated),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
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
      default:
        bgColor = Colors.red[50]!;
        textColor = Colors.red[700]!;
        borderColor = Colors.red[200]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _launchBalenaDashboard(String? uuid) async {
    if (uuid == null || uuid.isEmpty) return;
    final Uri url = Uri.parse('https://dashboard.balena-cloud.com/devices/$uuid/summary');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) debugPrint('Error launch $url');
  }

  Widget _miniTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: const TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyText(String text) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    );
  }
}
