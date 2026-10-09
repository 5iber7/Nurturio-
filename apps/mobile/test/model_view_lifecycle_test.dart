import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:model_viewer_plus/src/model_viewer_plus_mobile.dart' as mobile;

void main() {
  testWidgets('disposing a model while its asset server starts is safe', (
    tester,
  ) async {
    final pending = Completer<HttpServer>();
    final originalBind = mobile.ModelViewerState.bindProxy;
    mobile.ModelViewerState.bindProxy = () => pending.future;
    addTearDown(() => mobile.ModelViewerState.bindProxy = originalBind);
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          height: 200,
          child: ModelViewer(src: 'assets/models/honey.glb', ar: false),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      pending.complete(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    expect(tester.takeException(), null);
  });
}
