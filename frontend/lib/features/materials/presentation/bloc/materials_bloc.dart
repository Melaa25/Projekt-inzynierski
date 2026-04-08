import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_materials.dart';
import 'materials_event.dart';
import 'materials_state.dart';

class MaterialsBloc extends Bloc<MaterialsEvent, MaterialsState> {
  final GetMaterials getMaterials;

  MaterialsBloc(this.getMaterials) : super(const MaterialsState()) {
    on<MaterialsRequested>(_onMaterialsRequested);
  }

  Future<void> _onMaterialsRequested(
    MaterialsRequested event,
    Emitter<MaterialsState> emit,
  ) async {
    emit(state.copyWith(status: MaterialsStatus.loading, errorMessage: null));

    final result = await getMaterials();

    result.fold(
      (error) => emit(
        state.copyWith(
          status: MaterialsStatus.failure,
          errorMessage: error,
        ),
      ),
      (materials) => emit(
        state.copyWith(
          status: MaterialsStatus.success,
          materials: materials,
          errorMessage: null,
        ),
      ),
    );
  }
}
