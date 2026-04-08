import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/materials_bloc.dart';
import '../bloc/materials_event.dart';
import '../bloc/materials_state.dart';

class MaterialsPage extends StatelessWidget {
  const MaterialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materialy'),
      ),
      body: BlocBuilder<MaterialsBloc, MaterialsState>(
        builder: (context, state) {
          if (state.status == MaterialsStatus.initial) {
            context.read<MaterialsBloc>().add(const MaterialsRequested());
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == MaterialsStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == MaterialsStatus.failure) {
            return Center(
              child: Text(state.errorMessage ?? 'Nie udalo sie pobrac materialow'),
            );
          }

          if (state.materials.isEmpty) {
            return const Center(child: Text('Brak materialow'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.materials.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final material = state.materials[index];

              return Card(
                child: ListTile(
                  title: Text(material.name),
                  subtitle: Text(
                    'Nr seryjny: ${material.serialNumber} | Waga: ${material.weight} | Dlugosc: ${material.length}',
                  ),
                  trailing: Text(material.location ?? '-'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
