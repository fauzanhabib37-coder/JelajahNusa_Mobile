import 'package:flutter/material.dart';
import 'app.dart';
import 'core/app_state.dart';
import 'core/local_store.dart';
import 'data/catalog.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<AppState> future;
  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<AppState> _load() async {
    final catalog = await Catalog.load();
    final store = await SharedPrefsStore.open();
    final state = AppState(store, catalog);
    await state.initialize();
    return state;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AppState>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasData) return JelajahApp(state: snapshot.data!);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: nusaTheme(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Aplikasi belum dapat dimuat.',
                          style: Nusa.heading(24),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => setState(() => future = _load()),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    },
  );
}
