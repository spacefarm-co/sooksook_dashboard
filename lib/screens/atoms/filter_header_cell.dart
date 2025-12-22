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
    final regions = ref.read(availableRegionsProvider);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('$title 필터', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              // 필터가 많아질 경우를 대비
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. 지역 필터 (동적 리스트)
                  if (title == '지역')
                    ...regions.map(
                      (r) => FilterTile(
                        label: r,
                        isSelected: filters.region == r,
                        onTap: () {
                          filterNotifier.state = filters.copyWith(region: r);
                        },
                      ),
                    ),

                  // 2. 클라우드 필터 (전체/ON/OFF)
                  if (title == '클라우드') ...[
                    FilterTile(
                      label: '전체',
                      isSelected: filters.cloudOnline == null,
                      onTap: () {
                        filterNotifier.state = filters.copyWith(clearCloud: true);
                      },
                    ),
                    FilterTile(
                      label: 'ON',
                      isSelected: filters.cloudOnline == true,
                      onTap: () {
                        filterNotifier.state = filters.copyWith(cloudOnline: true, clearCloud: false);
                      },
                    ),
                    FilterTile(
                      label: 'OFF',
                      isSelected: filters.cloudOnline == false,
                      onTap: () {
                        filterNotifier.state = filters.copyWith(cloudOnline: false, clearCloud: false);
                      },
                    ),
                  ],

                  // 3. 하트비트 필터 (전체/ON/OFF)
                  if (title == '하트비트') ...[
                    FilterTile(
                      label: '전체',
                      isSelected: filters.heartbeatOnline == null,
                      onTap: () {
                        filterNotifier.state = filters.copyWith(clearHeartbeat: true);
                      },
                    ),
                    FilterTile(
                      label: 'ON',
                      isSelected: filters.heartbeatOnline == true,
                      onTap: () {
                        filterNotifier.state = filters.copyWith(heartbeatOnline: true, clearHeartbeat: false);
                      },
                    ),
                    FilterTile(
                      label: 'OFF',
                      isSelected: filters.heartbeatOnline == false,
                      onTap: () {
                        filterNotifier.state = filters.copyWith(heartbeatOnline: false, clearHeartbeat: false);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }
}
