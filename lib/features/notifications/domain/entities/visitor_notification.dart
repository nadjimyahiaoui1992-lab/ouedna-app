enum VisitorNotificationType { appUpdate, place, announcement, event, safety }

enum VisitorNotificationTarget { none, place, update, url }

class VisitorNotification {
  const VisitorNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.target,
    required this.publishedAt,
    this.imageUrl,
    this.targetPlaceId,
    this.targetUrl,
  });

  final String id;
  final VisitorNotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final VisitorNotificationTarget target;
  final int? targetPlaceId;
  final String? targetUrl;
  final DateTime publishedAt;

  factory VisitorNotification.fromMap(Map<String, dynamic> map) {
    return VisitorNotification(
      id: map['id'].toString(),
      type: _typeFromString(map['type']?.toString()),
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      imageUrl: map['image_url']?.toString(),
      target: _targetFromString(map['target_type']?.toString()),
      targetPlaceId: (map['target_place_id'] as num?)?.toInt(),
      targetUrl: map['target_url']?.toString(),
      publishedAt: DateTime.tryParse(map['published_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static VisitorNotificationType _typeFromString(String? value) =>
      switch (value) {
        'app_update' => VisitorNotificationType.appUpdate,
        'place' => VisitorNotificationType.place,
        'event' => VisitorNotificationType.event,
        'safety' => VisitorNotificationType.safety,
        _ => VisitorNotificationType.announcement,
      };

  static VisitorNotificationTarget _targetFromString(String? value) =>
      switch (value) {
        'place' => VisitorNotificationTarget.place,
        'update' => VisitorNotificationTarget.update,
        'url' => VisitorNotificationTarget.url,
        _ => VisitorNotificationTarget.none,
      };
}
