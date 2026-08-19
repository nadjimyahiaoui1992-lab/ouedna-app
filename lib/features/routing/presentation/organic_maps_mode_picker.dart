import 'package:flutter/material.dart';

import '../domain/routing_models.dart';

Future<TravelMode?> showOrganicMapsModePicker(BuildContext context) {
  return showModalBottomSheet<TravelMode>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'اختر وسيلة التنقل',
              style: Theme.of(sheetContext)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'سيتم فتح المسار في Organic Maps باستخدام خرائطه وملاحة الصوت.',
            ),
            const SizedBox(height: 16),
            _ModeButton(
              icon: Icons.directions_car_rounded,
              label: 'سيارة',
              onTap: () => Navigator.pop(sheetContext, TravelMode.car),
            ),
            const SizedBox(height: 8),
            _ModeButton(
              icon: Icons.directions_walk_rounded,
              label: 'مشياً',
              onTap: () => Navigator.pop(sheetContext, TravelMode.foot),
            ),
            const SizedBox(height: 8),
            _ModeButton(
              icon: Icons.two_wheeler_rounded,
              label: 'دراجة نارية',
              helper: 'يستعمل مسار القيادة الأقرب المتاح',
              onTap: () => Navigator.pop(sheetContext, TravelMode.motorcycle),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.helper,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? helper;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              if (helper != null)
                Text(
                  helper!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        style: OutlinedButton.styleFrom(
          alignment: AlignmentDirectional.centerStart,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
}
