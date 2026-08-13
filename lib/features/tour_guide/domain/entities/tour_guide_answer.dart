class TourGuideAnswer {
  const TourGuideAnswer({required this.answer, this.sources, this.suggestions, this.disclaimer});
  final String answer;
  final List<String>? sources;
  final List<String>? suggestions;
  final String? disclaimer;
}
