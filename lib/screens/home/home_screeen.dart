import 'package:finger_farm/screens/atoms/dashboard_header.dart';
import 'package:finger_farm/screens/atoms/dashboard_search_bar.dart';
import 'package:finger_farm/screens/atoms/device_expandable_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/providers/dashboard_search_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredDashboardProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '농가 기기 통합 모니터링',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          const DashboardSearchBar(), // 분리된 검색바 클래스
          const DashboardHeader(), // 분리된 헤더 클래스

          Expanded(
            child: filteredAsync.when(
              data: (combinedList) {
                if (combinedList.isEmpty) {
                  return const Center(child: Text("검색 결과가 없습니다.", style: TextStyle(color: Colors.grey)));
                }

                final sortedList = [...combinedList];
                sortedList.sort((a, b) => a.customerName.compareTo(b.customerName));

                return ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: sortedList.length,
                  itemBuilder: (context, index) => DeviceExpandableRow(device: sortedList[index], index: index + 1),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('에러: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
