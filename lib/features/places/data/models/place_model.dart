import '../../domain/entities/place.dart';

class PlaceModel extends Place {
  const PlaceModel({
    required super.id,
    required super.name,
    required super.category,
    required super.description,
    required super.address,
    super.subCategory,
    super.district,
    super.municipality,
    super.imageUrl,
    super.rating,
    super.openingHours,
    super.latitude,
    super.longitude,
    super.mapLink,
    super.phone,
    super.website,
    super.facebook,
    super.instagram,
    super.createdAt,
    super.updatedAt,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rating = json['rating'];
    final lat = json['lat'];
    final lng = json['lng'];

    return PlaceModel(
      id: rawId is int ? rawId : int.tryParse('$rawId') ?? 0,
      name: _requiredText(json['name'], 'معلم في وادي سوف'),
      category: _requiredText(json['main_category'], 'معالم سياحية'),
      subCategory: _optionalText(json['sub_category']),
      description:
          _requiredText(json['description'], 'لا يتوفر وصف لهذا المكان بعد.'),
      address: _requiredText(json['address'], 'وادي سوف، الجزائر'),
      district: _optionalText(json['district']),
      municipality: _optionalText(json['municipality']),
      imageUrl: _optionalText(json['image_url']),
      rating: rating is num ? rating.toDouble() : double.tryParse('$rating'),
      openingHours: _optionalText(json['opening_hours']),
      latitude: lat is num ? lat.toDouble() : double.tryParse('$lat'),
      longitude: lng is num ? lng.toDouble() : double.tryParse('$lng'),
      mapLink: _optionalText(json['map_link']),
      phone: _optionalText(json['phone']),
      website: _optionalText(json['website']),
      facebook: _optionalText(json['facebook']),
      instagram: _optionalText(json['instagram']),
      createdAt: _optionalDate(json['created_at']),
      updatedAt: _optionalDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'main_category': category,
        'sub_category': subCategory,
        'description': description,
        'address': address,
        'district': district,
        'municipality': municipality,
        'image_url': imageUrl,
        'rating': rating,
        'opening_hours': openingHours,
        'lat': latitude,
        'lng': longitude,
        'map_link': mapLink,
        'phone': phone,
        'website': website,
        'facebook': facebook,
        'instagram': instagram,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  static String _requiredText(Object? value, String fallback) =>
      _optionalText(value) ?? fallback;

  static String? _optionalText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime? _optionalDate(Object? value) {
    final text = _optionalText(value);
    return text == null ? null : DateTime.tryParse(text);
  }
}
