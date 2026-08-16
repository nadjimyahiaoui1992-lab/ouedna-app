import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_service.dart';
import '../../../core/storage/favorites_controller.dart';
import '../../../core/widgets/offline_catalogue_notice.dart';
import '../../../core/widgets/ouedna_map_tiles.dart';
import '../../places/domain/entities/place.dart';
import '../../places/domain/repositories/place_repository.dart';
import '../../places/presentation/place_details_page.dart';
import '../../routing/domain/routing_models.dart';
import '../../routing/domain/routing_service.dart';
import '../../routing/presentation/live_navigation_page.dart';
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
  final _selectedPlaceIds = <int>{};
  final _visitDurationOverrides = <int, int>{};
  final _preferredOrderIds = <int>[];

  Future<_CompassData>? _future;
  StreamSubscription<void>? _subscription;
  JourneyLength _length = JourneyLength.halfDay;
  TravelMode _travelMode = TravelMode.car;
  DateTime _startAt = _nextNineOClock();
  LatLng? _origin;
  CompassItinerary? _itinerary;
  bool _locating = false;
  bool _routing = false;
  bool _manualSelection = false;
  bool _downloadingCatalogue = false;
  int _customMinutes = 240;

  @override
  void initState() {
    super.initState();
    _reload();
    _subscription =
        widget.repository?.watchPublishedPlaces().listen((_) => _reload());
  }

  @override
  void didUpdateWidget(covariant CompassPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _subscription?.cancel();
      _subscription =
          widget.repository?.watchPublishedPlaces().listen((_) => _reload());
      _reload();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _reload() => setState(() => _future = _load());

  Future<_CompassData> _load() async {
    final repository = widget.repository;
    if (repository == null) {
      throw StateError('لا يتوفر اتصال بمصدر بيانات وادنا.');
    }
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
          content: Text('تعذر تنزيل الدليل حالياً. تحقق من اتصال الإنترنت.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloadingCatalogue = false);
    }
  }

  Future<void> _useMyLocation() async {
    if (_locating) return;
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

  Future<void> _pickOriginOnMap() async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => _CompassOriginPicker(initialPoint: _origin),
      ),
    );
    if (result != null && mounted) setState(() => _origin = result);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'اختر تاريخ الرحلة',
    );
    if (date == null || !mounted) return;
    setState(() {
      _startAt = DateTime(
        date.year,
        date.month,
        date.day,
        _startAt.hour,
        _startAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt),
      helpText: 'اختر وقت البداية',
    );
    if (time == null || !mounted) return;
    setState(() {
      _startAt = DateTime(
        _startAt.year,
        _startAt.month,
        _startAt.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickCustomDuration() async {
    final controller = TextEditingController(text: '$_customMinutes');
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('المدة المخصصة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'عدد الدقائق',
            hintText: 'مثال: 180',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              int.tryParse(controller.text.trim()),
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value < 30 || !mounted) return;
    setState(() {
      _customMinutes = value;
      _length = JourneyLength.custom;
    });
  }

  CompassPreferences _preferences() => CompassPreferences(
        length: _length,
        categories: _categories,
        origin: _origin,
        startAt: _startAt,
        availableMinutes: _length == JourneyLength.custom
            ? _customMinutes
            : _length.defaultMinutes,
        selectedPlaceIds: _manualSelection ? _selectedPlaceIds : const <int>{},
        preferredOrderIds: _preferredOrderIds,
        visitDurationOverrides: _visitDurationOverrides,
        travelMode: _travelMode,
      );

  Future<void> _buildItinerary(List<Place> places) async {
    if (_manualSelection && _selectedPlaceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('اختر معلماً واحداً على الأقل أو فعّل الاقتراح الذكي.')),
      );
      return;
    }
    final preferences = _preferences();
    final initial = _planner.compose(places: places, preferences: preferences);
    setState(() => _itinerary = initial);
    final routingService = widget.routingService;
    if (routingService == null || _origin == null || initial.isEmpty) return;

    setState(() => _routing = true);
    final routedLegs = <int, CompassLeg>{};
    var current = _origin!;
    for (final stop in initial.stops) {
      try {
        final result = await routingService.calculateRoute(
          placeId: stop.place.id,
          origin: RoutePoint(
            latitude: current.latitude,
            longitude: current.longitude,
          ),
          destination: RoutePoint(
            latitude: stop.place.latitude!,
            longitude: stop.place.longitude!,
          ),
          mode: _travelMode,
        );
        final route = result.routes.isEmpty ? null : result.routes.first;
        if (route != null) {
          routedLegs[stop.place.id] = CompassLeg(
            from: current,
            to: LatLng(stop.place.latitude!, stop.place.longitude!),
            distanceMeters: route.distanceMeters,
            durationSeconds: route.durationSeconds,
            geometry: route.geometry,
            isEstimated: false,
          );
        }
      } catch (_) {
        // The planner keeps its transparent straight-line estimate when OSRM
        // is temporarily unavailable.
      }
      current = LatLng(stop.place.latitude!, stop.place.longitude!);
    }
    if (!mounted) return;
    final enriched = _planner.compose(
      places: places,
      preferences: preferences,
      routedLegs: routedLegs,
    );
    setState(() {
      _itinerary = enriched;
      _routing = false;
    });
  }

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

  void _openTripMap(CompassItinerary itinerary) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CompassTripMap(
          itinerary: itinerary,
          routingService: widget.routingService,
        ),
      ),
    );
  }

  void _startTrip(CompassItinerary itinerary) {
    final first = itinerary.stops.isEmpty ? null : itinerary.stops.first.place;
    final service = widget.routingService;
    if (first == null || service == null) {
      _openTripMap(itinerary);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LiveNavigationPage(place: first, routingService: service),
      ),
    );
  }

  void _reorderStops(List<Place> places, int oldIndex, int newIndex) {
    final itinerary = _itinerary;
    if (itinerary == null) return;
    final reordered = itinerary.stops.toList(growable: true);
    if (oldIndex < newIndex) newIndex -= 1;
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    _preferredOrderIds
      ..clear()
      ..addAll(reordered.map((stop) => stop.place.id));
    _buildItinerary(places);
  }

  Future<void> _editDuration(List<Place> places, Place place) async {
    final controller = TextEditingController(
      text: '${_visitDurationOverrides[place.id] ?? _plannerDefaultFor(place)}',
    );
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('المدة المقترحة للزيارة'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'بالدقائق'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              int.tryParse(controller.text.trim()),
            ),
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value < 10 || !mounted) return;
    setState(() => _visitDurationOverrides[place.id] = value);
    await _buildItinerary(places);
  }

  int _plannerDefaultFor(Place place) {
    final text = '${place.category} ${place.subCategory ?? ''}'.toLowerCase();
    if (text.contains('مطعم') || text.contains('restaurant')) return 60;
    if (text.contains('فندق') || text.contains('hotel')) return 90;
    if (text.contains('طبيعي') ||
        text.contains('طبيعة') ||
        text.contains('nature')) return 75;
    if (text.contains('تراث') || text.contains('متحف') || text.contains('ديني'))
      return 60;
    if (text.contains('سوق') || text.contains('متجر')) return 45;
    return 45;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('خطط رحلتي'),
          actions: [
            IconButton(
              tooltip: 'عرض الخريطة',
              onPressed: widget.onMap,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              children: [
                _CompassHero(
                  locationEnabled: _origin != null,
                  hasItinerary: _itinerary != null,
                ),
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
                _StartScheduleCard(
                  startAt: _startAt,
                  onPickDate: _pickDate,
                  onPickTime: _pickTime,
                ),
                const SizedBox(height: 18),
                Text(
                  'كم لديك من الوقت؟',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: JourneyLength.values
                        .map(
                          (length) => Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: ChoiceChip(
                              label: Text(length.label),
                              selected: _length == length,
                              onSelected: (_) {
                                if (length == JourneyLength.custom) {
                                  _pickCustomDuration();
                                } else {
                                  setState(() => _length = length);
                                }
                              },
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 18),
                _TransportCard(
                  mode: _travelMode,
                  onChanged: (mode) => setState(() => _travelMode = mode),
                ),
                const SizedBox(height: 22),
                Text(
                  'ماذا تحب أن تزور؟',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('الكل'),
                        selected: _categories.isEmpty,
                        onSelected: (_) => setState(_categories.clear),
                      ),
                      ...data.categories.map(
                        (category) => Padding(
                          padding: const EdgeInsetsDirectional.only(start: 8),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: _categories.contains(category),
                            onSelected: (selected) => setState(() {
                              selected
                                  ? _categories.add(category)
                                  : _categories.remove(category);
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SelectionModeCard(
                  manual: _manualSelection,
                  selectedCount: _selectedPlaceIds.length,
                  onSuggested: () => setState(() {
                    _manualSelection = false;
                    _selectedPlaceIds.clear();
                  }),
                  onManual: () => setState(() => _manualSelection = true),
                ),
                if (_manualSelection) ...[
                  const SizedBox(height: 10),
                  _ManualPlacesList(
                    places: data.places
                        .where((place) =>
                            place.hasCoordinates &&
                            (_categories.isEmpty ||
                                _categories.contains(place.category)))
                        .toList(growable: false),
                    selected: _selectedPlaceIds,
                    onChanged: (place, selected) => setState(() {
                      selected
                          ? _selectedPlaceIds.add(place.id)
                          : _selectedPlaceIds.remove(place.id);
                    }),
                  ),
                ],
                const SizedBox(height: 18),
                _OriginCard(
                  origin: _origin,
                  loading: _locating,
                  onCurrentLocation: _useMyLocation,
                  onMap: _pickOriginOnMap,
                  onClear: () => setState(() => _origin = null),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed:
                      _routing ? null : () => _buildItinerary(data.places),
                  icon: _routing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                      _routing ? 'نحسب المسار والوقت...' : 'اقترح لي رحلة'),
                ),
                if (_itinerary != null) ...[
                  const SizedBox(height: 30),
                  _ItineraryResult(
                    itinerary: _itinerary!,
                    onOpenPlace: _openPlace,
                    onMap: () => _openTripMap(_itinerary!),
                    onStart: () => _startTrip(_itinerary!),
                    onRemove: (place) {
                      setState(() {
                        _manualSelection = true;
                        _selectedPlaceIds.remove(place.id);
                      });
                      _buildItinerary(data.places);
                    },
                    onEditDuration: (place) =>
                        _editDuration(data.places, place),
                    onReorder: (oldIndex, newIndex) =>
                        _reorderStops(data.places, oldIndex, newIndex),
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

class _StartScheduleCard extends StatelessWidget {
  const _StartScheduleCard({
    required this.startAt,
    required this.onPickDate,
    required this.onPickTime,
  });
  final DateTime startAt;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('متى تريد بدء رحلتك؟',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPickDate,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(_dateLabel(startAt)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onPickTime,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(_timeLabel(startAt)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _TransportCard extends StatelessWidget {
  const _TransportCard({required this.mode, required this.onChanged});
  final TravelMode mode;
  final ValueChanged<TravelMode> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Icon(Icons.directions_car_outlined),
          const SizedBox(width: 8),
          const Text('وسيلة التنقل',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          DropdownButton<TravelMode>(
            value: mode,
            underline: const SizedBox.shrink(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
            items: TravelMode.values
                .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ))
                .toList(growable: false),
          ),
        ],
      );
}

class _SelectionModeCard extends StatelessWidget {
  const _SelectionModeCard({
    required this.manual,
    required this.selectedCount,
    required this.onSuggested,
    required this.onManual,
  });
  final bool manual;
  final int selectedCount;
  final VoidCallback onSuggested;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: ChoiceChip(
              label: const Text('اقتراح ذكي'),
              avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
              selected: !manual,
              onSelected: (_) => onSuggested(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              label: Text(
                  'اختيار يدوي${selectedCount == 0 ? '' : ' ($selectedCount)'}'),
              avatar: const Icon(Icons.checklist_rounded, size: 18),
              selected: manual,
              onSelected: (_) => onManual(),
            ),
          ),
        ],
      );
}

class _ManualPlacesList extends StatelessWidget {
  const _ManualPlacesList({
    required this.places,
    required this.selected,
    required this.onChanged,
  });
  final List<Place> places;
  final Set<int> selected;
  final void Function(Place place, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const Text('لا توجد معالم بإحداثيات ضمن هذه التصنيفات.');
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: places.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final place = places[index];
            return CheckboxListTile(
              value: selected.contains(place.id),
              onChanged: (value) => onChanged(place, value ?? false),
              title: Text(place.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(place.category),
              controlAffinity: ListTileControlAffinity.leading,
            );
          },
        ),
      ),
    );
  }
}

class _OriginCard extends StatelessWidget {
  const _OriginCard({
    required this.origin,
    required this.loading,
    required this.onCurrentLocation,
    required this.onMap,
    required this.onClear,
  });
  final LatLng? origin;
  final bool loading;
  final VoidCallback onCurrentLocation;
  final VoidCallback onMap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('نقطة البداية',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(
                origin == null
                    ? 'اختر موقعي الحالي أو حدد نقطة من الخريطة. بدون نقطة بداية سيستخدم المخطط ترتيبًا تقريبيًا.'
                    : '${origin!.latitude.toStringAsFixed(5)}، ${origin!.longitude.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: loading ? null : onCurrentLocation,
                    icon: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded),
                    label: const Text('موقعي الحالي'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onMap,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('من الخريطة'),
                  ),
                  if (origin != null)
                    IconButton(
                      tooltip: 'إزالة نقطة البداية',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _ItineraryResult extends StatelessWidget {
  const _ItineraryResult({
    required this.itinerary,
    required this.onOpenPlace,
    required this.onMap,
    required this.onStart,
    required this.onRemove,
    required this.onEditDuration,
    required this.onReorder,
  });

  final CompassItinerary itinerary;
  final ValueChanged<Place> onOpenPlace;
  final VoidCallback onMap;
  final VoidCallback onStart;
  final ValueChanged<Place> onRemove;
  final ValueChanged<Place> onEditDuration;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    if (itinerary.isEmpty) {
      return const _EmptyItinerary();
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'رحلتي اليوم',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text('${itinerary.stops.length} محطات'),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${_timeLabel(itinerary.startAt!)} → ${_timeLabel(itinerary.endAt!)} · إجمالي ${_durationLabel(itinerary.totalMinutes)}',
          style:
              theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (itinerary.hasEstimatedTravel)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('وقت التنقل تقديري عند عدم توفر مسار routing مباشر.'),
          ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('ابدأ الرحلة'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onMap,
          icon: const Icon(Icons.route_outlined),
          label: const Text('عرض الرحلة على الخريطة'),
        ),
        const SizedBox(height: 16),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itinerary.stops.length,
          onReorder: onReorder,
          itemBuilder: (context, index) {
            final stop = itinerary.stops[index];
            return Padding(
              key: ValueKey(stop.place.id),
              padding: const EdgeInsets.only(bottom: 10),
              child: _StopCard(
                stop: stop,
                onTap: () => onOpenPlace(stop.place),
                onRemove: () => onRemove(stop.place),
                onEditDuration: () => onEditDuration(stop.place),
                showDragHandle: true,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.stop,
    required this.onTap,
    required this.onRemove,
    required this.onEditDuration,
    required this.showDragHandle,
  });

  final CompassStop stop;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onEditDuration;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
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
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                            '${stop.place.category} · مدة مقترحة ${stop.visitMinutes} دقيقة'),
                      ],
                    ),
                  ),
                  if (showDragHandle)
                    const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 17),
                  const SizedBox(width: 5),
                  Text(
                    stop.hasSchedule
                        ? '${_timeLabel(stop.arrivalAt!)} – ${_timeLabel(stop.departureAt!)}'
                        : 'وقت غير محدد',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  if (stop.distanceMeters != null)
                    Text(_distanceLabel(stop.distanceMeters!)),
                ],
              ),
              if (stop.travelSeconds > 0) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'تنقل ${_durationLabel((stop.travelSeconds / 60).round())}${stop.travelIsEstimated ? ' · تقديري' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEditDuration,
                    icon: const Icon(Icons.edit_calendar_outlined, size: 17),
                    label: const Text('تعديل المدة'),
                  ),
                  IconButton(
                    tooltip: 'حذف من الرحلة',
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompassTripMap extends StatelessWidget {
  const _CompassTripMap(
      {required this.itinerary, required this.routingService});
  final CompassItinerary itinerary;
  final RoutingService? routingService;

  @override
  Widget build(BuildContext context) {
    final points = <LatLng>[];
    if (itinerary.startLocation != null) points.add(itinerary.startLocation!);
    for (final stop in itinerary.stops) {
      points.add(LatLng(stop.place.latitude!, stop.place.longitude!));
    }
    final center =
        points.isEmpty ? const LatLng(33.3683, 6.8674) : points.first;
    final geometry = itinerary.geometry.isEmpty ? points : itinerary.geometry;
    return Scaffold(
      appBar: AppBar(title: const Text('خريطة الرحلة')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 12),
            children: [
              OuednaMapTiles.standard(),
              if (geometry.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: geometry,
                      strokeWidth: 5,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (itinerary.startLocation != null)
                    Marker(
                      point: itinerary.startLocation!,
                      width: 48,
                      height: 48,
                      child: const Icon(Icons.my_location_rounded,
                          color: Colors.blue, size: 34),
                    ),
                  ...itinerary.stops.map(
                    (stop) => Marker(
                      point:
                          LatLng(stop.place.latitude!, stop.place.longitude!),
                      width: 52,
                      height: 52,
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF193F38),
                        foregroundColor: const Color(0xFFE5B65A),
                        child: Text('${stop.order}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          PositionedDirectional(
            start: 12,
            end: 12,
            bottom: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        itinerary.stops.isEmpty
                            ? 'لا توجد محطات.'
                            : 'المحطة التالية: ${itinerary.stops.first.place.name}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (routingService != null && itinerary.stops.isNotEmpty)
                      FilledButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LiveNavigationPage(
                              place: itinerary.stops.first.place,
                              routingService: routingService!,
                            ),
                          ),
                        ),
                        child: const Text('الاتجاهات'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassOriginPicker extends StatefulWidget {
  const _CompassOriginPicker({this.initialPoint});
  final LatLng? initialPoint;

  @override
  State<_CompassOriginPicker> createState() => _CompassOriginPickerState();
}

class _CompassOriginPickerState extends State<_CompassOriginPicker> {
  late LatLng _point = widget.initialPoint ?? const LatLng(33.3683, 6.8674);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('حدد نقطة البداية'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, _point),
              child: const Text('تأكيد',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        body: FlutterMap(
          options: MapOptions(
            initialCenter: _point,
            initialZoom: 13,
            onTap: (_, point) => setState(() => _point = point),
          ),
          children: [
            OuednaMapTiles.standard(),
            MarkerLayer(
              markers: [
                Marker(
                  point: _point,
                  width: 56,
                  height: 56,
                  child: const Icon(Icons.location_on_rounded,
                      color: Color(0xFFB63D32), size: 50),
                ),
              ],
            ),
            PositionedDirectional(
              start: 16,
              end: 16,
              top: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'اضغط على الخريطة ثم أكد نقطة البداية.\n${_point.latitude.toStringAsFixed(5)}، ${_point.longitude.toStringAsFixed(5)}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
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
  const _CompassHero(
      {required this.locationEnabled, required this.hasItinerary});
  final bool locationEnabled;
  final bool hasItinerary;

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
                      hasItinerary
                          ? 'تم إعداد برنامج زمني قابل للتنفيذ. يمكنك تعديله أو بدء الاتجاهات.'
                          : locationEnabled
                              ? 'سنرتب المعالم المنشورة وفق اهتماماتك وموقعك ووقتك المتاح.'
                              : 'حدد وقتك واهتماماتك، وسنقترح لك برنامجًا من المعالم المنشورة فقط.',
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

class _EmptyItinerary extends StatelessWidget {
  const _EmptyItinerary();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.explore_off_outlined, size: 36),
              SizedBox(height: 10),
              Text(
                'لا توجد معالم منشورة مطابقة للوقت أو الاختيارات الحالية. جرّب توسيع الوقت أو التصنيفات.',
                textAlign: TextAlign.center,
              ),
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

DateTime _nextNineOClock() {
  final now = DateTime.now();
  final candidate = DateTime(now.year, now.month, now.day, 9);
  return candidate.isBefore(now)
      ? candidate.add(const Duration(days: 1))
      : candidate;
}

String _dateLabel(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _timeLabel(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _durationLabel(int minutes) {
  if (minutes < 60) return '$minutes دقيقة';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '$hours ساعة' : '$hours س و$remainder د';
}

String _distanceLabel(double meters) => meters < 1000
    ? '${meters.round()} م'
    : '${(meters / 1000).toStringAsFixed(1)} كم';
