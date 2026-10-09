import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase owns account identities; guest game saves remain local.
class AccountAuth {
  final SupabaseClient client;
  AccountAuth(this.client);

  Future<AuthResponse> signUp(String email, String password) =>
      client.auth.signUp(
        email: email.trim(),
        password: password,
        emailRedirectTo: 'https://nurturio.jauntybud16.chatgpt.site',
      );

  Future<AuthResponse> signIn(String email, String password) =>
      client.auth.signInWithPassword(email: email.trim(), password: password);

  Future<void> signOut() => client.auth.signOut();
}
