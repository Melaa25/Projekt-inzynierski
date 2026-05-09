import 'package:equatable/equatable.dart';

class LocationEntity extends Equatable {
  final int id;
  final String? code;
  final String name;
  final String? type;
  final int? parentId;
  final String? description;

  const LocationEntity({
    required this.id,
    this.code,
    required this.name,
    this.type,
    this.parentId,
    this.description,
  });

  @override
  List<Object?> get props => [id, code, name, type, parentId, description];
}
