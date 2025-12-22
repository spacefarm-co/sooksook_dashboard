import 'package:finger_farm/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:finger_farm/config/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 이제 파일이 있으니 주석을 해제하고 정상적으로 초기화합니다.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await dotenv.load(fileName: ".env");
    print(".env 로드 성공");
  } catch (e) {
    print(".env 로드 실패: $e");
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Finger Farm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), useMaterial3: true),
      routerConfig: router,
    );
  }
}
