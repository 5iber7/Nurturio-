import 'dart:math';

abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now().toUtc();
}

enum ProcessStatus { available, playing, waiting, ready, completed, needsCare }

class ProcessInstance {
  final String questId;
  ProcessStatus status;
  int actions;
  DateTime? startedAt, readyAt, lastObservedAt;
  final String contentVersion;
  ProcessInstance({
    required this.questId,
    this.status = ProcessStatus.available,
    this.actions = 0,
    this.startedAt,
    this.readyAt,
    this.lastObservedAt,
    this.contentVersion = '1.0.0',
  });
  Map<String, dynamic> toJson() => {
    'questId': questId,
    'status': status.name,
    'actions': actions,
    'startedAt': startedAt?.toIso8601String(),
    'readyAt': readyAt?.toIso8601String(),
    'lastObservedAt': lastObservedAt?.toIso8601String(),
    'contentVersion': contentVersion,
  };
  factory ProcessInstance.fromJson(Map<String, dynamic> j) => ProcessInstance(
    questId: j['questId'],
    status: ProcessStatus.values.byName(j['status']),
    actions: j['actions'] ?? 0,
    startedAt: DateTime.tryParse(j['startedAt'] ?? ''),
    readyAt: DateTime.tryParse(j['readyAt'] ?? ''),
    lastObservedAt: DateTime.tryParse(j['lastObservedAt'] ?? ''),
    contentVersion: j['contentVersion'] ?? '1.0.0',
  );
}

class ProcessEngine {
  final Clock clock;
  ProcessEngine(this.clock);
  bool unlocked(List<String> prerequisites, Set<String> completed) =>
      prerequisites.every(completed.contains);
  void start(ProcessInstance p) {
    if (p.status != ProcessStatus.available) return;
    p.status = ProcessStatus.playing;
    p.startedAt = clock.now();
    p.lastObservedAt = clock.now();
  }

  void finishInteraction(ProcessInstance p, int waitSeconds) {
    if (p.status != ProcessStatus.playing) return;
    p.readyAt = clock.now().add(Duration(seconds: max(0, waitSeconds)));
    p.lastObservedAt = clock.now();
    p.status = waitSeconds > 0 ? ProcessStatus.waiting : ProcessStatus.ready;
  }

  void refresh(ProcessInstance p) {
    if (p.status != ProcessStatus.waiting) return;
    final now = clock.now();
    if (p.lastObservedAt != null && now.isBefore(p.lastObservedAt!)) return;
    p.lastObservedAt = now;
    if (p.readyAt != null && !now.isBefore(p.readyAt!)) {
      p.status = ProcessStatus.ready;
    }
  }

  int remaining(ProcessInstance p) {
    refresh(p);
    return p.status == ProcessStatus.waiting
        ? max(0, p.readyAt!.difference(clock.now()).inSeconds + 1)
        : 0;
  }

  bool complete(ProcessInstance p) {
    refresh(p);
    if (p.status != ProcessStatus.ready) return false;
    p.status = ProcessStatus.completed;
    return true;
  }

  bool speedUp(ProcessInstance p) {
    if (p.status != ProcessStatus.waiting) return false;
    p.readyAt = clock.now();
    p.status = ProcessStatus.ready;
    return true;
  }

  void recoverCare(ProcessInstance p) {
    if (p.status == ProcessStatus.needsCare) p.status = ProcessStatus.playing;
  }
}
