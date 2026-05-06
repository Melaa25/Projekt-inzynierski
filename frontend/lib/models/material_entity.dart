import 'package:equatable/equatable.dart';

import 'material_status.dart';

class MaterialEntity extends Equatable {
  final int id;
  final String name;
  final String serialNumber;
  final double weight;
  final double length;
  final String? location;
  final String status;

  const MaterialEntity({
    required this.id,
    required this.name,
    required this.serialNumber,
    required this.weight,
    required this.length,
    this.location,
    this.status = MaterialStatus.inStock,
  });

  @override
  List<Object?> get props => [id, name, serialNumber, weight, length, location, status];
}