import '../entities/testimonial.dart';
abstract interface class CommunityRepository {
  Future<List<Testimonial>> getApprovedTestimonials({int limit = 12});
  Future<void> submitExperience({
    String? name,
    required String message,
    required List<ExperiencePhoto> photos,
  });
}
