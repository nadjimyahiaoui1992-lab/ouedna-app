import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_service.dart';
import '../../../core/storage/favorites_controller.dart';
import '../../../core/widgets/offline_catalogue_notice.dart';
import '../../places/domain/entities/place.dart';
import '../../places/domain/repositories/place_repository.dart';
import '../../places/presentation/place_details_page.dart';
import '../../routing/domain/routing_service.dart';
import '../domain/compass_planner.dart';
import '../domain/itinerary_models.dart';

class CompassPage extends StatefulWidget {
  const CompassPage({
    super.key,
    required this.repository,
    required this.favorites,
    required this.routingService,
    required this.onMap,
  });

  final PlaceRepository? repository;
  final FavoritesController favorites;
  final RoutingService? routingService;
  final VoidCallback onMap;

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> {
  final _planner = const CompassPlanner();
  final _locationService = LocationService();
  final _categories = <String>{};
  Future<_CompassData>? _future;
  StreamSubscription<void>? _subscription;
  JourneyLength _length = JourneyLength.halfDay;
  late DateTime _startAt;
  LatLng? _origin;
  CompassItinerary? _itinerary;
  bool _locating = false;
  bool _downloadingCatalogue = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startAt = DateTime(now.year, now.month, now.day, 9);
    _reload();
    _subscription =
        widget.repository?.watchPublishedPlaces().listen((_) => _reload());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _reload() => setState(() => _future = _load());

  Future<_CompassData> _load() async {
    final repository = widget.repository;
    if (repository == null)
      throw StateError('لا يتوفر اتصال بمصدر بيانات وادنا.');
    final response = await Future.wait([
      repository.getPublishedPlaces(),
      repository.getPublishedCategories(),
    ]);
    return _CompassData(
      places: response[0] as List<Place>,
      categories: response[1] as List<String>,
    );
  }

  Future<void> _downloadCatalogue() async {
    final repository = widget.repository;
    if (repository is! OfflineCatalogueRepository || _downloadingCatalogue) {
      return;
    }
    final offlineRepository = repository as OfflineCatalogueRepository;
    setState(() => _downloadingCatalogue = true);
    try {
      final count = await offlineRepository.downloadPublishedCatalogue();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تم حفظ $count معلماً منشوراً للاستخدام دون اتصال.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تعذر تنزيل الدليل حالياً. تحقق من اتصال الإنترنت.')),
      );
    } finally {
      if (mounted) setState(() => _downloadingCatalogue = false);
    }
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      final Position position = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _origin = LatLng(position.latitude, position.longitude);
        _locating = false;
      });
    } on LocationException catch (error) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _locating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديد موقعك الآن.')),
      );
    }
  }

  Future<void> _pickStartAt() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDate: _startAt.isBefore(today) ? today : _startAt,
      helpText: 'اختر يوم الرحلة',
      cancelText: 'إلغاء',
      confirmText: 'متابعة',
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
      helpText: 'اختر وقت الانطلاق',
      cancelText: 'إلغاء',
      confirmText: 'حفظ',
    );
    if (!mounted || time == null) return;
    setState(() {
      _startAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _buildItinerary(List<Place> places) => setState(() {
        _itinerary = _planner.compose(
          places: places,
          preferences: CompassPreferences(
            length: _length,
            categories: _categories,
            origin: _origin,
            startAt: _startAt,
          ),
        );
      });

  void _openPlace(Place place) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlaceDetailsPage(
            place: place,
            repository: widget.repository,
            favorites: widget.favorites,
            routingService: widget.routingService,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('بوصلة وادنا'),
          actions: [
            IconButton(
              tooltip: 'عرض الخريطة',
              onPressed: () {
                Navigator.pop(context);
                widget.onMap();
              },
              icon: const Icon(Icons.map_outlined),
            ),
          ],
        ),
        body: FutureBuilder<_CompassData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) return _CompassError(onRetry: _reload);
            final data = snapshot.data!;
            final isOffline =
                widget.repository is OfflineAwarePlaceRepository &&
                    (widget.repository as OfflineAwarePlaceRepository)
                        .isUsingCachedData;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _CompassHero(locationEnabled: _origin != null),
                const SizedBox(height: 12),
                _OfflineDownloadCard(
                  supported: widget.repository is OfflineCatalogueRepository,
                  downloading: _downloadingCatalogue,
                  onDownload: _downloadCatalogue,
                ),
                if (isOffline) ...[
                  const SizedBox(height: 12),
                  const OfflineCatalogueNotice(),
                ],
                const SizedBox(height: 22),
                Text(
                  'وقت الرحلة',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                SegmentedButton<JourneyLength>(
                  segments: const [
                    ButtonSegment(
                        value: JourneyLength.quick,
                        label: Text('سريع'),
                        icon: Icon(Icons.bolt_outlined)),
                    ButtonSegment(
                        value: JourneyLength.halfDay,
                        label: Text('نصف يوم'),
                        icon: Icon(Icons.wb_sunny_outlined)),
                    ButtonSegment(
                        value: JourneyLength.fullDay,
                        label: Text('يوم كامل'),
                        icon: Icon(Icons.auto_stories_outlined)),
                  ],
                  selected: {_length},
                  onSelectionChanged: (value) =>
                      setState(() => _length = value.first),
                ),
                const SizedBox(height: 22),
                _StartTimeCard(startAt: _startAt, onChange: _pickStartAt),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'اهتماماتك',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    TextButton(
                      onPressed: _categories.isEmpty
                          ? null
                          : () => setState(_categories.clear),
                      child: const Text('مسح'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'اختر ما يهمك أو اتركها فارغة لتجربة متنوعة من المعالم المنشورة.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: data.categories
                      .map(
                        (category) => FilterChip(
                          label: Text(category),
                          selected: _categories.contains(category),
                          onSelected: (selected) => setState(() {
                            selected
                                ? _categories.add(category)
                                : _categories.remove(category);
                          }),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: 20),
                _LocationCard(
                  enabled: _origin != null,
                  loading: _locating,
                  onEnable: _useMyLocation,
                  onClear: () => setState(() => _origin = null),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _buildItinerary(data.places),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('إنشاء خط رحلتي'),
                  ),
                ),
                if (_itinerary != null) ...[
                  const SizedBox(height: 30),
                  _ItineraryResult(
                    itinerary: _itinerary!,
                    onOpenPlace: _openPlace,
                    onMap: widget.onMap,
                  ),
                ],
              ],
            );
          },
        ),
      );
}

