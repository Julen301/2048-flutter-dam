import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/paleta_fichas.dart';

// Servicio para guardar y leer cosas pequeñas con SharedPreferences
// (tema, paleta, mejor puntuacion, sesion...).
// La idea es que solo esta clase toque SharedPreferences, asi si hay que
// cambiar algo solo se cambia aqui.
class PreferenciasService {
  PreferenciasService(this._prefs);

  // Se llama en el main() antes del runApp, porque getInstance() es async
  // y no se puede esperar dentro de un constructor.
  static Future<PreferenciasService> crear() async {
    return PreferenciasService(await SharedPreferences.getInstance());
  }

  final SharedPreferences _prefs;

  // nombres de las claves. Los pongo como constantes para no escribir
  // el string a mano cada vez y equivocarme con alguna letra
  static const String claveModoTema = 'modo_tema';
  static const String clavePaletaFichas = 'paleta_fichas';
  static const String claveUltimoJugador = 'ultimo_jugador';
  static const String claveMejorPuntuacion = 'mejor_puntuacion';
  static const String claveVibracion = 'vibracion';
  static const String claveSesionUsuarioId = 'sesion_usuario_id';

  /// tema

  // guardo el nombre del enum ('light', 'dark' o 'system') como texto
  Future<void> guardarModoTema(ThemeMode modo) async {
    await _prefs.setString(claveModoTema, modo.name);
  }

  // Busca el ThemeMode que tenga ese nombre. Si no hay nada guardado
  // (primera vez que se abre la app) devuelve el del sistema.
  Future<ThemeMode> leerModoTema() async {
    final valor = _prefs.getString(claveModoTema);
    return ThemeMode.values.firstWhere(
          (m) => m.name == valor,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> guardarPaletaFichas(PaletaFichas paleta) async {
    await _prefs.setString(clavePaletaFichas, paleta.name);
  }

  // igual que el tema, si no encuentra nada usa la clasica
  Future<PaletaFichas> leerPaletaFichas() async {
    final valor = _prefs.getString(clavePaletaFichas);
    return PaletaFichas.values.firstWhere(
          (p) => p.name == valor,
      orElse: () => PaletaFichas.clasica,
    );
  }

  /// ampliaciones

  Future<void> guardarUltimoJugador(String nombre) async {
    await _prefs.setString(claveUltimoJugador, nombre);
  }

  // puede ser null si nunca ha jugado nadie
  Future<String?> leerUltimoJugador() async => _prefs.getString(claveUltimoJugador);

  // Solo guarda la puntuacion si es mayor que la que ya habia.
  // Devuelve true si es un nuevo record.
  Future<bool> actualizarMejorPuntuacion(int puntuacion) async {
    final actual = await leerMejorPuntuacion();
    if (puntuacion > actual) {
      await _prefs.setInt(claveMejorPuntuacion, puntuacion);
      return true;
    }
    return false;
  }

  // si no hay record todavia devuelve 0
  Future<int> leerMejorPuntuacion() async => _prefs.getInt(claveMejorPuntuacion) ?? 0;

  // se usa cuando se borra todo el historial desde ajustes
  Future<void> reiniciarMejorPuntuacion() async {
    await _prefs.remove(claveMejorPuntuacion);
  }

  Future<void> guardarVibracion(bool activa) async {
    await _prefs.setBool(claveVibracion, activa);
  }

  // por defecto la vibracion esta activada
  Future<bool> leerVibracion() async => _prefs.getBool(claveVibracion) ?? true;

  /// sesion
  // guardamos solo el id del usuario para que no tenga que volver a
  // hacer login cada vez que abre la app

  Future<void> guardarSesion(int usuarioId) async {
    await _prefs.setInt(claveSesionUsuarioId, usuarioId);
  }

  // null = no hay nadie logueado
  Future<int?> leerSesion() async => _prefs.getInt(claveSesionUsuarioId);

  Future<void> borrarSesion() async {
    await _prefs.remove(claveSesionUsuarioId);
  }
}
