import 'package:equatable/equatable.dart';

abstract class MaterialsEvent extends Equatable {
  const MaterialsEvent();

  @override
  List<Object?> get props => [];
}

class MaterialsRequested extends MaterialsEvent {
  const MaterialsRequested();
}