class _CompassData {
  const _CompassData({required this.places, required this.categories});

  final List<Place> places;
  final List<String> categories;
}

class _OfflineDownloadCard extends StatelessWidget {
  const _OfflineDownloadCard({
    required this.supported,
    required this.downloading,
    required this.onDownload,
  });

  final bool supported;
  final bool downloading;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ListTile(
          leading: const Icon(Icons.download_for_offline_outlined),
          title: const Text('حفظ دليل وادنا دون اتصال'),
          subtitle: const Text(
            'يحفظ معلومات المعالم المنشورة على جهازك. الخرائط الحية تحتاج اتصالاً بالإنترنت.',
          ),
          trailing: downloading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : OutlinedButton(
                  onPressed: supported ? onDownload : null,
                  child: const Text('تنزيل'),
                ),
        ),
      );
}

class _CompassHero extends StatelessWidget {
  const _CompassHero({required this.locationEnabled});

  final bool locationEnabled;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.explore_rounded,
                  color: Color(0xFFE5B65A), size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('خط رحلتك في وادي سوف',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(
                      locationEnabled
                          ? 'سنرتب المعالم المنشورة وفق اهتماماتك وموقعك الحالي، مع أوقات انتقال وزيارة واضحة.'
                          : 'اختر اهتماماتك ووقت الانطلاق لنرتب لك تجربة من المعالم المنشورة.',
                      style: const TextStyle(
                          color: Color(0xFFF4EBDD), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _StartTimeCard extends StatelessWidget {
  const _StartTimeCard({required this.startAt, required this.onChange});

  final DateTime startAt;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: ListTile(
          leading: const Icon(Icons.schedule_rounded),
          title: const Text('موعد بداية الرحلة'),
          subtitle: Text('${_formatDate(startAt)} · ${_formatTime(startAt)}'),
          trailing: OutlinedButton.icon(
            onPressed: onChange,
            icon: const Icon(Icons.edit_calendar_outlined, size: 18),
            label: const Text('تغيير'),
          ),
        ),
      );
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.enabled,
    required this.loading,
    required this.onEnable,
    required this.onClear,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onEnable;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(18),
        ),
        child: ListTile(
          leading: Icon(enabled
              ? Icons.my_location_rounded
              : Icons.location_searching_outlined),
          title: Text(
              enabled ? 'سيُراعى موقعك الحالي' : 'استخدم موقعي لتحسين الترتيب'),
          subtitle: Text(enabled
              ? 'يُستخدم على جهازك فقط لإنشاء هذه الرحلة.'
              : 'اختياري، ولا يُطلب إلا عند الضغط.'),
          trailing: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : enabled
                  ? IconButton(
                      tooltip: 'إزالة الموقع',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded))
                  : OutlinedButton(
                      onPressed: onEnable, child: const Text('تفعيل')),
        ),
      );
}

