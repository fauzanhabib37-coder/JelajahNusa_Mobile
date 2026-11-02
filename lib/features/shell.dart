import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../ui/theme.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'collection_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  final AppState state;
  const AppShell({super.key, required this.state});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selected = 0;
  String query = '';
  void explore([String value = '']) => setState(() {
    query = value;
    selected = 1;
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: IndexedStack(
        index: selected,
        children: [
          HomeScreen(
            state: widget.state,
            onExplore: explore,
            onProfile: () => setState(() => selected = 3),
          ),
          ExploreScreen(
            key: ValueKey(query),
            state: widget.state,
            initialQuery: query,
          ),
          CollectionScreen(
            state: widget.state,
            onExplore: () => explore(),
          ),
          ProfileScreen(state: widget.state),
        ],
      ),
    ),
    bottomNavigationBar: MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: NavigationBar(
        height: 76,
        selectedIndex: selected,
        onDestinationSelected: (i) => setState(() => selected = i),
        backgroundColor: Colors.white,
        indicatorColor: Nusa.soft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: 'NusaSans',
            fontSize: 10,
            color: s.contains(WidgetState.selected) ? Nusa.green : Nusa.muted,
          ),
        ),
        destinations: const [
          NavigationDestination(
            key: Key('nav_beranda'),
            icon: Icon(Icons.home_outlined, size: 23),
            selectedIcon: Icon(
              Icons.home_outlined,
              color: Nusa.green,
              size: 23,
            ),
            label: 'Beranda',
          ),
          NavigationDestination(
            key: Key('nav_jelajah'),
            icon: Icon(Icons.explore_outlined, size: 23),
            selectedIcon: Icon(
              Icons.explore_outlined,
              color: Nusa.green,
              size: 23,
            ),
            label: 'Jelajah',
          ),
          NavigationDestination(
            key: Key('nav_koleksi'),
            icon: Icon(Icons.bookmark_border, size: 23),
            selectedIcon: Icon(
              Icons.bookmark_border,
              color: Nusa.green,
              size: 23,
            ),
            label: 'Koleksi',
          ),
          NavigationDestination(
            key: Key('nav_profil'),
            icon: Icon(Icons.person_outline, size: 23),
            selectedIcon: Icon(
              Icons.person_outline,
              color: Nusa.green,
              size: 23,
            ),
            label: 'Profil',
          ),
        ],
      ),
    ),
  );
}
