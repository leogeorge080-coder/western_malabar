// lib/main.dart
import 'dart:async'; // ✅ for runZonedGuarded
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind; // ✅ Needed
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:western_malabar/env.dart';
import 'package:western_malabar/theme.dart';
import 'package:western_malabar/screens/customer/app_shell.dart';

Future<void> main() async {
  // Catch framework errors and forward to zone handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(
        details.exception, details.stack ?? StackTrace.current);
  };

  // Catch platform/engine errors (Flutter 3.13+)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('❌ Uncaught platform error: $error\n$stack');
    return true; // handled
  };

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: '.env');

    // Initialize Stripe
    Stripe.publishableKey = Env.stripePublishableKey;
    await Stripe.instance.applySettings();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        anonKey: Env.supabaseAnonKey,
        debug: kDebugMode,
      );

      final supabase = Supabase.instance.client;

      if (supabase.auth.currentUser == null) {
        final res = await supabase.auth.signInAnonymously();
        debugPrint('Anonymous login: ${res.user?.id}');
      } else {
        debugPrint('Existing user: ${supabase.auth.currentUser?.id}');
      }

      debugPrint(
          'CURRENT AUTH USER: ${Supabase.instance.client.auth.currentUser?.id}');
    } catch (e, st) {
      debugPrint('❌ Supabase init/auth failed: $e\n$st');
    }

    runApp(
      const ProviderScope(
        child: WMApp(),
      ),
    );
  }, (error, stack) {
    // Last-resort safety net for uncaught async errors
    debugPrint('❌ Uncaught async error: $error\n$stack');
  });
}

class WMApp extends StatelessWidget {
  const WMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Western Malabar',
      debugShowCheckedModeBanner: false,
      theme: wmLightTheme,
      themeMode: ThemeMode.light,
      scrollBehavior: const _WMScrollBehavior(), // ✅ custom scroll
      home: const _InitGate(),
    );
  }
}

class _InitGate extends StatefulWidget {
  const _InitGate();

  @override
  State<_InitGate> createState() => _InitGateState();
}

class _InitGateState extends State<_InitGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _warmUp();
  }

  Future<void> _warmUp() async {
    // ✅ Make the type explicit to satisfy the analyzer.
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF7E6),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF5A2D82)),
        ),
      );
    }
    return const AppShell();
  }
}

class _WMScrollBehavior extends MaterialScrollBehavior {
  const _WMScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Set<PointerDeviceKind> get dragDevices => <PointerDeviceKind>{
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}
