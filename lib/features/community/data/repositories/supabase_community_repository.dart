import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/testimonial.dart';
import '../../domain/entities/visitor_inquiry.dart';
import '../../domain/repositories/community_repository.dart';
import '../models/testimonial_model.dart';

class SupabaseCommunityRepository implements CommunityRepository {
  SupabaseCommunityRepository(this._client);

  static const _bucket = 'testimonials-photos';
  static const _maxPhotoBytes = 8 * 1024 * 1024;

  final SupabaseClient _client;

  @override
  Future<List<Testimonial>> getApprovedTestimonials({int limit = 12}) async {
    try {
      final response = await _client
          .from('testimonials')
          .select('id,name,message,photos,created_at')
          .eq('status', 'approved')
          .order('created_at', ascending: false)
          .limit(limit.clamp(1, 30));
      return (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(TestimonialModel.fromJson)
          .where((testimonial) =>
              testimonial.id > 0 && testimonial.message.isNotEmpty)
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw AppException('تعذر تحميل تجارب الزوار حالياً.', cause: error.code);
    } catch (error) {
      throw AppException('تعذر تحميل تجارب الزوار حالياً.',
          cause: error.runtimeType);
    }
  }

  @override
  Future<void> submitExperience({
    String? name,
    required String message,
    required List<ExperiencePhoto> photos,
  }) async {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty || normalizedMessage.length > 1800) {
      throw const AppException('اكتب تجربتك في نص لا يتجاوز 1800 حرفاً.');
    }
    if (photos.length > 5) {
      throw const AppException('يمكنك إرفاق خمس صور كحد أقصى.');
    }

    final publicUrls = <String>[];
    final storage = _client.storage.from(_bucket);
    final prefix = DateTime.now().microsecondsSinceEpoch;

    try {
      for (var index = 0; index < photos.length; index++) {
        final photo = photos[index];
        if (photo.bytes.isEmpty || photo.bytes.length > _maxPhotoBytes) {
          throw const AppException('يجب ألا يتجاوز حجم كل صورة 8 ميغابايت.');
        }

        final extension = _imageExtension(photo.fileName);
        final path = 'testimonials/$prefix-$index.$extension';
        await storage.uploadBinary(
          path,
          photo.bytes,
          fileOptions: FileOptions(
            contentType: _contentType(extension),
            upsert: false,
          ),
        );
        publicUrls.add(storage.getPublicUrl(path));
      }

      await _client.from('testimonials').insert({
        'name': _nullable(name),
        'message': normalizedMessage,
        'photos': publicUrls,
        'status': 'pending',
      });
    } on StorageException catch (error) {
      throw AppException('تعذر رفع الصور. يرجى استخدام صور JPG أو PNG أو WebP.',
          cause: error.statusCode);
    } on PostgrestException catch (error) {
      throw AppException('تعذر إرسال التجربة للمراجعة حالياً.',
          cause: error.code);
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(
          'تعذر إرسال تجربتك. تحقق من اتصال الإنترنت ثم أعد المحاولة.',
          cause: error.runtimeType);
    }
  }

  @override
  Future<void> submitFeedback({
    String? name,
    required String message,
    required int rating,
    int? placeId,
  }) async {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty || normalizedMessage.length > 3000) {
      throw const AppException('اكتب ملاحظة لا تتجاوز 3000 حرف.');
    }
    if (rating < 1 || rating > 5) {
      throw const AppException('اختر تقييماً من نجمة واحدة إلى خمس نجوم.');
    }

    try {
      await _client.from('feedback').insert({
        'name': _nullable(name),
        'message': normalizedMessage,
        'rating': rating,
        'feedback_scope': placeId == null ? 'app' : 'place',
        'place_id': placeId,
        'status': 'pending',
      });
    } on PostgrestException catch (error) {
      throw AppException('تعذر إرسال تقييمك حالياً.', cause: error.code);
    } catch (error) {
      throw AppException(
          'تعذر إرسال تقييمك. تحقق من اتصال الإنترنت ثم أعد المحاولة.',
          cause: error.runtimeType);
    }
  }

  @override
  Future<void> submitInquiry({
    String? name,
    String? contactInfo,
    String? subject,
    required String message,
    required VisitorInquiryKind kind,
  }) async {
    final normalizedMessage = message.trim();
    final normalizedSubject = _nullable(subject);
    final normalizedContact = _nullable(contactInfo);
    if (normalizedMessage.isEmpty || normalizedMessage.length > 3000) {
      throw const AppException('اكتب رسالتك في نص لا يتجاوز 3000 حرف.');
    }
    if (normalizedSubject != null && normalizedSubject.length > 160) {
      throw const AppException('عنوان الرسالة يجب ألا يتجاوز 160 حرفاً.');
    }
    if (normalizedContact != null && normalizedContact.length > 180) {
      throw const AppException('بيانات التواصل يجب ألا تتجاوز 180 حرفاً.');
    }

    try {
      await _client.from('suggestions').insert({
        'name': _nullable(name),
        'contact_info': normalizedContact,
        'subject': normalizedSubject,
        'message': normalizedMessage,
        'kind': kind.databaseValue,
        'status': 'new',
      });
    } on PostgrestException catch (error) {
      throw AppException('تعذر إرسال رسالتك حالياً.', cause: error.code);
    } catch (error) {
      throw AppException(
          'تعذر إرسال رسالتك. تحقق من اتصال الإنترنت ثم أعد المحاولة.',
          cause: error.runtimeType);
    }
  }

  String? _nullable(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  String _imageExtension(String fileName) {
    final clean = fileName.trim().toLowerCase();
    if (!clean.contains('.')) return 'jpg';
    final extension = clean.split('.').last;
    if ({'png'}.contains(extension)) return 'png';
    if ({'webp'}.contains(extension)) return 'webp';
    return 'jpg';
  }

  String _contentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
