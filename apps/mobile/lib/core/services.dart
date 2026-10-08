import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import 'app_controller.dart';
import '../game/engine/process_engine.dart';

class SecureAuthStorage extends LocalStorage {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async =>
      (await storage.read(key: 'nurturio.auth')) != null;
  @override
  Future<String?> accessToken() => storage.read(key: 'nurturio.auth');
  @override
  Future<void> persistSession(String persistSessionString) =>
      storage.write(key: 'nurturio.auth', value: persistSessionString);
  @override
  Future<void> removePersistedSession() => storage.delete(key: 'nurturio.auth');
}

class CloudService {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static bool get configured => url.isNotEmpty && key.isNotEmpty;
  static Future<void> initialize() async {
    if (configured) {
      await Supabase.initialize(
        url: url,
        publishableKey: key,
        authOptions: FlutterAuthClientOptions(
          localStorage: SecureAuthStorage(),
        ),
      );
    }
  }

  SupabaseClient get client => Supabase.instance.client;
  Future<void> requestCode(String email) =>
      client.auth.signInWithOtp(email: email);
  Future<void> verifyCode(String email, String code) async {
    await client.auth.verifyOTP(email: email, token: code, type: OtpType.email);
  }

  Future<void> sync(AppController c) async {
    if (!configured || client.auth.currentSession == null) {
      throw StateError('Sign in first.');
    }
    await c.flush();
    final pending = await c.database.pending();
    final snapshot = c.toJson();
    snapshot.remove('scans');
    final result = await client.functions.invoke(
      'sync-progress',
      body: {
        'profileId': c.profileId,
        'snapshot': snapshot,
        'baseRevision': c.cloudRevision,
        'operationId': pending.isEmpty ? const Uuid().v4() : pending.last['id'],
      },
    );
    if (result.status != 200) throw StateError('Sync could not finish.');
    final data = Map<String, dynamic>.from(result.data);
    final remote = Map<String, dynamic>.from(data['snapshot']);
    c.cloudRevision = data['revision'];
    c.completed.addAll(List<String>.from(remote['completed']));
    c.decorations.addAll(List<String>.from(remote['decorations']));
    c.xp = c.completed.length * 30;
    final costs = {'flower-path': 30, 'sunny-sign': 50, 'garden-bench': 80};
    c.coins =
        c.completed.length * 10 -
        c.decorations.fold<int>(0, (total, id) => total + (costs[id] ?? 0));
    for (final p in (remote['processes'] as List? ?? [])) {
      final instance = ProcessInstance.fromJson(Map<String, dynamic>.from(p));
      c.processes.putIfAbsent(instance.questId, () => instance);
    }
    for (final id in c.completed) {
      if (c.processes[id] != null) {
        c.processes[id]!.status = ProcessStatus.completed;
      }
    }
    c.persist();
    await c.flush();
    for (final row in pending) {
      await c.database.acknowledge(row['id']);
    }
  }

  Future<Map<String, dynamic>> export() => client.functions
      .invoke('export-data')
      .then((r) => Map<String, dynamic>.from(r.data));
  Future<void> signOut() => client.auth.signOut();
  Future<void> deleteAccount() async {
    final r = await client.functions.invoke(
      'delete-account',
      body: {'confirmation': 'DELETE'},
    );
    if (r.status != 200) throw StateError('Deletion pending.');
    await client.auth.signOut();
  }
}

class ReminderService {
  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();
  final Map<int, String> scheduled = {};
  bool initialized = false;
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  Future<void> initialize() async {
    if (!supported) return;
    tzdata.initializeTimeZones();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    initialized = true;
  }

  Future<bool> request() async {
    if (!supported) return false;
    if (!initialized) await initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  Future<void> rebuild(AppController c) async {
    if (!supported || !initialized) return;
    if (c.settings['notifications'] != true) {
      await plugin.cancelAll();
      scheduled.clear();
      return;
    }
    for (final p in c.processes.values) {
      final id =
          c.library.topics
              .expand((t) => t.quests)
              .toList()
              .indexWhere((q) => q.id == p.questId) +
          1;
      if (p.status != ProcessStatus.waiting || p.readyAt == null) {
        await plugin.cancel(id: id);
        scheduled.remove(id);
        continue;
      }
      final stamp = p.readyAt!.toIso8601String();
      if (scheduled[id] == stamp) continue;
      final q = c.library.quest(p.questId);
      await plugin.zonedSchedule(
        id: id,
        title: 'A little discovery is ready',
        body: '${q.title} is ready when you are.',
        scheduledDate: tz.TZDateTime.from(p.readyAt!, tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'readiness',
            'Learning reminders',
            channelDescription: 'Optional process readiness reminders',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: q.id,
      );
      scheduled[id] = stamp;
    }
  }

  Future<void> clear() async {
    if (supported && initialized) await plugin.cancelAll();
    scheduled.clear();
  }
}

String prettyExport(AppController c) =>
    const JsonEncoder.withIndent('  ').convert(c.toJson());
