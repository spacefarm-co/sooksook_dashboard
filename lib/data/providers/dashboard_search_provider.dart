import 'package:finger_farm/data/model/combined_user_device.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_provider.dart';

// 필터 옵션 정의
class DashboardFilters {
  final String region; // '전체' 또는 특정 지역명
  final bool? cloudOnline; // null(전체), true(ON), false(OFF)
  final bool? heartbeatOnline; // null(전체), true(ON), false(OFF)

  DashboardFilters({this.region = '전체', this.cloudOnline, this.heartbeatOnline});

  DashboardFilters copyWith({String? region, bool? cloudOnline, bool? heartbeatOnline}) {
    return DashboardFilters(
      region: region ?? this.region,
      cloudOnline: cloudOnline, // null을 허용하기 위해 그대로 둠
      heartbeatOnline: heartbeatOnline,
    );
  }
}

// 필터 상태 관리자
final filterProvider = StateProvider<DashboardFilters>((ref) => DashboardFilters());
final searchQueryProvider = StateProvider<String>((ref) => "");

// 최종 필터링 로직
final filteredDashboardProvider = Provider<AsyncValue<List<CombinedUserDevice>>>((ref) {
  final dashboardAsync = ref.watch(dashboardProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final filters = ref.watch(filterProvider);

  return dashboardAsync.whenData((list) {
    return list.where((device) {
      // 1. 검색어 필터
      final matchesQuery =
          device.customerName.toLowerCase().contains(query) || device.deviceName.toLowerCase().contains(query);

      // 2. 지역 필터
      final matchesRegion = filters.region == '전체' || device.regionName == filters.region;

      // 3. 클라우드 필터
      final matchesCloud = filters.cloudOnline == null || device.isCloudlinkOnline == filters.cloudOnline;

      // 4. 하트비트 필터
      final matchesHeartbeat = filters.heartbeatOnline == null || device.isHeartbeatOnline == filters.heartbeatOnline;

      return matchesQuery && matchesRegion && matchesCloud && matchesHeartbeat;
    }).toList();
  });
});
