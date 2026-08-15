import '../entities/archive_memory.dart';
import '../entities/testimonial.dart';
import '../entities/visitor_inquiry.dart';

abstract interface class CommunityRepository {
  Future<List<Testimonial>> getApprovedTestimonials({int limit = 12});
  Future<List<ArchiveMemory>> getPublishedArchive({int limit = 48});
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
