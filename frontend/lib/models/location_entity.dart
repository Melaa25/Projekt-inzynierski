import 'package:equatable/equatable.dart';

class LocationEntity extends Equatable {
  final int id;
  final String? code;
  final String name;
  final String? type;
  final int? parentId;
  final String? description;
  final int childrenCount;

  const LocationEntity({
    required this.id,
    this.code,
    required this.name,
    this.type,
    this.parentId,
    this.description,
    this.childrenCount = 0,
  });

  @override
  List<Object?> get props => [id, code, name, type, parentId, description, childrenCount];
}