import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const ink = Color(0xFF25382D),
    cream = Color(0xFFFFF8EB),
    olive = Color(0xFF456A43),
    amber = Color(0xFFF5B942);
ThemeData nurturioTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final background = dark ? const Color(0xFF151D18) : cream;
  final foreground = dark ? const Color(0xFFE9EEDF) : ink;
  final card = dark ? const Color(0xFF222E25) : Colors.white;
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: olive,
      brightness: brightness,
      surface: background,
      primary: dark ? const Color(0xFFB0D29A) : olive,
      surfaceContainer: card,
      onSurface: foreground,
    ),
    fontFamily: 'Nunito',
    textTheme: TextTheme(
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: foreground,
        height: 1.12,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
      bodyLarge: TextStyle(fontSize: 17, color: foreground, height: 1.45),
      bodyMedium: TextStyle(fontSize: 15, color: foreground, height: 1.45),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: foreground,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardThemeData(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

Color accent(BuildContext context) => Theme.of(context).colorScheme.primary;

class SoftCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsets padding;
  const SoftCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(22),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? (color == null
                ? Theme.of(context).colorScheme.surfaceContainer
                : Color.alphaBlend(
                    color!.withValues(alpha: .12),
                    Theme.of(context).colorScheme.surfaceContainer,
                  ))
          : color ?? Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .08),
      ),
    ),
    child: child,
  );
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1040),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: children,
      ),
    ),
  );
}

class VillageBackButton extends StatelessWidget {
  const VillageBackButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Back',
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/village');
      }
    },
  );
}
