import 'package:equatable/equatable.dart';

import '../../domain/entities/material_entity.dart';

enum MaterialsStatus { initial, loading, success, failure }

class MaterialsState extends Equatable {
  final MaterialsStatus status;
  final List<MaterialEntity> materials;
  final String? errorMessage;

  const MaterialsState({
    this.status = MaterialsStatus.initial,
    this.materials = const [],
    this.errorMessage,
  });

  MaterialsState copyWith({
    MaterialsStatus? status,
    List<MaterialEntity>? materials,
    String? errorMessage,
  }) {
    return MaterialsState(
      status: status ?? this.status,
      materials: materials ?? this.materials,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, materials, errorMessage];
}
