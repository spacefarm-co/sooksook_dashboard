import 'package:finger_farm/data/model/sensor_data.dart';

class SensorTelemetry {
  final List<SensorData> measurements;
  final int? battery;
  final int? rssi;

  SensorTelemetry({this.measurements = const [], this.battery, this.rssi});
}
