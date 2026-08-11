import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  Future<List<Place>> getPlaces() async {
    try {
      final response = await _supabase
          .from('places')
          .select('*')
          .eq('status', 'منشور');

      return (response as List).map((e) => Place.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching places: $e');
      return [];
    }
  }

  Future<List<Place>> searchPlaces(String query) async {
    try {
      final response = await _supabase
          .from('places')
          .select('*')
          .eq('status', 'منشور')
          .or('name.ilike.%$query%,description.ilike.%$query%,main_category.ilike.%$query%');

      return (response as List).map((e) => Place.fromJson(e)).toList();
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('places')
          .select('main_category')
          .eq('status', 'منشور')
          .not('main_category', 'is', null);

      final categories = (response as List)
          .map((e) => e['main_category'] as String)
          .toSet()
          .toList();

      return categories;
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }
}
