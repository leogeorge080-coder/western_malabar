// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:western_malabar/app/env.dart';
import 'package:western_malabar/app/app_shell.dart';
import 'package:western_malabar/app/auth_session_guard.dart';
import 'package:western_malabar/shared/theme/theme.dart';
import 'package:western_malabar/features/splash/splash_screen.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('❌ Uncaught platform error: $error\n$stack');
    return true;
  };

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: '.env');

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
    } catch (e, st) {
      debugPrint('❌ Supabase init failed: $e\n$st');
    }

    runApp(
      const ProviderScope(
        child: WMApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('❌ Uncaught async error: $error\n$stack');
  });
}

class WMApp extends StatelessWidget {
  const WMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthSessionGuard(
      child: MaterialApp(
        title: 'Malabar Hub',
        debugShowCheckedModeBanner: false,
        theme: wmLightTheme,
        themeMode: ThemeMode.light,
        scrollBehavior: const _WMScrollBehavior(),
        home: const _StartupGate(),
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _ready = false;
  bool _didKickAuth = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final splashMin = Future<void>.delayed(const Duration(milliseconds: 1200));

    _kickAnonymousAuthInBackground();

    await splashMin;

    if (!mounted) return;
    setState(() => _ready = true);
  }

  void _kickAnonymousAuthInBackground() {
    if (_didKickAuth) return;
    _didKickAuth = true;

    unawaited(_ensureAnonymousSession());
  }

  Future<void> _ensureAnonymousSession() async {
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) {
        final res = await supabase.auth.signInAnonymously();
        debugPrint('Anonymous login: ${res.user?.id}');
      } else {
        debugPrint('Existing user: ${supabase.auth.currentUser?.id}');
      }
    } catch (e, st) {
      debugPrint('❌ Background anonymous auth failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SplashScreen();
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
