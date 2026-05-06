import 'package:flutter/material.dart';

class SummaryPanel extends StatelessWidget {
  final int totalCount;
  final int filteredCount;
  final bool isLoading;

  const SummaryPanel({
    super.key,
    required this.totalCount,
    required this.filteredCount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E9E4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Color(0xFF006B38)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Widoczne: $filteredCount z $totalCount materiałów',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF2A3A32),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
        ],
      ),
    );
  }
}