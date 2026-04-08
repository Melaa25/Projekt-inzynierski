import 'package:equatable/equatable.dart';

class MaterialEntity extends Equatable {
  final int id;
  final String name;
  final String serialNumber;
  final double weight;
  final double length;
  final String? location;

  const MaterialEntity({
    required this.id,
    required this.name,
    required this.serialNumber,
    required this.weight,
    required this.length,
    this.location,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        serialNumber,
        weight,
        length,
        location,
      ];
}
