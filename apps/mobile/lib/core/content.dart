import 'dart:convert';

import 'package:flutter/services.dart';

class QuestItem {
  final String id, label, target;
  QuestItem(Map<String, dynamic> j)
    : id = j['id'],
      label = j['label'],
      target = j['target'];
}

class Quest {
  final String? videoUrl, videoTranscript;
  final String id,
      topicId,
      title,
      template,
      instruction,
      intro,
      fact,
      explorer,
      safety,
      realDuration;
  final int order, waitSeconds, gardenSeconds, xp, coins, correct;
  final List<QuestItem> items;
  final List<String> prerequisites, answers, sourceIds;
  final String question;
  Quest(Map<String, dynamic> j)
    : videoUrl = j['videoUrl'],
      videoTranscript = j['videoTranscript'],
      id = j['id'],
      topicId = j['topicId'],
      title = j['title'],
      template = j['template'],
      instruction = j['instruction'],
      intro = j['intro'],
      fact = j['fact'],
      explorer = j['explorer'],
      safety = j['safety'],
      realDuration = j['realDuration']['label'],
      order = j['order'],
      waitSeconds = j['gameDurationSeconds'],
      gardenSeconds = j['gardenPaceSeconds'],
      xp = j['reward']['xp'],
      coins = j['reward']['coins'],
      items = (j['items'] as List).map((e) => QuestItem(e)).toList(),
      prerequisites = List<String>.from(j['prerequisites']),
      answers = List<String>.from(j['check']['answers']),
      correct = j['check']['correct'],
      question = j['check']['question'],
      sourceIds = List<String>.from(j['sourceIds']);
}

class Topic {
  final String id, name, subject, subtitle, icon, goal;
  final int color;
  final List<Quest> quests;
  final List<List<String>> glossary;
  Topic(Map<String, dynamic> j)
    : id = j['id'],
      name = j['name'],
      subject = j['subject'],
      subtitle = j['subtitle'],
      icon = j['icon'],
      goal = j['goal'],
      color = int.parse('FF${(j['color'] as String).substring(1)}', radix: 16),
      quests = (j['quests'] as List).map((e) => Quest(e)).toList(),
      glossary = (j['glossary'] as List)
          .map((e) => List<String>.from(e))
          .toList();
}

class ContentLibrary {
  final List<Topic> topics;
  final List<Map<String, dynamic>> plants, sources;
  ContentLibrary(this.topics, this.plants, this.sources);
  Topic topic(String id) => topics.firstWhere((t) => t.id == id);
  Quest quest(String id) =>
      topics.expand((t) => t.quests).firstWhere((q) => q.id == id);
  static Future<ContentLibrary> load() async {
    Future<dynamic> read(String name) async =>
        jsonDecode(await rootBundle.loadString('assets/content/$name.json'));
    final manifest = await read('manifest');
    final topics = await Future.wait(
      (manifest['topics'] as List).map((id) async => Topic(await read(id))),
    );
    return ContentLibrary(
      topics,
      List<Map<String, dynamic>>.from(await read('plants')),
      List<Map<String, dynamic>>.from(await read('sources')),
    );
  }
}
