import 'package:flutter/material.dart';

class MaterialsEmptyState extends StatelessWidget {
  const MaterialsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E9E4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 42, color: Color(0xFF7A8A82)),
          const SizedBox(height: 10),
          Text(
            'Brak wyników dla podanych filtrów',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF32433A),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Zmień frazę wyszukiwania lub sposób sortowania.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5B6B63),
                ),
          ),
        ],
      ),
    );
  }
}