import 'dart:typed_data';

import '../entities/testimonial.dart';

class ExperiencePhoto {
  const ExperiencePhoto({required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;
}

abstract class CommunityRepository {
  Future<List<Testimonial>> getApprovedTestimonials({int limit = 12});

  Future<void> submitExperience({
    String? name,
    required String message,
    required List<ExperiencePhoto> photos,
  });
}
