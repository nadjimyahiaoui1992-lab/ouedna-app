import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/entities/archive_memory.dart';
import '../domain/entities/testimonial.dart';
import '../domain/repositories/community_repository.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key, required this.communityRepository});

  final CommunityRepository? communityRepository;

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final _picker = ImagePicker();
  late Future<List<ArchiveMemory>> _future;
  var _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ArchiveMemory>> _load() {
    return widget.communityRepository?.getPublishedArchive() ??
        Future.value(const <ArchiveMemory>[]);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _submitPhotos() async {
    final repository = widget.communityRepository;
    if (repository == null) return;
    final photos =
        await _picker.pickMultiImage(imageQuality: 88, maxWidth: 2400);
    if (photos.isEmpty) return;
    if (photos.length > 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('يمكن إرسال خمس صور كحد أقصى في كل مساهمة.')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final payload = <ExperiencePhoto>[];
      for (final photo in photos) {
        payload.add(ExperiencePhoto(
            bytes: await photo.readAsBytes(), fileName: photo.name));
      }
      await repository.submitExperience(
        name: 'مساهمة في أرشيف وادنا',
        message: 'صور تاريخية أو تراثية مرسلة للأرشيف وتنتظر مراجعة الإدارة.',
        photos: payload,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('وصلت مساهمتك للمراجعة. ستظهر في الأرشيف بعد اعتمادها.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إرسال الصور: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('أرشيف وادي سوف التاريخي'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ArchiveMemory>>(
          future: _future,
          builder: (context, snapshot) {
            final memories = snapshot.data ?? const <ArchiveMemory>[];
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _ArchiveIntro(
                  isSubmitting: _isSubmitting,
                  onSubmit: _submitPhotos,
                  itemCount: memories.length,
                ),
                const SizedBox(height: 18),
                if (snapshot.connectionState != ConnectionState.done)
                  const Padding(
                    padding: EdgeInsets.only(top: 56),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  _ArchiveState(
                    icon: Icons.cloud_off_rounded,
                    title: 'تعذر تحميل الأرشيف حالياً',
                    message:
                        'تحقق من اتصال الإنترنت ثم اسحب للأسفل لإعادة المحاولة.',
                  )
                else if (memories.isEmpty)
                  const _ArchiveState(
                    icon: Icons.history_edu_outlined,
                    title: 'الأرشيف قيد التوسعة',
                    message:
                        'ستظهر هنا الصور التي تعتمدها إدارة وادنا من ذاكرة وادي سوف.',
                  )
                else
                  ...memories.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ArchiveCard(memory: item),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ArchiveIntro extends StatelessWidget {
  const _ArchiveIntro(
      {required this.isSubmitting,
      required this.onSubmit,
      required this.itemCount});
  final bool isSubmitting;
  final VoidCallback onSubmit;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.auto_stories_rounded, size: 29),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('ذاكرة الوادي',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900))),
              if (itemCount > 0) Chip(label: Text('$itemCount مادة')),
            ]),
            const SizedBox(height: 10),
            const Text(
                'صور ومواد تراثية تعتمدها الإدارة. اسحب للتحديث، واضغط على الصور للتنقل داخل كل مجموعة.'),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_photo_alternate_outlined),
              label:
                  Text(isSubmitting ? 'جارٍ الإرسال…' : 'إرسال صور للمراجعة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchiveCard extends StatefulWidget {
  const _ArchiveCard({required this.memory});
  final ArchiveMemory memory;

  @override
  State<_ArchiveCard> createState() => _ArchiveCardState();
}

class _ArchiveCardState extends State<_ArchiveCard> {
  var _index = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectImage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final memory = widget.memory;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(children: [
              PageView.builder(
                controller: _pageController,
                itemCount: memory.images.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (_, index) => Image.network(
                  memory.images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFFE4ECE8),
                    child: Center(
                        child: Icon(Icons.broken_image_outlined, size: 36)),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 10,
                end: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    child: Text('${_index + 1} / ${memory.images.length}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ]),
          ),
          if (memory.images.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: memory.images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => Semantics(
                    button: true,
                    selected: index == _index,
                    label: 'عرض الصورة ${index + 1} من ${memory.images.length}',
                    child: InkWell(
                      onTap: () => _selectImage(index),
                      borderRadius: BorderRadius.circular(9),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 54,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: index == _index
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Image.network(
                          memory.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFE4ECE8),
                            child: Icon(Icons.broken_image_outlined, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 6, children: [
                Chip(
                    avatar: const Icon(Icons.verified_outlined, size: 16),
                    label: Text(memory.sourceLabel)),
                Chip(label: Text(memory.period ?? 'تاريخ قيد التوثيق')),
              ]),
              const SizedBox(height: 10),
              Text(memory.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900)),
              if (memory.description?.isNotEmpty == true) ...[
                const SizedBox(height: 7),
                Text(memory.description!, style: const TextStyle(height: 1.55)),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class _ArchiveState extends StatelessWidget {
  const _ArchiveState(
      {required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 42),
        child: Center(
          child: Column(children: [
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            Text(message, textAlign: TextAlign.center),
          ]),
        ),
      );
}
