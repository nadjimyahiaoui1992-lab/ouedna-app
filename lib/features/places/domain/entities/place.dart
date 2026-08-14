class Place {
  const Place({
    required this.id,
    required this.name,
    String? mainCategory,
    String? category,
    this.subCategory,
    String? description,
    this.address,
    this.district,
    this.municipality,
    this.phone,
    this.mapLink,
    this.openingHours,
    this.imageUrl,
    this.latitude,
    this.longitude,
    double? rating,
    String? status,
    DateTime? createdAt,
  })  : mainCategory = mainCategory ?? category ?? 'أخرى',
        description = description ?? '',
        rating = rating ?? 0,
        status = status ?? 'منشور',
        _createdAt = createdAt;

  final int id;
  final String name;
  final String mainCategory;
  final String? subCategory;
  final String description;
  final String? address;
  final String? district;
  final String? municipality;
  final String? phone;
  final String? mapLink;
  final String? openingHours;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final double rating;
  final String status;
  final DateTime? _createdAt;

  double? get latitudeValue => latitude;
  DateTime get createdAt =>
      _createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  String get category => mainCategory;
  bool get hasCoordinates => latitude != null && longitude != null;

  String get locationLabel {
    final parts = <String>[];
    if (address != null && address!.isNotEmpty) parts.add(address!);
    if (district != null && district!.isNotEmpty) parts.add(district!);
    if (municipality != null && municipality!.isNotEmpty)
      parts.add(municipality!);
    return parts.isEmpty ? 'ولاية الوادي' : parts.join('، ');
  }
}
