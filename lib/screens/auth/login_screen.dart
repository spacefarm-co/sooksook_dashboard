import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Container(
          width: 400, // 웹 대시보드이므로 적절한 너비 고정
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dashboard_customize, size: 48, color: Colors.blueAccent),
              const SizedBox(height: 24),
              const Text("핑거팜 대시보드", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("관리자 계정으로 로그인하세요", style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 32),

              // [핵심] 기존 이메일 로그인 대신 구글 로그인 버튼 사용
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // AuthRepository의 구글 로그인 호출
                    await ref.read(authRepositoryProvider).signInWithGoogle();
                  },
                  label: const Text("Google 계정으로 계속하기"),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
