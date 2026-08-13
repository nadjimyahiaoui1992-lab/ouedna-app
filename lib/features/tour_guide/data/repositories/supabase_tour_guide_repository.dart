import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/tour_guide_repository.dart';
class SupabaseTourGuideRepository implements TourGuideRepository {
  SupabaseTourGuideRepository(this._client);
  final SupabaseClient _client;
  @override
  Future<String> ask({required String question}) async {
    final clean = question.trim();
    if (clean.isEmpty) {
      throw const AppException('يرجى كتابة سؤالك للمساعد السياحي.');
    }
    try {
      final response = await _client.functions.invoke(
        'tour-guide-ai',
        body: {'question': clean},
      );
      final data = response.data;
      if (data is Map) {
        if (data['error'] != null) {
          throw AppException('عذراً، تعذر الرد: ${data['error']}');
        }
        final answer = data['answer']?.toString() ?? data['response']?.toString();
        if (answer != null && answer.isNotEmpty) return answer;
      }
      return 'أهلاً بك في وادنا! يسرني مساعدتك في استكشاف معالم ولاية الوادي الرائعة.';
    } on FunctionException catch (error) {
      throw AppException('تعذر الاتصال بالمساعد الذكي: ${error.details ?? error.reasonPhrase}');
    } catch (error) {
      throw AppException('تعذر الاتصال بالمساعد الذكي حالياً.');
    }
  }
}
