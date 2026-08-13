enum VisitorInquiryKind {
  suggestion,
  question;

  String get databaseValue => switch (this) {
        VisitorInquiryKind.suggestion => 'suggestion',
        VisitorInquiryKind.question => 'question',
      };
}
