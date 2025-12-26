import 'package:finger_farm/screens/home/home_screeen.dart';
import 'package:finger_farm/screens/user_detail/user_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/user_detail', builder: (context, state) => const UserDetailScreen()),
      // 여기에 로그인(auth), 설정(setting) 등의 경로를 추가해 나갈 예정입니다.
    ],
  );
});
