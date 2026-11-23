import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../data/datos_exception.dart';
import '../data/usuario_dao.dart';
import '../models/usuario.dart';

/// Error de autenticación con mensaje apto para el usuario.
class AuthException implements Exception {
  const AuthException(this.mensaje);
  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Registro e inicio de sesión. La contraseña se guarda como
/// SHA-256(salt + contraseña), con un salt aleatorio distinto por usuario.
class AuthService {
  AuthService(this._usuarioDao);

  final UsuarioDao _usuarioDao;

  static final RegExp _regexEmail = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');
  static const int longitudMinimaContrasena = 6;
  static const int _iteracionesHash = 1000;

  // ------------------------------------------------------- Validaciones

  static String? validarUsuario(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Introduce un nombre de usuario';
    if (v.length < 3) return 'Mínimo 3 caracteres';
    return null;
  }

  static String? validarEmail(String? valor) {
    final v = valor?.trim() ?? '';
    if (v.isEmpty) return 'Introduce un email';
    if (!v.contains('@') || !_regexEmail.hasMatch(v)) {
      return 'El email no tiene un formato válido';
    }
    return null;
  }

  static String? validarContrasena(String? valor) {
    final v = valor ?? '';
    if (v.length < longitudMinimaContrasena) {
      return 'Mínimo $longitudMinimaContrasena caracteres';
    }
    return null;
  }

  // ------------------------------------------------------- Operaciones

  Future<Usuario> registrar({
    required String usuario,
    required String email,
    required String contrasena,
  }) async {
    final salt = _generarSalt();
    final nuevo = Usuario(
      usuario: usuario.trim(),
      fechaRegistro: DateTime.now(),
      email: email.trim().toLowerCase(),
      contrasenaHash: hashContrasena(contrasena, salt),
      salt: salt,
    );
    try {
      return await _usuarioDao.insertar(nuevo);
    } on DatosException catch (e) {
      throw AuthException(e.mensaje);
    }
  }

  /// [identificador] puede ser el nombre de usuario o el email.
  Future<Usuario> iniciarSesion(String identificador, String contrasena) async {
    final Usuario? usuario;
    try {
      usuario = await _usuarioDao.buscarPorUsuarioOEmail(identificador.trim());
    } on DatosException catch (e) {
      throw AuthException(e.mensaje);
    }
    // Mismo mensaje en ambos casos para no revelar qué usuarios existen.
    if (usuario == null ||
        hashContrasena(contrasena, usuario.salt) != usuario.contrasenaHash) {
      throw const AuthException('Usuario o contraseña incorrectos');
    }
    return usuario;
  }

  Future<Usuario?> buscarPorId(int id) => _usuarioDao.buscarPorId(id);

  // ------------------------------------------------------- Criptografía

  static String hashContrasena(String contrasena, String salt) {
    List<int> bytes = utf8.encode('$salt$contrasena');
    for (var i = 0; i < _iteracionesHash; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64Encode(bytes);
  }

  static String _generarSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
}
