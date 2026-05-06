import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import 'screens/home_shell.dart';

class PanopticonApp extends ConsumerWidget {
  const PanopticonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Touch the bridge so it subscribes to native events at app launch.
    ref.watch(nativeBridgeProvider);

    return MaterialApp(
      title: 'Panopticon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F4068),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F4068),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}
