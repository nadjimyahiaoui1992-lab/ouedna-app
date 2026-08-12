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
          'لا أستطيع الإجابة عن هذا السؤال حالياً. حاول مرة أخرى بعد قليل.',
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
