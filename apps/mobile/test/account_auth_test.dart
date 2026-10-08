import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nurturio/core/account_auth.dart';

class MemoryPkceStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

void main() {
  final user = {
    'id': 'abbe6c3d-9e8e-45a1-aa7e-b16a0e634492',
    'aud': 'authenticated',
    'role': 'authenticated',
    'email': 'player@example.com',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'created_at': '2026-10-09T00:00:00Z',
  };
  test(
    'sign-up preserves email confirmation instead of inventing a session',
    () async {
      final client = SupabaseClient(
        'https://project.supabase.co',
        'test-publishable',
        authOptions: AuthClientOptions(
          autoRefreshToken: false,
          pkceAsyncStorage: MemoryPkceStorage(),
        ),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/auth/v1/signup');
          final body = jsonDecode(request.body) as Map;
          expect(body['email'], 'player@example.com');
          expect(body['password'], 'a-test-password');
          expect(
            request.url.queryParameters['redirect_to'],
            'https://nurturio.jauntybud16.chatgpt.site',
          );
          return http.Response(jsonEncode(user), 200);
        }),
      );
      final response = await AccountAuth(client)
          .signUp(' player@example.com ', 'a-test-password');
      expect(response.user?.id, user['id']);
      expect(response.session, isNull);
      expect(client.auth.currentSession, isNull);
      await client.dispose();
    },
  );
  test(
    'password sign-in creates the server session and sign-out clears it',
    () async {
      final client = SupabaseClient(
        'https://project.supabase.co',
        'test-publishable',
        authOptions: AuthClientOptions(
          autoRefreshToken: false,
          pkceAsyncStorage: MemoryPkceStorage(),
        ),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/logout')) {
            return http.Response('', 204);
          }
          expect(request.url.path, '/auth/v1/token');
          expect(request.url.queryParameters['grant_type'], 'password');
          expect(jsonDecode(request.body)['email'], 'player@example.com');
          return http.Response(
            jsonEncode({
              'access_token': 'test-session-token',
              'refresh_token': 'test-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': user,
            }),
            200,
          );
        }),
      );
      final auth = AccountAuth(client);
      await auth.signIn(' player@example.com ', 'a-test-password');
      expect(client.auth.currentUser?.id, user['id']);
      await auth.signOut();
      expect(client.auth.currentSession, isNull);
      await client.dispose();
    },
  );
  test(
    'invalid credentials are surfaced without a local signed-in state',
    () async {
      final client = SupabaseClient(
        'https://project.supabase.co',
        'test-publishable',
        authOptions: AuthClientOptions(
          autoRefreshToken: false,
          pkceAsyncStorage: MemoryPkceStorage(),
        ),
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'code': 'invalid_credentials',
              'msg': 'Invalid login credentials',
            }),
            400,
          ),
        ),
      );
      await expectLater(
        AccountAuth(client).signIn('player@example.com', 'wrong-password'),
        throwsA(isA<AuthException>()),
      );
      expect(client.auth.currentSession, isNull);
      await client.dispose();
    },
  );
}
