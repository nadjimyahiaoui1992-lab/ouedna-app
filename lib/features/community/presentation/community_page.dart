import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/entities/testimonial.dart';
import '../domain/repositories/community_repository.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, required this.repository});

  final CommunityRepository? repository;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  Future<List<Testimonial>>? _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final repository = widget.repository;
    setState(() {
      _future = repository == null
          ? Future<List<Testimonial>>.error(
              const AppException('تعذر الاتصال بمصدر تجارب الزوار.'),
            )
          : repository.getApprovedTestimonials();
    });
  }

  Future<void> _openShareExperience() async {
    final repository = widget.repository;
    if (repository == null) {
      _showMessage('تعذر الاتصال بالخدمة حالياً. حاول مرة أخرى لاحقاً.');
      return;
    }

    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareExperienceSheet(repository: repository),
    );
    if (sent == true && mounted) _refresh();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<Testimonial>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const _CommunityLoading();
            }
            if (snapshot.hasError) {
              return _CommunityError(onRetry: _refresh);
            }

            final testimonials = snapshot.data ?? const <Testimonial>[];
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              children: [
                _CommunityHero(onShare: _openShareExperience),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.forum_outlined,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'تجارب الزوار',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '${testimonials.length} تجربة',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (testimonials.isEmpty)
                  _EmptyExperiences(onShare: _openShareExperience)
                else
                  ...testimonials.map(
                    (testimonial) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _TestimonialCard(testimonial: testimonial),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CommunityHero extends StatelessWidget {
  const _CommunityHero({required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF193F38), Color(0xFF102D28)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x28102D28),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0x22FFFFFF),
              child: Icon(Icons.auto_stories_rounded, color: Color(0xFFE5B65A)),
            ),
            const SizedBox(height: 16),
            Text(
              'شارك تجربتك في وادي سوف',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 7),
            Text(
              'اكتب انطباعك وأرفق صور رحلتك. تُنشر تجربتك بعد مراجعتها من إدارة سوف 360.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFF5EBDD),
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('شارك تجربتك'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE5B65A),
                foregroundColor: const Color(0xFF102D28),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
}

class _EmptyExperiences extends StatelessWidget {
  const _EmptyExperiences({required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_camera_back_outlined,
                size: 38, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'كن أول من يشارك تجربته',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'أضف رأيك وصور رحلتك لمساعدة الزوار على اكتشاف وادي سوف.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            OutlinedButton(
                onPressed: onShare, child: const Text('ابدأ المشاركة')),
          ],
        ),
      );
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.testimonial});

  final Testimonial testimonial;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.outlineVariant.withOpacity(0.55),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (testimonial.photoUrls.isNotEmpty) ...[
                SizedBox(
                  height: 138,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: testimonial.photoUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: testimonial.photoUrls[index],
                        width: 170,
                        height: 138,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const SizedBox(
                          width: 170,
                          child: ColoredBox(color: Color(0x1A193F38)),
                        ),
                        errorWidget: (_, __, ___) => const SizedBox(
                          width: 170,
                          child: ColoredBox(
                            color: Color(0x1A193F38),
                            child: Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const Icon(Icons.format_quote_rounded,
                  color: Color(0xFFD9A441), size: 24),
              const SizedBox(height: 4),
              Text(
                testimonial.message,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.55),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0x19193F38),
                    child: Icon(Icons.person_outline,
                        size: 18, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      testimonial.name ?? 'زائر من سوف 360',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (testimonial.createdAt != null)
                    Text(
                      _dateLabel(testimonial.createdAt!),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ],
          ),
        ),
      );

  String _dateLabel(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _ShareExperienceSheet extends StatefulWidget {
  const _ShareExperienceSheet({required this.repository});

  final CommunityRepository repository;

  @override
  State<_ShareExperienceSheet> createState() => _ShareExperienceSheetState();
}

class _ShareExperienceSheetState extends State<_ShareExperienceSheet> {
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  final _picker = ImagePicker();
  final _photos = <XFile>[];
  var _isSending = false;
  var _isDone = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final selected = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (!mounted || selected.isEmpty) return;
      final available = 5 - _photos.length;
      setState(() {
        _photos.addAll(selected.take(available));
        _error = selected.length > available
            ? 'تم الاحتفاظ بخمس صور كحد أقصى.'
            : null;
      });
    } catch (_) {
      if (mounted)
        setState(() => _error = 'تعذر فتح معرض الصور. تحقق من أذونات الصور.');
    }
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'يرجى كتابة نص تجربتك أولاً.');
      return;
    }
    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      final photos = <ExperiencePhoto>[];
      for (final photo in _photos) {
        photos.add(ExperiencePhoto(
            fileName: photo.name, bytes: await photo.readAsBytes()));
      }
      await widget.repository.submitExperience(
        name: _nameController.text,
        message: message,
        photos: photos,
      );
      if (mounted) setState(() => _isDone = true);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'حدث خطأ أثناء إرسال التجربة. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        margin: EdgeInsets.only(top: 36, bottom: bottomPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
            child: _isDone ? _successView() : _formView(),
          ),
        ),
      ),
    );
  }

  Widget _successView() => Column(
        children: [
          const SizedBox(height: 26),
          const CircleAvatar(
            radius: 34,
            backgroundColor: Color(0x1AD9A441),
            child: Icon(Icons.mark_email_read_outlined,
                size: 34, color: Color(0xFF193F38)),
          ),
          const SizedBox(height: 16),
          Text('شكراً لمشاركتك!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'تجربتك قيد المراجعة وستظهر للزوار بعد اعتمادها من إدارة سوف 360.',
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تم'),
          ),
        ],
      );

  Widget _formView() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.add_a_photo_outlined, color: Color(0xFFD9A441)),
              const SizedBox(width: 8),
              Text('شارك تجربتك',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const Spacer(),
              IconButton(
                tooltip: 'إغلاق',
                onPressed:
                    _isSending ? null : () => Navigator.pop(context, false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            'تُنشر المشاركة بعد مراجعة إدارة سوف 360.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _nameController,
            enabled: !_isSending,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'اسمك الكريم (اختياري)',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            enabled: !_isSending,
            minLines: 4,
            maxLines: 7,
            maxLength: 1800,
            decoration: const InputDecoration(
              labelText: 'كيف كانت رحلتك في الوادي؟ *',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 86),
                child: Icon(Icons.chat_bubble_outline),
              ),
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _isSending || _photos.length >= 5 ? null : _pickPhotos,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(
              _photos.isEmpty
                  ? 'أرفق صوراً (اختياري، حتى 5 صور)'
                  : 'إضافة صور أخرى (${_photos.length}/5)',
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: const Color(0xFF193F38),
            ),
          ),
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 94,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _SelectedPhoto(
                  photo: _photos[index],
                  isSending: _isSending,
                  onRemove: () => setState(() => _photos.removeAt(index)),
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                )),
          ],
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _isSending ? null : _send,
            icon: _isSending
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_isSending ? 'جارٍ الإرسال...' : 'إرسال تجربتي'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF193F38),
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      );
}

class _SelectedPhoto extends StatelessWidget {
  const _SelectedPhoto({
    required this.photo,
    required this.isSending,
    required this.onRemove,
  });

  final XFile photo;
  final bool isSending;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: FutureBuilder<Uint8List>(
              future: photo.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    width: 94,
                    height: 94,
                    child: ColoredBox(color: Color(0x1A193F38)),
                  );
                }
                return Image.memory(
                  snapshot.data!,
                  width: 94,
                  height: 94,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          Positioned(
            top: -8,
            right: -8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isSending ? null : onRemove,
                customBorder: const CircleBorder(),
                child: const CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.redAccent,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
}

class _CommunityLoading extends StatelessWidget {
  const _CommunityLoading();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 48),
          Center(child: CircularProgressIndicator()),
        ],
      );
}

class _CommunityError extends StatelessWidget {
  const _CommunityError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 100),
          Icon(Icons.cloud_off_outlined,
              size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'تعذر تحميل تجارب الزوار حالياً',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'تحقق من اتصال الإنترنت ثم أعد المحاولة.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ),
        ],
      );
}
