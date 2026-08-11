class TourGuideAnswer {
  const TourGuideAnswer({
    required this.answer,
    required this.suggestions,
    this.disclaimer,
  });

  final String answer;
  final List<String> suggestions;
  final String? disclaimer;

  factory TourGuideAnswer.fromJson(Map<String, dynamic> json) {
    final rawSuggestions = json['suggestions'];
    return TourGuideAnswer(
      answer: (json['answer'] as String?)?.trim() ??
          'Je ne peux pas répondre à cette question pour le moment.',
      suggestions: rawSuggestions is List
          ? rawSuggestions
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .take(3)
              .toList(growable: false)
          : const [],
      disclaimer: (json['disclaimer'] as String?)?.trim(),
    );
  }
}
