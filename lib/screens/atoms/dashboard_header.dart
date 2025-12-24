import 'package:finger_farm/screens/atoms/filter_header_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      color: Colors.grey[100],
      child: Row(
        children: [
          const SizedBox(width: 30, child: Text('#', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          FilterHeaderCell(flex: 1, title: '농가명'),
          FilterHeaderCell(flex: 1, title: '지역', hasFilter: true),
          FilterHeaderCell(flex: 2, title: '디바이스'),
          FilterHeaderCell(flex: 1, title: '클라우드', hasFilter: true),
          FilterHeaderCell(flex: 1, title: '하트비트', hasFilter: true),
          const Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('센서연결', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
