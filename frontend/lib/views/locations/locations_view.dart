import 'package:flutter/material.dart';

class LocationsView extends StatelessWidget {
  const LocationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final sampleLocations = [
      ('A', 'Strefa', 'Główna strefa materiałów stalowych'),
      ('A-01', 'Sektor', 'Sektor wejściowy dla nowych dostaw'),
      ('A-01-R03', 'Miejsce', 'Trzecie miejsce w rzędzie 01'),
      ('B', 'Strefa', 'Strefa materiałów do cięcia'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokalizacje magazynowe'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF00A54F), Color(0xFF006B38)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Struktura lokalizacji',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Na tym etapie lokalizacje są pokazane jako osobny moduł, a później podepniemy je do materiałów i operacji.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFE5FFF1),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...sampleLocations.map(
            (location) => Card(
              child: ListTile(
                leading: const Icon(Icons.place_rounded, color: Color(0xFF006B38)),
                title: Text('${location.$1} • ${location.$2}'),
                subtitle: Text(location.$3),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE1E9E4)),
            ),
            child: Text(
              'W kolejnym kroku podepniemy to pod bazę i materiały będą wskazywały current_location.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}