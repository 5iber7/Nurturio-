import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/app_controller.dart';
import 'world_art.dart';

/// Bundled glTF meshes rendered with model-viewer's physically based renderer.
/// Headless tests and unsupported desktop platforms use the original artwork.
class WorldView extends ConsumerStatefulWidget {
  final String world;
  final double height;
  final bool interactive;
  final bool animate;
  final Widget? fallback;
  const WorldView({
    super.key,
    required this.world,
    this.height = 250,
    this.interactive = true,
    this.animate = true,
    this.fallback,
  });
  @override
  ConsumerState<WorldView> createState() => _WorldViewState();
}

class _WorldViewState extends ConsumerState<WorldView>
    with WidgetsBindingObserver {
  static int nextId = 0;
  final id = 'nurturio-scene-${nextId++}';
  bool active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted) setState(() => active = state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(controllerProvider);
    final supported =
        kIsWeb ||
        ((defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS) &&
            WebViewPlatform.instance != null);
    if (!supported || c.settings['scene3d'] == false) {
      if (widget.fallback != null) return widget.fallback!;
      return SizedBox(
        height: widget.height,
        child: CustomPaint(
          painter: WorldPainter(
            widget.world == 'village' ? 'garden' : widget.world,
            0,
          ),
          size: Size(double.infinity, widget.height),
        ),
      );
    }
    final motion = c.settings['motion'] == true && active && widget.animate;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final asset = 'assets/models/${widget.world}.glb';
    final label = widget.world == 'village'
        ? 'Your 3D village with a farmer, bees, chickens and growing beds'
        : '3D ${widget.world.replaceAll('plant-', '')} scene';
    return Semantics(
      label: label,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: widget.height,
          child: ModelViewer(
            key: ValueKey(
              '${widget.world}-$motion-${widget.interactive}-$dark',
            ),
            id: id,
            src: kIsWeb ? 'assets/$asset' : asset,
            alt: label,
            ar: false,
            autoPlay: motion,
            autoRotate: false,
            cameraControls: widget.interactive,
            disablePan: true,
            disableZoom: !widget.interactive,
            touchAction: TouchAction.panY,
            interactionPrompt: InteractionPrompt.none,
            cameraOrbit: '30deg 65deg 105%',
            minCameraOrbit: 'auto 25deg 65%',
            maxCameraOrbit: 'auto 85deg 180%',
            fieldOfView: '36deg',
            environmentImage: 'neutral',
            exposure: 1.05,
            shadowIntensity: .8,
            shadowSoftness: .9,
            loading: Loading.eager,
            backgroundColor: dark
                ? const Color(0xFF20382C)
                : const Color(0xFFE9EEDF),
            debugLogging: false,
            relatedCss:
                '#$id { --poster-color: transparent; ${widget.interactive ? '' : 'pointer-events:none;'} }',
          ),
        ),
      ),
    );
  }
}
