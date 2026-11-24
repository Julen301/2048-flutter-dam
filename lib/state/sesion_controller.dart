import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../services/preferencias_service.dart';

/// Usuario con la sesión iniciada. Persiste su id en preferencias para
/// no tener que hacer login cada vez que se abre la app.
class SesionController extends ChangeNotifier {
  SesionController(this._preferencias, this._auth);

  final PreferenciasService _preferencias;
  final AuthService _auth;

  Usuario? _usuario;

  Usuario? get usuario => _usuario;
  bool get haySesion => _usuario != null;

  /// Se llama en main() antes de runApp.
  Future<void> restaurar() async {
    final id = await _preferencias.leerSesion();
    if (id == null) return;
    try {
      _usuario = await _auth.buscarPorId(id);
    } catch (_) {
      _usuario = null;
    }
    if (_usuario == null) await _preferencias.borrarSesion();
  }

  Future<void> iniciarSesion(String identificador, String contrasena) async {
    final usuario = await _auth.iniciarSesion(identificador, contrasena);
    await _establecer(usuario);
  }

  Future<void> registrar({
    required String usuario,
    required String email,
    required String contrasena,
  }) async {
    final nuevo = await _auth.registrar(
      usuario: usuario,
      email: email,
      contrasena: contrasena,
    );
    await _establecer(nuevo);
  }

  Future<void> cerrarSesion() async {
    _usuario = null;
    await _preferencias.borrarSesion();
    notifyListeners();
  }

  Future<void> _establecer(Usuario usuario) async {
    _usuario = usuario;
    await _preferencias.guardarSesion(usuario.id!);
    await _preferencias.guardarUltimoJugador(usuario.usuario);
    notifyListeners();
  }
}
