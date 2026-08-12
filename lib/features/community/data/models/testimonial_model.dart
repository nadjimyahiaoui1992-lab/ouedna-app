import '../../domain/entities/testimonial.dart';

class TestimonialModel extends Testimonial {
  const TestimonialModel({
    required super.id,
    required super.message,
    required super.photoUrls,
    super.name,
    super.createdAt,
  });

  factory TestimonialModel.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'];
    final photoUrls = rawPhotos is List
        ? rawPhotos
            .map((item) => item?.toString().trim())
            .whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList(growable: false)
        : const <String>[];
    final rawId = json['id'];
    final rawCreatedAt = json['created_at']?.toString();

    return TestimonialModel(
      id: rawId is int ? rawId : int.tryParse('$rawId') ?? 0,
      name: _optionalText(json['name']),
      message: _optionalText(json['message']) ?? '',
      photoUrls: photoUrls,
      createdAt: rawCreatedAt == null ? null : DateTime.tryParse(rawCreatedAt),
    );
  }

  static String? _optionalText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}
