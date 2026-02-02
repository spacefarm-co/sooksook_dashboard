import 'dart:convert';
import 'package:finger_farm/data/model/balena_device_model.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
// 위에서 만든 모델 파일을 import 하세요
// import 'path_to_your_model/balena_device_model.dart';

class BalenaRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String balenaToken = 'KqUFkpcWALNyuqhRvvaVOOQg9tLlTUcY';

  /// [Balena] 모든 기기 정보를 로드하여 모델 리스트로 반환합니다.
  Future<List<BalenaDeviceModel>> fetchDevicesWithFacilityId() async {
    const String url =
        "https://api.balena-cloud.com/v7/device?\$expand=device_environment_variable(\$filter=name eq 'FacilityId')";

    try {
      debugPrint('🚀 [Balena] Balena 데이터 전수 로드 시작');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $balenaToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List devicesJson = data['d'] ?? [];

        // JSON 리스트를 BalenaDeviceModel 리스트로 변환
        final List<BalenaDeviceModel> deviceModels =
            devicesJson.map((json) => BalenaDeviceModel.fromApi(json)).toList();

        debugPrint('✅ [Connectivity] ${deviceModels.length}개의 기기 모델화 완료');
        return deviceModels;
      } else {
        debugPrint('❌ [Connectivity] API 에러: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [Connectivity] Balena API 예외 발생: $e');
    }
    return []; // 에러 시 빈 리스트 반환
  }
}
