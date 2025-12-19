import 'package:finger_farm/screens/atoms/filter_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/providers/dashboard_search_provider.dart';

class FilterHeaderCell extends ConsumerWidget {
  final int flex;
  final String title;
  final bool hasFilter;

  const FilterHeaderCell({super.key, required this.flex, required this.title, this.hasFilter = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(filterProvider);

    // 현재 필터 활성화 여부 판단
    bool isActive = false;
    if (title == '지역' && filters.region != '전체') isActive = true;
    if (title == '클라우드' && filters.cloudOnline != null) isActive = true;
    if (title == '하트비트' && filters.heartbeatOnline != null) isActive = true;

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: hasFilter ? () => _showFilterDialog(context, ref, title) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            if (hasFilter) ...[
              const SizedBox(width: 2),
              Icon(Icons.filter_alt, size: 12, color: isActive ? Colors.blue : Colors.grey),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref, String title) {
    final filters = ref.read(filterProvider);
    final filterNotifier = ref.read(filterProvider.notifier);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('$title 필터', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title == '지역') ...[
                  FilterTile(
                    label: '전체',
                    isSelected: filters.region == '전체',
                    onTap: () => filterNotifier.state = filters.copyWith(region: '전체'),
                  ),
                  FilterTile(
                    label: '대저',
                    isSelected: filters.region == '대저',
                    onTap: () => filterNotifier.state = filters.copyWith(region: '대저'),
                  ),
                  // ... 밀양, 거창도 같은 방식으로 추가
                ] else if (title == '클라우드') ...[
                  FilterTile(
                    label: '전체',
                    isSelected: filters.cloudOnline == null,
                    onTap:
                        () =>
                            filterNotifier.state = DashboardFilters(
                              region: filters.region,
                              heartbeatOnline: filters.heartbeatOnline,
                            ),
                  ),
                  FilterTile(
                    label: 'ON',
                    isSelected: filters.cloudOnline == true,
                    onTap: () => filterNotifier.state = filters.copyWith(cloudOnline: true),
                  ),
                  // ... OFF 추가
                ],
                // ... 하트비트 생략
              ],
            ),
          ),
    );
  }
}
