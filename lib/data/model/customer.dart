import 'package:finger_farm/data/model/farm.dart';
import 'package:finger_farm/data/model/sookmaster.dart';

class Customer {
  final String id;
  final String name;
  final List<SookMaster> sookMasters;
  final List<Farm> farms;

  Customer({required this.id, required this.name, required this.sookMasters, this.farms = const []});

  factory Customer.fromFirestore(String id, Map<String, dynamic> json, {List<Farm> farms = const []}) {
    var sookList = json['sook_master'] as List? ?? [];
    return Customer(
      id: id,
      name: json['name'] ?? '',
      sookMasters: sookList.map((e) => SookMaster.fromJson(e)).toList(),
      farms: farms,
    );
  }
}
