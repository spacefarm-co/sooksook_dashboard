import 'package:flutter/material.dart';

class FilterTile extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isSelected; // 현재 선택된 상태인지 표시 (옵션)

  const FilterTile({super.key, required this.label, required this.onTap, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          // 선택된 항목은 파란색과 볼드체로 강조할 수 있습니다.
          color: isSelected ? Colors.blue : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      dense: true,
      // 선택된 상태일 때 체크 아이콘을 보여주면 더 친절합니다.
      trailing: isSelected ? const Icon(Icons.check, size: 16, color: Colors.blue) : null,
      onTap: () {
        onTap();
        Navigator.pop(context); // 선택 후 다이얼로그 닫기
      },
    );
  }
}
