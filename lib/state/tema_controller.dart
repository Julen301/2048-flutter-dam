import 'package:flutter/material.dart';

import '../models/paleta_fichas.dart';
import '../services/preferencias_service.dart';

/// Estado del tema. Al cambiar notifica a MaterialApp, que se reconstruye
/// al instante sin reiniciar la app, y persiste el valor en preferencias.
class TemaController extends ChangeNotifier {
  TemaController(
    this._preferencias, {
    required ThemeMode modoInicial,
    required PaletaFichas paletaInicial,
  })  : _modo = modoInicial,
        _paleta = paletaInicial;

  final PreferenciasService _preferencias;

  ThemeMode _modo;
  PaletaFichas _paleta;

  ThemeMode get modo => _modo;
  PaletaFichas get paleta => _paleta;

  Future<void> cambiarModo(ThemeMode modo) async {
    if (modo == _modo) return;
    _modo = modo;
    notifyListeners(); // primero la UI, luego el disco
    await _preferencias.guardarModoTema(modo);
  }

  Future<void> cambiarPaleta(PaletaFichas paleta) async {
    if (paleta == _paleta) return;
    _paleta = paleta;
    notifyListeners();
    await _preferencias.guardarPaletaFichas(paleta);
  }
}
