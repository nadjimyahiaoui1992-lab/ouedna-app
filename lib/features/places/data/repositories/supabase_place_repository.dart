import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/place_gallery_image.dart';
import '../../domain/entities/place_page.dart';
import '../../domain/repositories/place_repository.dart';
import '../models/place_gallery_image_model.dart';
import '../models/place_model.dart';

class SupabasePlaceRepository implements PlaceRepository {
  SupabasePlaceRepository(this._client);

  final SupabaseClient _client;

  static const _columns =
      'id,name,main_category,sub_category,description,address,district,municipality,'
      'image_url,rating,opening_hours,lat,lng,map_link,phone,website,facebook,instagram,'
      'created_at,updated_at';

  @override
  Future<PlacePage> getPublishedPlacesPage({
    String? query,
    String? category,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final normalizedQuery = query?.trim();
      final normalizedCategory = category?.trim();
      var request =
          _client.from('places').select(_columns).eq('status', 'منشور');

      if (normalizedCategory != null && normalizedCategory.isNotEmpty) {
        request = request.eq('main_category', normalizedCategory);
      }
      if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
        final safeQuery = _escapeLike(normalizedQuery);
        request = request.or(
          'name.ilike.%$safeQuery%,'
          'description.ilike.%$safeQuery%,'
          'main_category.ilike.%$safeQuery%,'
          'sub_category.ilike.%$safeQuery%,'
          'address.ilike.%$safeQuery%,'
          'district.ilike.%$safeQuery%,'
          'municipality.ilike.%$safeQuery%',
        );
      }

      final response = await request
          .order('updated_at', ascending: false)
          .range(offset, offset + limit - 1);
      final places = (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PlaceModel.fromJson)
          .toList(growable: false);
      return PlacePage(places: places, offset: offset, limit: limit);
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
  Future<List<Place>> getPublishedPlaces({String? query}) async {
    final page = await getPublishedPlacesPage(query: query, limit: 100);
    return page.places;
  }

  @override
  Future<List<String>> getPublishedCategories() async {
    try {
      final response = await _client
          .from('places')
          .select('main_category')
          .eq('status', 'منشور')
          .limit(100);
      return (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((item) => item['main_category']?.toString().trim())
          .whereType<String>()
          .where((category) => category.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<PlaceGalleryImage>> getPlaceGallery(int placeId) async {
    try {
      final response = await _client
          .from('gallery')
          .select('id,place_id,image_url,title,description,is_cover,sort_order')
          .eq('place_id', placeId)
          .order('is_cover', ascending: false)
          .order('sort_order')
          .limit(30);
      return (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PlaceGalleryImageModel.fromJson)
          .where((image) => image.imageUrl.isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> submitVisitorPlace({
    required String name,
    required String mainCategory,
    String? subCategory,
    String? description,
    String? address,
    String? municipality,
    String? phone,
    String? mapLink,
    String? openingHours,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const AppException('يرجى إدخال اسم المعلم.');
    }

    String? imageUrl;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final ext = imageFileName?.split('.').last.toLowerCase() ?? 'jpg';
      final fileName =
          'places/visitor_${DateTime.now().millisecondsSinceEpoch}_${_randomString(6)}.$ext';
      await _client.storage.from('images').uploadBinary(
            fileName,
            imageBytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );
      imageUrl = _client.storage.from('images').getPublicUrl(fileName);
    }

    final data = {
      'name': normalizedName,
      'main_category': mainCategory,
      'sub_category':
          subCategory?.trim().isNotEmpty == true ? subCategory!.trim() : null,
      'description':
          description?.trim().isNotEmpty == true ? description!.trim() : null,
      'address': address?.trim().isNotEmpty == true ? address!.trim() : null,
      'municipality':
          municipality?.trim().isNotEmpty == true ? municipality!.trim() : null,
      'phone': phone?.trim().isNotEmpty == true ? phone!.trim() : null,
      'map_link': mapLink?.trim().isNotEmpty == true ? mapLink!.trim() : null,
      'opening_hours':
          openingHours?.trim().isNotEmpty == true ? openingHours!.trim() : null,
      'image_url': imageUrl,
      'status': 'قيد المراجعة',
    };

    try {
      await _client.from('places').insert(data);
    } catch (e) {
      throw AppException('تعذر إرسال المعلم: $e');
    }
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
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
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'gallery',
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
