import 'package:flutter/material.dart';

import '../../models/material_batch_entity.dart';
import '../../models/batch_status.dart';

class BatchCard extends StatelessWidget {
  final MaterialBatchEntity batch;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const BatchCard({
    super.key,
    required this.batch,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: batch.isWaste ? const Color(0x1A8E1B1B) : const Color(0x1A00A54F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  batch.isWaste ? Icons.delete_outline_rounded : Icons.inventory_2_rounded,
                  color: batch.isWaste ? const Color(0xFF8E1B1B) : const Color(0xFF006B38),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batch.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kod partii: ${batch.batchCode}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ilość: ${batch.quantity} szt.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5A685F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Lokalizacja: ${batch.currentLocation?.name ?? '-'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5A685F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Status: ${BatchStatus.label(batch.status)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF5A685F),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelectionMode)
                Checkbox(value: isSelected, onChanged: (_) => onTap())
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF7D8A82),
                ),
            ],
          ),
        ),
      ),
    );
  }
}