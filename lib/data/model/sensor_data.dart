class SensorData {
  final String name; // 센서 이름 (예: SoilTemperature, CO2)
  final dynamic value; // 센서 값 (예: 29.45, 517)
  final DateTime date; // 가져온 날짜 (타임스탬프 변환)

  SensorData({required this.name, required this.value, required this.date});
}
