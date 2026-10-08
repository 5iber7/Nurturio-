import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_controller.dart';
import 'services.dart';

enum ConsentState { localOnly, pending, verified, revoked }

class ConsentService {
  // No simulated verification can enable restricted services in production.
  ConsentState get state => ConsentState.localOnly;
  bool get minorCloudAccess => false;
}

class ScanResult {
  final String name, description, status, confidence;
  final List<String> warnings, limitations, relatedQuests, retakeTips;
  ScanResult({
    required this.name,
    required this.description,
    required this.status,
    required this.confidence,
    required this.warnings,
    required this.limitations,
    required this.relatedQuests,
    required this.retakeTips,
  });
  factory ScanResult.fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] != 1 ||
        ![
          'identified',
          'uncertain',
          'unsupported',
          'refused',
        ].contains(j['status'])) {
      throw const FormatException('Unsupported scan response');
    }
    final identity = Map<String, dynamic>.from(j['identification']),
        safety = Map<String, dynamic>.from(j['safety']);
    if (safety['edibility'] != 'unknown' ||
        safety['petSafety'] != 'unknown' ||
        !['unknown', 'careful', 'unsafe'].contains(safety['verdict'])) {
      throw const FormatException('Unsafe response');
    }
    final name = identity['commonName'] as String,
        description = j['description'] as String;
    if (name.length > 100 || description.length > 1500) {
      throw const FormatException('Oversized response');
    }
    final related = List<String>.from(j['relatedQuestIds']);
    if (related.any(
      (id) => !RegExp(r'^(honey|olive|chicken|garden)-[1-8]$').hasMatch(id),
    )) {
      throw const FormatException('Unknown quest');
    }
    return ScanResult(
      name: name,
      description: description,
      status: j['status'],
      confidence: identity['confidenceLabel'],
      warnings: List<String>.from(safety['warnings']),
      limitations: List<String>.from(identity['limitations']),
      relatedQuests: related,
      retakeTips: List<String>.from(j['retakeTips']),
    );
  }
}

class AIService {
  static const approved = bool.fromEnvironment('AI_DEPLOYMENT_APPROVED');
  static const mockRequested = bool.fromEnvironment('AI_MOCK');
  bool get mock => kDebugMode && mockRequested;
  bool get available => mock || (approved && CloudService.configured);
  Future<ScanResult> identify(Uint8List image, AppController c) async {
    if (mock) {
      return ScanResult(
        name: 'Development fixture',
        description: 'This sample is not an analysis of your photo.',
        status: 'uncertain',
        confidence: 'uncertain',
        warnings: [
          'Never eat or handle an object based on an app identification.',
        ],
        limitations: ['Mock response; image was not analyzed.'],
        relatedQuests: [],
        retakeTips: [],
      );
    }
    if (!available || c.settings['age'] != 'adult') {
      throw StateError('Identification unavailable');
    }
    final response = await CloudService().client.functions.invoke(
      'scan-identify',
      body: {
        'profileId': c.profileId,
        'reading': c.settings['reading'],
        'image': base64Encode(image),
      },
    );
    if (response.status != 200) throw StateError('Identification unavailable');
    return ScanResult.fromJson(Map<String, dynamic>.from(response.data));
  }
}
