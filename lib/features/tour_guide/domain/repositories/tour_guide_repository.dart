abstract interface class TourGuideRepository {
  Future<String> ask({required String question});
}
