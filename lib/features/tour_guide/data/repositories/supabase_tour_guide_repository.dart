import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/tour_guide_answer.dart';
import '../../domain/repositories/tour_guide_repository.dart';

class SupabaseTourGuideRepository implements TourGuideRepository {
  SupabaseTourGuideRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TourGuideAnswer> ask({
    required String question,
    String? placeName,
  }) async {
    final normalizedQuestion = question.trim();
    if (normalizedQuestion.isEmpty || normalizedQuestion.length > 500) {
      throw const AppException(
        'Votre question doit comporter entre 1 et 500 caractères.',
      );
    }

    try {
      final response = await _client.functions.invoke(
        'tour-guide',
        body: {
          'question': normalizedQuestion,
          if (placeName?.trim().isNotEmpty == true) 'place_name': placeName,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const AppException('Réponse du guide invalide.');
      }
      return TourGuideAnswer.fromJson(data);
    } on FunctionException catch (error) {
      throw AppException(
        'Le guide est temporairement indisponible. Réessayez dans un instant.',
        cause: error.status,
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(
        'Une erreur est survenue lors de la consultation du guide.',
        cause: error.runtimeType,
      );
    }
  }
}
