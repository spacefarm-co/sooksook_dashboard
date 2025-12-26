import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  // 인자를 받지 않도록 생성자 수정
  const UserDetailScreen({super.key});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // 현재는 아무런 상태를 구독하거나 인자를 받지 않습니다.

    return const Scaffold(
      // 화면에 아무 내용도 표시하지 않음
      body: SizedBox.shrink(),
    );
  }
}
