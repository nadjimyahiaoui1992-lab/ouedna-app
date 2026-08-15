class ArchiveMemory {
  const ArchiveMemory({
    required this.id,
    required this.title,
    required this.images,
    required this.sourceLabel,
    this.description,
    this.period,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String? period;
  final List<String> images;
  final String sourceLabel;
  final DateTime? createdAt;
}
