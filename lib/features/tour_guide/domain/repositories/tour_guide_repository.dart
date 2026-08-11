import '../entities/tour_guide_answer.dart';

abstract interface class TourGuideRepository {
  Future<TourGuideAnswer> ask({
    required String question,
    String? placeName,
  });
}
