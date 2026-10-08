import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../game/engine/process_engine.dart';
import '../game/engine/growing_bed.dart';
import 'content.dart';
import 'database.dart';

final controllerProvider = ChangeNotifierProvider<AppController>(
  (ref) => throw StateError('Controller must be initialized'),
);

class AppController extends ChangeNotifier {
  final ContentLibrary library;
  final SaveDatabase database;
  final ProcessEngine engine;
  String profileId;
  final Set<String> completed = {};
  final Map<String, ProcessInstance> processes = {};
  final Map<String, Set<String>> actions = {};
  final Set<String> decorations = {};
  final Map<int, GrowingBed> beds = {};
  final Set<String> plantCards = {};
  final List<Map<String, dynamic>> scans = [];
  final Map<String, dynamic> settings = {
    'reading': 'Simple',
    'age': 'under13',
    'onboarded': false,
    'pace': 'guided',
    'motion': true,
    'readAloud': false,
    'music': false,
    'sound': true,
    'notifications': false,
    'timeLimit': 0,
    'cloud': false,
  };
  int xp = 0, coins = 0, streak = 0, cloudRevision = 0;
  int sessionSeconds = 0;
  bool parentVerified = false;
  String? lastDay, error, lastFreezeWeek;
  Future<void> _writes = Future.value();
  AppController(this.library, this.database, {Clock? clock, String? profileId})
    : engine = ProcessEngine(clock ?? SystemClock()),
      profileId = profileId ?? const Uuid().v4();
  static Future<AppController> load(
    ContentLibrary library,
    SaveDatabase database,
  ) async {
    final j = await database.load();
    final c = AppController(library, database, profileId: j?['profileId']);
    if (j != null) {
      if (j['schemaVersion'] != 1) throw StateError('Unsupported save version');
      c.completed.addAll(List<String>.from(j['completed'] ?? []));
      c.xp = j['xp'] ?? 0;
      c.coins = j['coins'] ?? 0;
      c.streak = j['streak'] ?? 0;
      c.lastDay = j['lastDay'];
      c.lastFreezeWeek = j['lastFreezeWeek'];
      c.cloudRevision = j['cloudRevision'] ?? 0;
      c.settings.addAll(Map<String, dynamic>.from(j['settings'] ?? {}));
      c.decorations.addAll(List<String>.from(j['decorations'] ?? []));
      c.plantCards.addAll(List<String>.from(j['plantCards'] ?? []));
      (j['beds'] as Map? ?? {}).forEach(
        (k, v) => c.beds[int.parse(k)] = GrowingBed.fromJson(
          Map<String, dynamic>.from(v),
        ),
      );
      c.scans.addAll(List<Map<String, dynamic>>.from(j['scans'] ?? []));
      for (final p in (j['processes'] as List? ?? [])) {
        final instance = ProcessInstance.fromJson(p);
        c.processes[instance.questId] = instance;
      }
      (j['actions'] as Map? ?? {}).forEach(
        (key, value) => c.actions[key] = Set<String>.from(value),
      );
    }
    c.refresh();
    return c;
  }

  int get level => 1 + xp ~/ 120;
  bool get onboarded => settings['onboarded'] == true;
  bool get breakRequired =>
      (settings['timeLimit'] as int) > 0 &&
      sessionSeconds >= (settings['timeLimit'] as int) * 60;
  void tickSession() {
    if (!breakRequired) {
      sessionSeconds++;
      if (breakRequired) notifyListeners();
    }
  }

  bool available(Quest q) => engine.unlocked(q.prerequisites, completed);
  ProcessInstance process(Quest q) =>
      processes.putIfAbsent(q.id, () => ProcessInstance(questId: q.id));
  int targetActions(Quest q) =>
      q.template == 'pour' || q.template == 'timing' ? 5 : q.items.length;
  int doneActions(Quest q) => actions[q.id]?.length ?? 0;
  int topicCount(Topic t) =>
      t.quests.where((q) => completed.contains(q.id)).length;
  Quest? get nextQuest {
    for (final t in library.topics) {
      for (final q in t.quests) {
        if (!completed.contains(q.id) && available(q)) return q;
      }
    }
    return null;
  }

  void start(Quest q) {
    if (!available(q) || completed.contains(q.id)) return;
    engine.start(process(q));
    persist();
  }

  void recordAction(Quest q, String actionId) {
    final p = process(q);
    if (p.status != ProcessStatus.playing) return;
    final set = actions.putIfAbsent(q.id, () => {});
    if (set.length >= targetActions(q) || !set.add(actionId)) return;
    p.actions = set.length;
    if (set.length >= targetActions(q)) {
      engine.finishInteraction(
        p,
        settings['pace'] == 'garden' ? q.gardenSeconds : q.waitSeconds,
      );
    }
    persist();
  }

