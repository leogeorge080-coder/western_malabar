// lib/main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';
import 'screens/customer/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase once (awaited before UI builds).
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      // If/when you add auth flows, you can enable PKCE:
      // authFlowType: AuthFlowType.pkce,
    );
  } catch (e, st) {
    // Keep running even if init throws; log for debugging.
    // (Your UI can still start and show an error state if needed.)
    // ignore: avoid_print
    print('❌ Supabase init failed: $e\n$st');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Western Malabar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5A2D82)),
        scaffoldBackgroundColor: Colors.white,
      ),
      // Gate ensures we don’t flash uninitialized UI while the first frame
      // settles (especially helpful on hot restart).
      home: const _InitGate(),
    );
  }
}

/// Simple gate to show a tiny branded loader before rendering AppShell.
/// We already awaited Supabase.initialize() in main(), so this is just
/// a micro splash to feel smooth on first paint / hot restart.
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
    // Short delay to avoid layout jank; tweak or remove if you like.
    await Future.delayed(const Duration(milliseconds: 200));
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
