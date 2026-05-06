import 'package:flutter/material.dart';

class FilterPanel extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const FilterPanel({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E9E4)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: 'Szukaj po nazwie, numerze seryjnym lub lokalizacji',
          suffixIcon: searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Wyczyść',
                  onPressed: () {
                    controller.clear();
                    onSearchChanged('');
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
        ),
      ),
    );
  }
}