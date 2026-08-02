import 'package:flutter/material.dart';

import '../../models/material_batch_entity.dart';

class MatchedBatchTile extends StatelessWidget {
  final MaterialBatchEntity batch;
  final VoidCallback onOpenDetails;

  const MatchedBatchTile({
    super.key,
    required this.batch,
    required this.onOpenDetails,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onOpenDetails,
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8F4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD6E7DC)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0x1A00A54F),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: Color(0xFF006B38),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('Kod: ${batch.batchCode}'),
                  Text('Ilość: ${batch.quantity} szt.'),
                  Text('Lokalizacja: ${batch.currentLocation?.name ?? '-'}'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}