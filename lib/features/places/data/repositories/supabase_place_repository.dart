import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/place_repository.dart';
import '../models/place_model.dart';

class SupabasePlaceRepository implements PlaceRepository {
  SupabasePlaceRepository(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id,name,main_category,description,address,image_url,rating,opening_hours,lat,lng';

  @override
  Future<List<Place>> getPublishedPlaces({String? query}) async {
    try {
      final normalizedQuery = query?.trim();
      final response = normalizedQuery == null || normalizedQuery.isEmpty
          ? await _client
              .from('places')
              .select(_columns)
              .eq('status', 'منشور')
              .order('rating', ascending: false)
              .limit(30)
          : await _client
              .from('places')
              .select(_columns)
              .eq('status', 'منشور')
              .or(
                'name.ilike.%${_escapeLike(normalizedQuery)}%,'
                'description.ilike.%${_escapeLike(normalizedQuery)}%,'
                'main_category.ilike.%${_escapeLike(normalizedQuery)}%',
              )
              .order('rating', ascending: false)
              .limit(30);

      return (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PlaceModel.fromJson)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw AppException(
        'تعذر الوصول إلى معالم سوف 360 حالياً.',
        cause: error.code,
      );
    } catch (error) {
      throw AppException(
        'تعذر تحميل المعالم السياحية.',
        cause: error.runtimeType,
      );
    }
  }

  @override
  Stream<void> watchPublishedPlaces() {
    final controller = StreamController<void>.broadcast();
    final channel = _client
        .channel('souf-tour-places-${DateTime.now().microsecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'places',
          callback: (_) {
            if (!controller.isClosed) controller.add(null);
          },
        )
        .subscribe();

    controller.onCancel = () => _client.removeChannel(channel);
    return controller.stream;
  }

  String _escapeLike(String value) => value.replaceAll(RegExp(r'[%_(),]'), ' ');
}
