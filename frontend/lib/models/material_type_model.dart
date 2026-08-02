import 'material_type_entity.dart';

class MaterialTypeModel extends MaterialTypeEntity {
  const MaterialTypeModel({
    required super.id,
    required super.name,
    required super.weight,
    required super.length,
    required super.thickness,
  });

  factory MaterialTypeModel.fromJson(Map<String, dynamic> json) {
    return MaterialTypeModel(
      id: json['id'] as int,
      name: json['name'] as String,
      weight: _toDouble(json['weight']),
      length: _toDouble(json['length']),
      thickness: _toDouble(json['thickness']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }
}