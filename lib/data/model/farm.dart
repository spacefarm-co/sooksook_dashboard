import 'package:finger_farm/data/model/facility.dart';

class Farm {
  final String id;
  final String name;
  final List<Facility> facilities;

  Farm({required this.id, required this.name, this.facilities = const []});

  factory Farm.fromFirestore(String id, Map<String, dynamic> json, {List<Facility> facilities = const []}) {
    return Farm(id: id, name: json['name'] ?? '', facilities: facilities);
  }
}
