import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'features/auth_screen.dart';
import 'features/shell.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class JelajahApp extends StatelessWidget {
  final AppState state;
  final Widget Function(Widget)? wrapper;
  const JelajahApp({super.key, required this.state, this.wrapper});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) => MaterialApp(
      key: ValueKey(state.isSignedIn ? state.email : 'guest'),
      title: 'JelajahNusa',
      debugShowCheckedModeBanner: false,
      theme: nusaTheme(),
      builder: (context, child) {
        final content = ColoredBox(
          color: const Color(0xFFE4EAE0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: child!,
            ),
          ),
        );
        return wrapper?.call(content) ?? content;
      },
      home: !state.ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : state.loadError != null
          ? _Recovery(state)
          : AppShell(state: state),
    ),
  );
}

class _Recovery extends StatelessWidget {
  final AppState state;
  const _Recovery(this.state);
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: PageBody(
          children: [
            const Brand(),
            const SizedBox(height: 24),
            Text('Data belum dapat dibaca', style: Nusa.heading()),
            const SizedBox(height: 12),
            Text(state.loadError!),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.initialize,
              child: const Text('Coba muat ulang'),
            ),
            TextButton(
              onPressed: () async {
                if (await confirm(
                  context,
                  title: 'Hapus data lokal yang tidak terbaca?',
                  message:
                      'Semua akun dan progres pada instalasi ini akan dihapus. Tindakan ini tidak dapat dibatalkan.',
                  action: 'Hapus data',
                )) {
                  if (context.mounted) {
                    await perform(context, state.clearUnreadableStorage);
                  }
                }
              },
              child: const Text('Reset penyimpanan perangkat'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Helper to push AuthScreen from anywhere in the app.
Future<void> goToAuth(BuildContext context, AppState state) => Navigator.push<void>(
  context,
  MaterialPageRoute<void>(builder: (_) => AuthScreen(state: state)),
);
