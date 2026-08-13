import 'package:flutter/material.dart';
import '../data/repositories/supabase_community_repository.dart';
import '../domain/entities/testimonial.dart';
import '../domain/repositories/community_repository.dart';
import 'archive_page.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key, required this.repository});
  final CommunityRepository? repository;
  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late Future<List<Testimonial>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Testimonial>> _load() {
    return widget.repository?.getApprovedTestimonials() ??
        Future.value(const <Testimonial>[]);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final archiveEnabled = widget.repository is SupabaseCommunityRepository;
    return Scaffold(
      appBar: AppBar(title: const Text('المجتمع')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          children: [
            _CommunityHero(
              onArchive: archiveEnabled
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ArchivePage(
                            placeRepository: null,
                            communityRepository:
                                widget.repository! as SupabaseCommunityRepository,
                          ),
                        ),
                      );
                    }
                  : null,
              onRate: _showAppRating,
            ),
            const SizedBox(height: 20),
            Text(
              'تجارب الزوار',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<Testimonial>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'تعذر تحميل تجارب الزوار حالياً.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final testimonials = snapshot.data ?? const <Testimonial>[];
                if (testimonials.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'كن أول من يشارك تجربته بعد رحلتك في وادي سوف.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(
                  children: testimonials
                      .map((item) => _TestimonialCard(testimonial: item))
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAppRating() async {
    var rating = 5.0;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('قيّم تطبيق وادنا'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ما مدى رضاك عن تجربة استخدام التطبيق؟'),
              const SizedBox(height: 14),
              Slider(
                value: rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: rating.toStringAsFixed(0),
                onChanged: (value) => setDialogState(() => rating = value),
              ),
              Text('${rating.toStringAsFixed(0)} / 5',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('شكراً لتقييمك، رأيك يساعدنا على التطور.'),
                  ),
                );
              },
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityHero extends StatelessWidget {
  const _CommunityHero({required this.onArchive, required this.onRate});
  final VoidCallback? onArchive;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.groups_rounded, size: 34),
            const SizedBox(height: 8),
            const Text(
              'ذاكرة وادنا بأصوات زوارها',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'شارك تجربة، صورة قديمة، أو ملاحظة تساعد الآخرين على اكتشاف الولاية باحترام.',
              style: TextStyle(height: 1.4),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onArchive,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('الأرشيف التاريخي'),
                ),
                OutlinedButton.icon(
                  onPressed: onRate,
                  icon: const Icon(Icons.star_outline_rounded),
                  label: const Text('قيّم التطبيق'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  const _TestimonialCard({required this.testimonial});
  final Testimonial testimonial;

  @override
  Widget build(BuildContext context) {
    final displayName = testimonial.name?.trim().isNotEmpty == true
        ? testimonial.name!.trim()
        : 'زائر وادنا';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(displayName,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                const Icon(Icons.verified_rounded,
                    color: Colors.teal, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(testimonial.message,
                style: const TextStyle(height: 1.5)),
            if (testimonial.photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 82,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: testimonial.photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      testimonial.photos[index],
                      width: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFE4ECE8),
                        child: SizedBox(
                          width: 110,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
