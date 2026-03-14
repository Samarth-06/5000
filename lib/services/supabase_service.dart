import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase service for auth and database operations.
class SupabaseService {
  SupabaseClient get _client => Supabase.instance.client;

  // ─── Auth ──────────────────────────────────────────────────────────────────
  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<AuthResponse> signUp(String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user != null) {
      await _client.from('users').upsert({'id': user.id, 'email': user.email});
    }
    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user != null) {
      await _client.from('users').upsert({'id': user.id, 'email': user.email});
    }
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ─── Farms ────────────────────────────────────────────────────────────────
  Future<void> insertFarm(Map<String, dynamic> farm) async {
    await _client.from('farms').upsert(farm);
  }

  Future<List<Map<String, dynamic>>> getFarms() async {
    final userId = currentUser?.id;
    if (userId == null) return [];
    return await _client.from('farms').select().eq('user_id', userId);
  }

  // ─── Vegetation History ───────────────────────────────────────────────────
  Future<void> insertVegetationHistory(Map<String, dynamic> data) async {
    await _client.from('vegetation_history').insert(data);
  }

  Future<List<Map<String, dynamic>>> getVegetationHistory(
    String farmId,
    int days,
  ) async {
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();
    return await _client
        .from('vegetation_history')
        .select()
        .eq('farm_id', farmId)
        .gte('timestamp', since)
        .order('timestamp', ascending: true);
  }

  // ─── Weather History ──────────────────────────────────────────────────────
  Future<void> insertWeatherHistory(Map<String, dynamic> data) async {
    await _client.from('weather_history').insert(data);
  }

  Future<List<Map<String, dynamic>>> getWeatherHistory(
    String farmId,
    int days,
  ) async {
    final since = DateTime.now()
        .subtract(Duration(days: days))
        .toIso8601String();
    return await _client
        .from('weather_history')
        .select()
        .eq('farm_id', farmId)
        .gte('timestamp', since)
        .order('timestamp', ascending: true);
  }

  // ─── Image Reports ────────────────────────────────────────────────────────
  Future<void> insertImageReport(Map<String, dynamic> data) async {
    await _client.from('image_reports').insert(data);
  }

  Future<List<Map<String, dynamic>>> getImageReports(String farmId) async {
    return await _client
        .from('image_reports')
        .select()
        .eq('farm_id', farmId)
        .order('created_at', ascending: false);
  }
}
