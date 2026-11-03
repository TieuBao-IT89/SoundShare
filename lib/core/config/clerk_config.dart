abstract final class ClerkConfig {
  static const publishableKey = String.fromEnvironment('CLERK_PUBLISHABLE_KEY');

  static const isConfigured = publishableKey != '';
}
