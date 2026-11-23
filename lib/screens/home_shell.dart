import 'package:flutter/material.dart';

import 'ajustes_screen.dart';
import 'historial_screen.dart';
import 'inicio_screen.dart';
import 'ranking_screen.dart';

/// Pantalla principal con la NavigationBar de abajo (Material 3).
///
/// Elegi NavigationBar porque son 4 secciones del mismo nivel que se usan
/// mucho, y asi siempre estan a un toque.
/// Cada vez que cambias de pestaña la pantalla se crea de nuevo, asi vuelve
/// a leer la base de datos y salen las partidas nuevas o borradas.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0; // pestaña seleccionada (0 = inicio)

  void _ir(int indice) => setState(() => _indice = indice);

  @override
  Widget build(BuildContext context) {
    // segun el indice enseño una pantalla u otra.
    // A inicio le paso _ir para que sus botones puedan cambiar de pestaña
    final pantalla = switch (_indice) {
      0 => InicioScreen(onNavegar: _ir),
      1 => const HistorialScreen(),
      2 => const RankingScreen(),
      _ => const AjustesScreen(),
    };

    // PopScope controla el boton atras del movil:
    // en inicio (canPop true) sale de la app normal, y en otra pestaña en
    // vez de salir vuelve a inicio
    return PopScope(
      canPop: _indice == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _ir(0);
      },
      child: Scaffold(
        body: pantalla,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _indice,
          onDestinationSelected: _ir,
          // el orden tiene que coincidir con el switch de arriba y con
          // PestanasInicio (inicio_screen.dart)
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Historial',
            ),
            NavigationDestination(
              icon: Icon(Icons.leaderboard_outlined),
              selectedIcon: Icon(Icons.leaderboard),
              label: 'Ranking',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
