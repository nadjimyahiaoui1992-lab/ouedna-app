abstract final class AppConfig {
  // These values are the public, browser-delivered settings used by Souf360.
  // They provide read-only access constrained by the backend's RLS policies.
  static const _defaultSupabaseUrl = 'https://cwbenhuiextfoiyfboxo.supabase.co';
  static const _defaultSupabasePublishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3YmVuaHVpZXh0Zm9peWZib3hvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM3NDIwMjcsImV4cCI6MjA5OTMxODAyN30.coWbBaPvT08K_zk8ZQyedJ-gFcr_q9HQS8r5mXqu50I';

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultSupabaseUrl,
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: _defaultSupabasePublishableKey,
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.startsWith('https://') && supabasePublishableKey.isNotEmpty;
}
