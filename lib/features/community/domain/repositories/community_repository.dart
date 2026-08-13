import '../entities/testimonial.dart';
import '../entities/visitor_inquiry.dart';

abstract interface class CommunityRepository {
  Future<List<Testimonial>> getApprovedTestimonials({int limit = 12});
  Future<void> submitExperience({
    String? name,
    required String message,
    required List<ExperiencePhoto> photos,
  });

  Future<void> submitFeedback({
    String? name,
    required String message,
    required int rating,
    int? placeId,
  });

  Future<void> submitInquiry({
    String? name,
    String? contactInfo,
    String? subject,
    required String message,
    required VisitorInquiryKind kind,
  });
}