class _ItineraryResult extends StatelessWidget {
  const _ItineraryResult({
    required this.itinerary,
    required this.onOpenPlace,
    required this.onMap,
  });

  final CompassItinerary itinerary;
  final ValueChanged<Place> onOpenPlace;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    if (itinerary.isEmpty) {
      return _EmptyItinerary(onMap: onMap);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('رحلتك المقترحة',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
          '${itinerary.stops.length} محطات من المعالم المنشورة فقط · ${_formatDate(itinerary.startAt)}',
        ),
        const SizedBox(height: 4),
        const Text('الأوقات تقديرية حسب الإحداثيات المنشورة. تحقّق من ساعات العمل قبل الانطلاق.'),
        const SizedBox(height: 14),
        ...itinerary.stops.map(
          (stop) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _StopCard(stop: stop, onTap: () => onOpenPlace(stop.place)),
          ),
        ),
      ],
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({required this.stop, required this.onTap});

  final CompassStop stop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF193F38),
                  foregroundColor: const Color(0xFFE5B65A),
                  child: Text('${stop.order}',
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stop.place.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(stop.place.category),
                      const SizedBox(height: 6),
                      if (stop.arrivalAt != null && stop.departureAt != null)
                        Text(
                          '${_formatTime(stop.arrivalAt!)} – ${_formatTime(stop.departureAt!)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      if (stop.distanceMeters != null)
                        Text(_formatDistance(stop.distanceMeters!)),
                      if (stop.place.openingHours?.trim().isNotEmpty == true)
                        Text(
                          'ساعات العمل: ${stop.place.openingHours!.trim()}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_back_rounded),
              ],
            ),
          ),
        ),
      );
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _formatDate(DateTime? value) {
  if (value == null) return 'لم يُحدّد وقت';
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _formatDistance(double meters) {
  if (meters < 1000) return 'يبعد نحو ${meters.round()} م عن المحطة السابقة';
  return 'يبعد نحو ${(meters / 1000).toStringAsFixed(1)} كم عن المحطة السابقة';
}

class _EmptyItinerary extends StatelessWidget {
  const _EmptyItinerary({required this.onMap});
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.explore_off_outlined, size: 36),
              const SizedBox(height: 10),
              const Text('لا توجد معالم منشورة مطابقة للاختيارات الحالية.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              TextButton.icon(
                  onPressed: onMap,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('استكشف الخريطة')),
            ],
          ),
        ),
      );
}

class _CompassError extends StatelessWidget {
  const _CompassError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, size: 44),
              const SizedBox(height: 12),
              const Text('تعذر تحميل المعالم لإنشاء الرحلة.'),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ),
        ),
      );
}
