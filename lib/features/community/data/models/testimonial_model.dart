import '../../domain/entities/testimonial.dart';
class TestimonialModel extends Testimonial {
  const TestimonialModel({
    required super.id,
    super.name,
    required super.message,
    required super.photos,
    required super.createdAt,
  });
  factory TestimonialModel.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'];
    final photosList = <String>[];
    if (rawPhotos is List) {
      for (final item in rawPhotos) {
        if (item != null) photosList.add(item.toString());
      }
    }
    return TestimonialModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString(),
      message: json['message']?.toString() ?? '',
      photos: photosList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
