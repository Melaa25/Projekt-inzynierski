import 'package:equatable/equatable.dart';

class MaterialTypeEntity extends Equatable {
  final int id;
  final String name;
  final double weight;
  final double length;
  final double thickness;

  const MaterialTypeEntity({
    required this.id,
    required this.name,
    required this.weight,
    required this.length,
    required this.thickness,
  });

  @override
  List<Object?> get props => [id, name, weight, length, thickness];
}