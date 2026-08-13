import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/repositories/supabase_community_repository.dart';
import '../domain/entities/testimonial.dart';
import '../../places/domain/repositories/place_repository.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage(
      {super.key,
      required this.placeRepository,
      required this.communityRepository});
  final PlaceRepository? placeRepository;
  final SupabaseCommunityRepository? communityRepository;

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _submitPhoto() async {
    if (widget.communityRepository == null) return;
    final photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo == null) return;

    setState(() => _isSubmitting = true);
    try {
      final bytes = await photo.readAsBytes();
      await widget.communityRepository!.submitExperience(
        name: "مساهمة في الأرشيف",
        message: "صورة تاريخية مرسلة للأرشيف",
        photos: [ExperiencePhoto(bytes: bytes, fileName: photo.name)],
      );
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('شكراً لمساهمتك! سيتم مراجعة الصورة وإضافتها للأرشيف.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('أرشيف وادي سوف التاريخي'), centerTitle: true),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF193F38).withOpacity(0.05),
            child: Row(
              children: [
                const Expanded(
                    child: Text(
                        'ساهم في إثراء أرشيفنا التاريخي بصورك القديمة والنادرة لوادي سوف.',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13))),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitPhoto,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add_a_photo_rounded),
                  label: const Text('إرسال صورة'),
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF193F38)),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
                child: Text('سيتم عرض الصور التاريخية المعتمدة هنا قريباً...',
                    style: TextStyle(color: Colors.grey))),
          ),
        ],
      ),
    );
  }
}
