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
        home: const _AppBootstrap(),
      ),
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kickAnonymousAuthInBackground();
    });
  }

  Future<void> _kickAnonymousAuthInBackground() async {
    try {
      final supabase = Supabase.instance.client;
      if (supabase.auth.currentUser == null) {
        await supabase.auth.signInAnonymously();
      }
    } catch (e, st) {
      debugPrint('❌ Background anonymous auth failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
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
