// Fill these in with your own Supabase project's values before building.
// Find them in your Supabase project: Settings -> API.
// The anon key is safe to ship inside the app — it only allows what your
// Row Level Security policies (see supabase/schema.sql) permit.
class AppConfig {
  static const String supabaseUrl = 'https://umzxvquoncllampmtnie.supabase.co';
  static const String supabasePublishableKey = 'sb_publishable_yvdJmT69mj8S6t40SaFeDQ_sWQuHF5t';

  static const String appName = 'Ababil';
  static const String receiptsBucket = 'receipts';
  static const String verificationBucket = 'verification';
  static const String avatarsBucket = 'avatars';

  // Bump this to match pubspec.yaml's `version:` (and the Git tag you
  // publish, e.g. v1.1.0) every time you build and release a new APK — the
  // in-app update checker compares this against the latest GitHub release
  // to decide whether to prompt members to update.
  static const String appVersion = '1.2.0';

  // owner/repo of the GitHub repository releases are published to. Must be
  // a PUBLIC repo: the update checker calls GitHub's public releases API
  // straight from the app, with no login token shipped inside it.
  static const String githubRepo = 'finstudio-dev/ababil_app';
}
