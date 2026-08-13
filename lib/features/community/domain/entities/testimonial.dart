import 'dart:typed_data';
class ExperiencePhoto {
  const ExperiencePhoto({required this.bytes, required this.fileName});
  final Uint8List bytes;
  final String fileName;
}
class Testimonial {
  const Testimonial({
    required this.id,
    this.name,
    required this.message,
    required this.photos,
    required this.createdAt,
  });
  final int id;
  final String? name;
  final String message;
  final List<String> photos;
  final DateTime createdAt;
}
