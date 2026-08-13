import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/entities/testimonial.dart';
import '../domain/entities/visitor_inquiry.dart';
import '../domain/repositories/community_repository.dart';

class ExperienceSubmissionPage extends StatefulWidget {
  const ExperienceSubmissionPage({super.key, required this.repository});

  final CommunityRepository repository;

  @override
  State<ExperienceSubmissionPage> createState() =>
      _ExperienceSubmissionPageState();
}

class _ExperienceSubmissionPageState extends State<ExperienceSubmissionPage> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  final _picker = ImagePicker();
  final List<_PickedPhoto> _photos = [];
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    final remaining = 5 - _photos.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يمكن إرفاق خمس صور كحد أقصى.')),
      );
      return;
    }

    final picked = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked.isEmpty) return;

    final selected = <_PickedPhoto>[];
    for (final photo in picked.take(remaining)) {
      final bytes = await photo.readAsBytes();
      selected.add(_PickedPhoto(bytes: bytes, fileName: photo.name));
    }
    if (!mounted) return;
    setState(() => _photos.addAll(selected));
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب تجربتك قبل الإرسال.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.repository.submitExperience(
        name: _nameController.text.trim(),
        message: message,
        photos: _photos
            .map((photo) =>
                ExperiencePhoto(bytes: photo.bytes, fileName: photo.fileName))
            .toList(growable: false),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('شكراً لمشاركتك. ستظهر تجربتك بعد مراجعتها.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال التجربة: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('شارك تجربتك')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const _FormIntro(
              icon: Icons.auto_stories_rounded,
              title: 'رحلتك قد تساعد زائراً آخر',
              description:
                  'اكتب ما أعجبك، وأضف صوراً من رحلتك إن رغبت. تُراجع التجربة قبل نشرها للجميع.',
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'الاسم (اختياري)',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              minLines: 6,
              maxLines: 9,
              maxLength: 1800,
              decoration: const InputDecoration(
                labelText: 'كيف كانت تجربتك؟',
                hintText: 'مثلاً: أفضل وقت للزيارة وما الذي تنصح به الزوار…',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 120),
                  child: Icon(Icons.edit_note_rounded),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _submitting ? null : _pickPhotos,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text('إرفاق صور (${_photos.length}/5)'),
                  ),
                ),
              ],
            ),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            photo.bytes,
                            width: 104,
                            height: 104,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            child: IconButton(
                              tooltip: 'حذف الصورة',
                              constraints: const BoxConstraints.tightFor(
                                width: 34,
                                height: 34,
                              ),
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              onPressed: _submitting
                                  ? null
                                  : () =>
                                      setState(() => _photos.removeAt(index)),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                  _submitting ? 'جارٍ الإرسال…' : 'إرسال التجربة للمراجعة'),
            ),
          ],
        ),
      ),
    );
  }
}

class VisitorInquiryPage extends StatefulWidget {
  const VisitorInquiryPage({super.key, required this.repository});

  final CommunityRepository repository;

  @override
  State<VisitorInquiryPage> createState() => _VisitorInquiryPageState();
}

class _VisitorInquiryPageState extends State<VisitorInquiryPage> {
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  VisitorInquiryKind _kind = VisitorInquiryKind.suggestion;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب رسالتك قبل الإرسال.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.repository.submitInquiry(
        name: _nameController.text.trim(),
        contactInfo: _contactController.text.trim(),
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        kind: _kind,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _kind == VisitorInquiryKind.question
                ? 'تم إرسال سؤالك إلى فريق وادنا.'
                : 'شكراً لاقتراحك. وصل إلى فريق وادنا للمراجعة.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال رسالتك: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isQuestion = _kind == VisitorInquiryKind.question;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اقتراح أو سؤال')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _FormIntro(
              icon: isQuestion
                  ? Icons.help_outline_rounded
                  : Icons.lightbulb_outline_rounded,
              title: isQuestion ? 'اسأل فريق وادنا' : 'ساعدنا على تحسين وادنا',
              description: isQuestion
                  ? 'أرسل سؤالك بوضوح، ويمكنك ترك وسيلة تواصل اختيارية للرد.'
                  : 'أخبرنا بالميزة أو المعلومة التي ستجعل تجربتك أفضل.',
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<VisitorInquiryKind>(
              value: _kind,
              decoration: const InputDecoration(
                labelText: 'نوع الرسالة',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: VisitorInquiryKind.suggestion,
                  child: Text('اقتراح أو ملاحظة'),
                ),
                DropdownMenuItem(
                  value: VisitorInquiryKind.question,
                  child: Text('سؤال'),
                ),
              ],
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value != null) setState(() => _kind = value);
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              maxLength: 100,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'الاسم (اختياري)',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactController,
              maxLength: 180,
              textInputAction: TextInputAction.next,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'هاتف أو بريد إلكتروني للرد (اختياري)',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              maxLength: 160,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'عنوان مختصر (اختياري)',
                prefixIcon: Icon(Icons.subject_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              minLines: 6,
              maxLines: 9,
              maxLength: 3000,
              decoration: const InputDecoration(
                labelText: 'الرسالة',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 120),
                  child: Icon(Icons.forum_outlined),
                ),
              ),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_submitting ? 'جارٍ الإرسال…' : 'إرسال الرسالة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormIntro extends StatelessWidget {
  const _FormIntro({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(description, style: const TextStyle(height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickedPhoto {
  const _PickedPhoto({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;
}
