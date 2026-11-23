import 'package:sqflite/sqflite.dart';

import '../models/usuario.dart';
import 'database_helper.dart';
import 'datos_exception.dart';

// Gestiona las consultas y escrituras en la tabla de usuarios
class UsuarioDao {
  // Permite inyectar un helper de prueba o usar la instancia compartida por defecto
  UsuarioDao({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;
  static const String _tabla = DatabaseHelper.tablaUsuarios;

  // Registra un usuario nuevo y devuelve una copia con el id asignado por la base de datos
  Future<Usuario> insertar(Usuario usuario) async {
    try {
      final db = await _helper.database;
      // Aborta si ya existe un registro con el mismo usuario o email unico
      final id = await db.insert(
        _tabla,
        usuario.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return usuario.copyWith(id: id);
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw DatosException('Ese nombre de usuario o email ya está registrado', e);
      }
      throw DatosException('No se pudo registrar el usuario', e);
    }
  }

  // Busca un usuario por nombre o email ignorando mayusculas y minusculas para el login
  Future<Usuario?> buscarPorUsuarioOEmail(String identificador) async {
    try {
      final db = await _helper.database;
      final filas = await db.query(
        _tabla,
        where: 'usuario = ? COLLATE NOCASE OR email = ? COLLATE NOCASE',
        whereArgs: [identificador, identificador],
        limit: 1,
      );
      // Devuelve null si no hay coincidencias o convierte la primera fila en Usuario
      return filas.isEmpty ? null : Usuario.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DatosException('Error al buscar el usuario', e);
    }
  }

  // Recupera un usuario concreto a partir de su id interno
  Future<Usuario?> buscarPorId(int id) async {
    try {
      final db = await _helper.database;
      final filas = await db.query(
        _tabla,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return filas.isEmpty ? null : Usuario.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DatosException('Error al cargar el usuario', e);
    }
  }
}
