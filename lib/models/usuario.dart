/// Usuario registrado en la aplicación (tabla `usuarios`).
class Usuario {
  const Usuario({
    this.id,
    required this.usuario,
    required this.fechaRegistro,
    required this.email,
    required this.contrasenaHash,
    required this.salt,
  });

  final int? id;
  final String usuario;
  final DateTime fechaRegistro;
  final String email;

  /// Nunca se guarda la contraseña en claro: solo su hash SHA-256 con salt.
  final String contrasenaHash;
  final String salt;

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'usuario': usuario,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'email': email,
      'contrasena_hash': contrasenaHash,
      'salt': salt,
    };
  }

  factory Usuario.fromMap(Map<String, Object?> map) {
    return Usuario(
      id: map['id'] as int?,
      usuario: map['usuario'] as String,
      fechaRegistro: DateTime.parse(map['fecha_registro'] as String),
      email: map['email'] as String,
      contrasenaHash: map['contrasena_hash'] as String,
      salt: map['salt'] as String,
    );
  }

  Usuario copyWith({int? id}) {
    return Usuario(
      id: id ?? this.id,
      usuario: usuario,
      fechaRegistro: fechaRegistro,
      email: email,
      contrasenaHash: contrasenaHash,
      salt: salt,
    );
  }
}