  bool claim(Quest q, int answer) {
    if (answer != q.correct ||
        completed.contains(q.id) ||
        !engine.complete(process(q))) {
      return false;
    }
    completed.add(q.id);
    xp += q.xp;
    coins += q.coins;
    final day = DateTime.now();
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    if (lastDay != key) {
      final previous = DateTime.tryParse(lastDay ?? '');
      final delta = previous == null
          ? null
          : DateTime(day.year, day.month, day.day)
                .difference(
                  DateTime(previous.year, previous.month, previous.day),
                )
                .inDays;
      final monday = DateTime(
        day.year,
        day.month,
        day.day,
      ).subtract(Duration(days: day.weekday - 1));
      final week = '${monday.year}-${monday.month}-${monday.day}';
      if (delta == 2 && lastFreezeWeek != week) {
        streak++;
        lastFreezeWeek = week;
      } else {
        streak = delta == 1 ? streak + 1 : 1;
      }
      lastDay =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    }
    persist();
    return true;
  }

  void refresh() {
    for (final p in processes.values) {
      engine.refresh(p);
    }
    for (final bed in beds.values) {
      engine.refresh(bed.process);
    }
    notifyListeners();
  }

  void plant(int slot, String plantId) {
    if (slot < 0 ||
        slot > 2 ||
        beds[slot]?.process.status == ProcessStatus.waiting ||
        beds[slot]?.process.status == ProcessStatus.ready) {
      return;
    }
    final plant = library.plants.firstWhere((p) => p['id'] == plantId);
    final p = ProcessInstance(questId: 'plant-$plantId');
    engine.start(p);
    engine.finishInteraction(
      p,
      settings['pace'] == 'garden'
          ? plant['gardenPaceSeconds']
          : plant['gameGrowthSeconds'],
    );
    beds[slot] = GrowingBed(plantId, p);
    persist();
  }

  void waterBed(int slot) {
    final bed = beds[slot];
    if (bed == null) return;
    bed.wateredAt = engine.clock.now();
    persist();
  }

  bool harvestBed(int slot) {
    final bed = beds[slot];
    if (bed == null ||
        bed.needsCare(engine.clock.now()) ||
        !engine.complete(bed.process)) {
      return false;
    }
    plantCards.add(bed.plantId);
    persist();
    return true;
  }

  bool speedUp(Quest q, int answer) {
    if (answer != q.correct || !engine.speedUp(process(q))) return false;
    persist();
    return true;
  }

  bool buy(String id, int cost) {
    const prices = {'flower-path': 30, 'sunny-sign': 50, 'garden-bench': 80};
    if (prices[id] != cost) return false;
    if (cost < 0 || coins < cost || decorations.contains(id)) return false;
    coins -= cost;
    decorations.add(id);
    persist();
    return true;
  }

  void setSetting(String key, dynamic value) {
    settings[key] = value;
    persist();
  }

  void addScan(Map<String, dynamic> result) {
    scans.insert(0, result);
    if (scans.length > 50) scans.removeLast();
    persist();
  }

  Map<String, dynamic> toJson() => {
    'cloudRevision': cloudRevision,
    'schemaVersion': 1,
    'profileId': profileId,
    'completed': completed.toList(),
    'xp': xp,
    'coins': coins,
    'streak': streak,
    'lastDay': lastDay,
    'lastFreezeWeek': lastFreezeWeek,
    'processes': processes.values.map((p) => p.toJson()).toList(),
    'actions': actions.map((k, v) => MapEntry(k, v.toList())),
    'settings': settings,
    'decorations': decorations.toList(),
    'plantCards': plantCards.toList(),
    'beds': beds.map((k, v) => MapEntry(k.toString(), v.toJson())),
    'scans': scans,
  };
  void persist() {
    final snapshot = jsonDecode(jsonEncode(toJson())) as Map<String, dynamic>;
    _writes = _writes
        .then(
          (_) => database.save(
            snapshot,
            operationId: settings['cloud'] == true ? const Uuid().v4() : null,
          ),
        )
        .then((_) {
          error = null;
        })
        .catchError((Object e) {
          error = 'Your latest changes could not be saved. Please keep the app open and retry.';
          notifyListeners();
        });
    notifyListeners();
  }

  Future<void> flush() => _writes;
  Future<void> reset() async {
    await _writes;
    await database.clear();
    completed.clear();
    processes.clear();
    actions.clear();
    decorations.clear();
    beds.clear();
    plantCards.clear();
    scans.clear();
    xp = 0;
    coins = 0;
    streak = 0;
    lastDay = null;
    lastFreezeWeek = null;
    cloudRevision = 0;
    sessionSeconds = 0;
    parentVerified = false;
    profileId = const Uuid().v4();
    settings.clear();
    settings.addAll({
      'reading': 'Simple',
      'age': 'under13',
      'onboarded': false,
      'pace': 'guided',
      'motion': true,
      'readAloud': false,
      'music': false,
      'sound': true,
      'notifications': false,
      'timeLimit': 0,
      'cloud': false,
    });
    notifyListeners();
  }
}
