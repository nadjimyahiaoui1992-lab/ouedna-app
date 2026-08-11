class Place {
  final int id;
  final String name;
  final String? mainCategory;
  final String? subCategory;
  final String? description;
  final String? address;
  final String? district;
  final String? municipality;
  final double? lat;
  final double? lng;
  final String? mapLink;
  final String? phone;
  final String? website;
  final String? facebook;
  final String? instagram;
  final String? openingHours;
  final String? imageUrl;
  final int? rating;
  final String? status;

  Place({
    required this.id,
    required this.name,
    this.mainCategory,
    this.subCategory,
    this.description,
    this.address,
    this.district,
    this.municipality,
    this.lat,
    this.lng,
    this.mapLink,
    this.phone,
    this.website,
    this.facebook,
    this.instagram,
    this.openingHours,
    this.imageUrl,
    this.rating,
    this.status,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['name'],
      mainCategory: json['main_category'],
      subCategory: json['sub_category'],
      description: json['description'],
      address: json['address'],
      district: json['district'],
      municipality: json['municipality'],
      lat: json['lat'] != null ? (json['lat'] as num).toDouble() : null,
      lng: json['lng'] != null ? (json['lng'] as num).toDouble() : null,
      mapLink: json['map_link'],
      phone: json['phone'],
      website: json['website'],
      facebook: json['facebook'],
      instagram: json['instagram'],
      openingHours: json['opening_hours'],
      imageUrl: json['image_url'],
      rating: json['rating'],
      status: json['status'],
    );
  }
}
