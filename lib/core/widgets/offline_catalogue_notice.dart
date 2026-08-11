import 'package:flutter/material.dart';

class OfflineCatalogueNotice extends StatelessWidget {
  const OfflineCatalogueNotice({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 19,
                color: Theme.of(context).colorScheme.onTertiaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'أنت تشاهد بيانات محفوظة على الجهاز؛ قد لا تكون محدثة الآن.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      );
}
