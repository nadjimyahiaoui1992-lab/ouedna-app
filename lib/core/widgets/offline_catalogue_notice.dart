import 'package:flutter/material.dart';

class OfflineCatalogueNotice extends StatelessWidget {
  const OfflineCatalogueNotice({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber.shade100,
      child: Row(
        children: const [
          Icon(Icons.offline_bolt_outlined, size: 20, color: Colors.brown),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'أنت تستخدم النسخة المخزنة مؤقتاً لعدم توفر الاتصال بالإنترنت.',
              style: TextStyle(
                  color: Colors.brown,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
