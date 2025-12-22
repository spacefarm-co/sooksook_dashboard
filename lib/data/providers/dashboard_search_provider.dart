import 'package:finger_farm/data/model/combined_user_device.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_provider.dart';

// 필터 옵션 정의
class DashboardFilters {
  final String region;
  final bool? cloudOnline; // null: 전체, true: ON, false: OFF
  final bool? heartbeatOnline; // null: 전체, true: ON, false: OFF

  DashboardFilters({this.region = '전체', this.cloudOnline, this.heartbeatOnline});

  // null 값(전체) 선택 시 기존 값을 덮어쓰기 위해 전용 플래그 추가
  DashboardFilters copyWith({
    String? region,
    bool? cloudOnline,
    bool? heartbeatOnline,
    bool clearCloud = false, // true로 전달되면 cloudOnline을 null로 설정
    bool clearHeartbeat = false, // true로 전달되면 heartbeatOnline을 null로 설정
  }) {
    return DashboardFilters(
      region: region ?? this.region,
      cloudOnline: clearCloud ? null : (cloudOnline ?? this.cloudOnline),
      heartbeatOnline: clearHeartbeat ? null : (heartbeatOnline ?? this.heartbeatOnline),
    );
  }
}

// 1. 데이터로부터 동적 지역 리스트 생성 Provider
final availableRegionsProvider = Provider<List<String>>((ref) {
  final dashboardAsync = ref.watch(dashboardProvider);

  return dashboardAsync.maybeWhen(
    data: (list) {
      final regions = list.map((device) => device.regionName).where((r) => r.isNotEmpty).toSet().toList();

      return ['전체', ...regions..sort()];
    },
    orElse: () => ['전체'],
  );
});

// 2. 필터 상태 및 검색어 관리자
final filterProvider = StateProvider<DashboardFilters>((ref) => DashboardFilters());
final searchQueryProvider = StateProvider<String>((ref) => "");

// 3. 최종 필터링 로직 (UI에서는 이 Provider를 watch 하면 됩니다)
final filteredDashboardProvider = Provider<AsyncValue<List<CombinedUserDevice>>>((ref) {
  final dashboardAsync = ref.watch(dashboardProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final filters = ref.watch(filterProvider);

  return dashboardAsync.whenData((list) {
    return list.where((device) {
      // 1. 검색어 필터 (농가명 또는 디바이스명)
      final matchesQuery =
          device.customerName.toLowerCase().contains(query) || device.deviceName.toLowerCase().contains(query);

      // 2. 지역 필터
      final matchesRegion = filters.region == '전체' || device.regionName == filters.region;

      // 3. 클라우드 필터 (ON/OFF/전체)
      final matchesCloud = filters.cloudOnline == null || device.isCloudlinkOnline == filters.cloudOnline;

      // 4. 하트비트 필터 (ON/OFF/전체)
      final matchesHeartbeat = filters.heartbeatOnline == null || device.isHeartbeatOnline == filters.heartbeatOnline;

      return matchesQuery && matchesRegion && matchesCloud && matchesHeartbeat;
    }).toList();
  });
});
