import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/theme.dart';
import 'ui/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure window for macOS
  if (Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1400, 900),
      minimumSize: Size(1100, 700),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: true,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    const ProviderScope(
      child: CartoMixApp(),
    ),
  );
}

class CartoMixApp extends StatelessWidget {
  const CartoMixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CartoMix',
      debugShowCheckedModeBanner: false,
      theme: CartoMixTheme.dark,
      home: const MainScreen(),
    );
  }
}
