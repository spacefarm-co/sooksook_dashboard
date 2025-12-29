import 'package:finger_farm/data/providers/auth_provider.dart';
import 'package:finger_farm/screens/auth/login_screen.dart';
import 'package:finger_farm/screens/home/home_screeen.dart';
import 'package:finger_farm/screens/user_detail/user_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login'; // 로그인 안 됨 -> 로그인 페이지로
      if (isLoggedIn && isLoggingIn) return '/'; // 로그인 됨 -> 대시보드로
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/user_detail', builder: (context, state) => const UserDetailScreen()),
      // ... 나머지 라우트
    ],
  );
});
