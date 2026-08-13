import '../../domain/entities/place.dart';

class PlaceModel extends Place {
  PlaceModel({
    required super.id,
    required super.name,
    super.mainCategory,
    super.subCategory,
    super.description,
    super.address,
    super.district,
    super.municipality,
    super.phone,
    super.mapLink,
    super.openingHours,
    super.imageUrl,
    super.latitude,
    super.longitude,
    super.rating,
    super.status,
    super.createdAt,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawLatitude = json['latitude'] ?? json['lat'];
    final rawLongitude = json['longitude'] ?? json['lng'];
    return PlaceModel(
      id: rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      mainCategory: json['main_category']?.toString() ?? json['category']?.toString(),
      subCategory: json['sub_category']?.toString(),
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      district: json['district']?.toString(),
      municipality: json['municipality']?.toString(),
      phone: json['phone']?.toString(),
      mapLink: json['map_link']?.toString(),
      openingHours: json['opening_hours']?.toString(),
      imageUrl: json['image_url']?.toString(),
      latitude: (rawLatitude as num?)?.toDouble(),
      longitude: (rawLongitude as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      status: json['status']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'main_category': mainCategory,
        'sub_category': subCategory,
        'description': description,
        'address': address,
        'district': district,
        'municipality': municipality,
        'phone': phone,
        'map_link': mapLink,
        'opening_hours': openingHours,
        'image_url': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'lat': latitude,
        'lng': longitude,
        'rating': rating,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}
