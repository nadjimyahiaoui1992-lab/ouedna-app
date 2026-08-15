import '../../domain/entities/archive_memory.dart';

class ArchiveMemoryModel extends ArchiveMemory {
  ArchiveMemoryModel({
    required super.id,
    required super.title,
    required super.images,
    required super.sourceLabel,
    super.description,
    super.period,
    super.createdAt,
  });

  factory ArchiveMemoryModel.fromOldMemory(Map<String, dynamic> json) {
    return ArchiveMemoryModel(
      id: 'memory-${json['id'] ?? ''}',
      title: _text(json['caption']) ?? 'من ذاكرة الوادي',
      images: _images(json['image_url'], json['gallery']),
      sourceLabel: 'ذاكرة الوادي',
      period: _text(json['year']),
      createdAt: _date(json['created_at']),
    );
  }

  factory ArchiveMemoryModel.fromHeritage(Map<String, dynamic> json) {
    return ArchiveMemoryModel(
      id: 'heritage-${json['id'] ?? ''}',
      title: _text(json['title']) ?? 'من تراث وادي سوف',
      description: _text(json['text']),
      images: _images(json['image'], json['gallery']),
      sourceLabel: 'تراث وادي سوف',
      period: _text(json['year']),
      createdAt: _date(json['created_at']),
    );
  }

  static List<String> _images(dynamic primary, dynamic gallery) {
    final urls = <String>[];
    void append(dynamic value) {
      if (value is List) {
        for (final item in value) {
          append(item);
        }
        return;
      }
      if (value is! String) return;
      final normalized = value.trim().replaceAll(RegExp(r'''[\[\]"']'''), '');
      for (final item in normalized.split(',')) {
        final url = item.trim();
        if (url.startsWith('http://') || url.startsWith('https://')) {
          urls.add(url);
        }
      }
    }

    append(primary);
    append(gallery);
    return urls.toSet().toList(growable: false);
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static DateTime? _date(dynamic value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
