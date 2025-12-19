import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectivityRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  findSookMasterNameByFacilityId(String? currentCustomerId, String? facilityId) async {
    final customerDoc = await firestore.collection('customers').doc(currentCustomerId).get();

    if (!customerDoc.exists) {
      return null; // 해당 customer가 존재하지 않음
    }

    var customerData = customerDoc.data();
    if (customerData == null) return null;

    // Step 2: farms 컬렉션 가져오기
    final farmsSnapshot = await firestore.collection('customers').doc(currentCustomerId).collection('farms').get();

    for (var farmDoc in farmsSnapshot.docs) {
      // Step 3: 해당 farm의 facilities 컬렉션에서 특정 facility 문서 찾기
      final facilityDoc =
          await firestore
              .collection('customers')
              .doc(currentCustomerId)
              .collection('farms')
              .doc(farmDoc.id)
              .collection('facilities')
              .doc(facilityId)
              .get();

      if (facilityDoc.exists) {
        var facilityData = facilityDoc.data();
        String? facilityToken = facilityData?['sook_master_token'];

        if (facilityToken != null) {
          var sookMaster = customerData['sook_master'];

          if (sookMaster != null) {
            for (var entry in sookMaster) {
              if (entry['token'] == facilityToken) {
                return entry['name']; // 일치하는 name 반환
              }
            }
          }
        }
      }
    }

    return null; // 일치하는 name이 없을 경우
  }

  Future<String?> findUuidByDeviceName(String? sookMasterName) async {
    final devicesSnapshot = await firestore.collection('balenaDevices').get();

    for (var deviceDoc in devicesSnapshot.docs) {
      var deviceData = deviceDoc.data();

      if (deviceData['device_name'] == sookMasterName) {
        return deviceData['uuid'];
      }
    }

    return null; // 일치하는 device_name이 없을 경우
  }

  Future getDeviceByUUID(String? uuid) async {
    final String url = 'https://api.balena-cloud.com/v7/device(uuid=\'$uuid\')';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer KqUFkpcWALNyuqhRvvaVOOQg9tLlTUcY'},
      );

      if (response.statusCode == 200) {
        // Successful response
        var data = jsonDecode(response.body);
        var device = data['d'][0]; // Assuming the first device in the list
        var result = {'is_online': device['is_online'], 'api_heartbeat_state': device['api_heartbeat_state']};
        return result;
      } else {
        // Handle error response
        print('Error failed to get device: ${response.body}');
        return {};
      }
    } catch (e) {
      // Handle any errors
      print('Error occurred: $e');
    }
  }

  Future<bool> checkRealConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      try {
        final result = await InternetAddress.lookup('cloudflare.com');
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        return false;
      }
    }
  }

  Future<bool?> checkConnectionType() async {
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      return false;
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      return true;
    } else {
      return null;
    }
  }
}
