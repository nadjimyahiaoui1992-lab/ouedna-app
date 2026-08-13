import 'package:flutter/material.dart';
import '../../community/domain/repositories/community_repository.dart';

class PlaceFeedbackDialog extends StatefulWidget {
  const PlaceFeedbackDialog({super.key, required this.placeId, required this.communityRepository});
  final int placeId;
  final CommunityRepository communityRepository;

  @override
  State<PlaceFeedbackDialog> createState() => _PlaceFeedbackDialogState();
}

class _PlaceFeedbackDialogState extends State<PlaceFeedbackDialog> {
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  double _rating = 5.0;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_messageController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      // Reuse community repository to submit feedback
      // Note: Testimonials table can be used for general app feedback or linked to places
      await widget.communityRepository.submitExperience(
        name: _nameController.text.trim(),
        message: "[Place ID: ${widget.placeId}] ${_messageController.text.trim()}",
        photos: [],
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شكراً لمشاركتك! سيتم مراجعة رأيك ونشره.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('ما رأيك في هذا المكان؟', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => IconButton(
                onPressed: () => setState(() => _rating = index + 1.0),
                icon: Icon(index < _rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 32),
              )),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'الاسم (اختياري)', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(labelText: 'اكتب تجربتك هنا...', filled: true, fillColor: Colors.grey.shade100, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF193F38)),
            child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('إرسال التقييم'),
          ),
        ],
      ),
    );
  }
}
