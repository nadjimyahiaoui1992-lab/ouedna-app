class Testimonial {
  const Testimonial({
    required this.id,
    required this.message,
    required this.photoUrls,
    this.name,
    this.createdAt,
  });

  final int id;
  final String? name;
  final String message;
  final List<String> photoUrls;
  final DateTime? createdAt;
}
