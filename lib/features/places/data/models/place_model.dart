import '../../domain/entities/place.dart';

class PlaceModel extends Place {
  const PlaceModel({
    required super.id,
    required super.name,
    required super.category,
    required super.description,
    required super.address,
    super.imageUrl,
    super.rating,
    super.openingHours,
    super.latitude,
    super.longitude,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
    final rating = json['rating'];
    final lat = json['lat'];
    final lng = json['lng'];

    return PlaceModel(
      id: id,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? (json['name'] as String).trim()
          : 'Lieu à découvrir',
      category: (json['main_category'] as String?)?.trim() ?? 'Découverte',
      description: (json['description'] as String?)?.trim() ??
          'Les informations culturelles de ce lieu seront bientôt enrichies.',
      address: (json['address'] as String?)?.trim() ?? 'El Oued, Algérie',
      imageUrl: _optionalText(json['image_url']),
      rating: rating is num ? rating.toDouble() : double.tryParse('$rating'),
      openingHours: _optionalText(json['opening_hours']),
      latitude: lat is num ? lat.toDouble() : double.tryParse('$lat'),
      longitude: lng is num ? lng.toDouble() : double.tryParse('$lng'),
    );
  }

  static String? _optionalText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
