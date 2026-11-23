import 'package:sqflite/sqflite.dart';

import '../models/partida_guardada.dart';
import 'database_helper.dart';
import 'datos_exception.dart';

// Administra la partida en curso que se guarda como registro unico
class PartidaGuardadaDao {
  PartidaGuardadaDao({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;
  static const String _tabla = DatabaseHelper.tablaPartidaGuardada;

  // Guarda la partida actual o sobrescribe la que hubiera guardada previamente
  Future<void> guardar(PartidaGuardada partida) async {
    try {
      final db = await _helper.database;
      await db.insert(
        _tabla,
        partida.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      throw DatosException('No se pudo guardar la partida en curso', e);
    }
  }

  // Recupera la partida guardada si pertenece al usuario indicado, o null si no existe
  Future<PartidaGuardada?> obtener(int usuarioId) async {
    try {
      final db = await _helper.database;
      final filas = await db.query(
        _tabla,
        where: 'id = ? AND usuario_id = ?',
        whereArgs: [PartidaGuardada.idUnico, usuarioId],
        limit: 1,
      );
      return filas.isEmpty ? null : PartidaGuardada.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DatosException('No se pudo recuperar la partida en curso', e);
    }
  }

  // Indica si el usuario tiene actualmente una partida guardada
  Future<bool> existe(int usuarioId) async => (await obtener(usuarioId)) != null;

  // Elimina la partida guardada para liberar el espacio de partida en curso
  Future<void> eliminar() async {
    try {
      final db = await _helper.database;
      await db.delete(
        _tabla,
        where: 'id = ?',
        whereArgs: [PartidaGuardada.idUnico],
      );
    } on DatabaseException catch (e) {
      throw DatosException('No se pudo borrar la partida en curso', e);
    }
  }
}
