import 'package:flutter/material.dart';

import 'screens/detalle_screen.dart';
import 'screens/home_shell.dart';
import 'screens/juego_screen.dart';
import 'screens/login_screen.dart';
import 'screens/registro_screen.dart';

/// Todas las rutas de la app estan aqui.
/// Solo en este archivo se crean MaterialPageRoute, desde las pantallas
/// se navega con Navigator.pushNamed(context, AppRoutes.xxx).
abstract final class AppRoutes {
  static const String login = '/login';
  static const String registro = '/registro';

  /// La pantalla con la barra de abajo (Inicio, Historial, Ranking, Ajustes).
  static const String home = '/';

  /// Recibe un bool como argumento: true = continuar la partida guardada.
  static const String juego = '/juego';

  /// Recibe un int como argumento: el id de la partida.
  static const String detalle = '/detalle';

  // lo usa app.dart (onGenerateInitialRoutes) para la primera pantalla,
  // que sera login o home segun si hay sesion guardada
  static List<Route<dynamic>> rutasIniciales(String nombre) {
    return [generar(RouteSettings(name: nombre))];
  }

  /// Se llama cada vez que se hace un pushNamed (es el onGenerateRoute).
  /// Segun el nombre devuelve una pantalla u otra.
  static Route<dynamic> generar(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _ruta(settings, const LoginScreen());
      case registro:
        return _ruta(settings, const RegistroScreen());
      case home:
        return _ruta(settings, const HomeShell());
      case juego:
        // si no nos pasan nada, partida nueva
        final continuar = settings.arguments as bool? ?? false;
        return _ruta(settings, JuegoScreen(continuar: continuar));
      case detalle:
        final id = settings.arguments;
        // compruebo que el argumento sea un int antes de usarlo
        if (id is int) {
          return _ruta(settings, DetalleScreen(partidaId: id));
        }
        return _noEncontrada(settings);
      default:
        return _noEncontrada(settings);
    }
  }

  // para no repetir el MaterialPageRoute en cada case
  static MaterialPageRoute<T> _ruta<T>(RouteSettings settings, Widget pantalla) {
    return MaterialPageRoute<T>(settings: settings, builder: (_) => pantalla);
  }

  // pantalla de error por si se pide una ruta que no existe o el argumento
  // esta mal, asi la app no peta
  static Route<dynamic> _noEncontrada(RouteSettings settings) {
    return _ruta(
      settings,
      Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Ruta no encontrada: ${settings.name}')),
      ),
    );
  }
}
