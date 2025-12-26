import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/combined_user_device.dart';

// 현재 선택된 상세 유저 정보를 관리하는 프로바이더
final userDetailProvider = StateProvider<CombinedUserDevice?>((ref) => null);
