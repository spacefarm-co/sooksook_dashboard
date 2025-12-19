import 'package:finger_farm/data/repositories/connectivity_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

final connectivityRepositoryProvider = Provider<ConnectivityRepository>((ref) {
  return ConnectivityRepository();
});

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  final connectivityRepository = ref.watch(connectivityRepositoryProvider);
  return ConnectivityNotifier(connectivityRepository);
});

class ConnectivityState {
  final bool hasInternet;
  final bool cloudlink;
  final bool heartbeat;
  final bool wifiConnected;
  final int connectionCheckCountDown;

  ConnectivityState({
    this.hasInternet = false,
    this.cloudlink = false,
    this.heartbeat = false,
    this.wifiConnected = false,
    this.connectionCheckCountDown = 10,
  });

  ConnectivityState copyWith({
    bool? hasInternet,
    bool? cloudlink,
    bool? heartbeat,
    bool? wifiConnected,
    int? connectionCheckCountDown,
  }) {
    return ConnectivityState(
      hasInternet: hasInternet ?? this.hasInternet,
      cloudlink: cloudlink ?? this.cloudlink,
      heartbeat: heartbeat ?? this.heartbeat,
      wifiConnected: wifiConnected ?? this.wifiConnected,
      connectionCheckCountDown: connectionCheckCountDown ?? this.connectionCheckCountDown,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final ConnectivityRepository repository;
  Timer? _timer;

  ConnectivityNotifier(this.repository) : super(ConnectivityState());

  Future checkInternetConnectivity(String? currentCustomerId, String? facilityId) async {
    try {
      final hasInternet = await repository.checkRealConnection();
      String? sookMasterName = await repository.findSookMasterNameByFacilityId(currentCustomerId, facilityId);
      String? balenaUUID = await repository.findUuidByDeviceName(sookMasterName);
      if (balenaUUID == null) return;

      final result = await repository.getDeviceByUUID(balenaUUID);
      final wifiConnected = await repository.checkConnectionType();

      state = state.copyWith(
        hasInternet: hasInternet,
        wifiConnected: wifiConnected,
        cloudlink: result['is_online'],
        heartbeat: result['api_heartbeat_state'] == 'online' ? true : false,
      );

      Map<String, dynamic> stateMap = {
        'hasInternet': state.hasInternet,
        'wifiConnected': state.wifiConnected,
        'cloudlink': state.cloudlink,
        'heartbeat': state.heartbeat,
      };

      return stateMap;
    } catch (e) {
      print('Failed to check internet connectivity: $e');
    }
  }

  Future handleButtonTap() async {
    _timer?.cancel();
    state = state.copyWith(connectionCheckCountDown: 5);
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (state.connectionCheckCountDown > 0) {
        state = state.copyWith(connectionCheckCountDown: state.connectionCheckCountDown - 1);
      } else {
        timer.cancel();
      }
    });
  }
}
