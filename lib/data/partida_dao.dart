import 'package:sqflite/sqflite.dart';

import '../models/estadisticas.dart';
import '../models/partida.dart';
import 'database_helper.dart';
import 'datos_exception.dart';

// Maneja el historial, el ranking y las estadisticas de partidas usando consultas parametrizadas
class PartidaDao {
  PartidaDao({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  static const String _tP = DatabaseHelper.tablaPartidas;
  static const String _tU = DatabaseHelper.tablaUsuarios;
  static const String _tG = DatabaseHelper.tablaPartidaGuardada;

  // Consulta base que une partidas con usuarios para obtener el nombre del jugador
  static const String _selectConJugador = '''
    SELECT p.*, u.usuario AS usuario
    FROM $_tP p
    INNER JOIN $_tU u ON u.id = p.usuario_id
  ''';

  // Guarda una partida terminada y reemplaza si ya existia una con el mismo id
  Future<int> insertar(Partida partida) async {
    try {
      final db = await _helper.database;
      return await db.insert(
        _tP,
        partida.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      throw DatosException('No se pudo guardar la partida', e);
    }
  }

  // Ejecuta en una sola transaccion guardar la partida finalizada y borrar la partida en curso
  Future<int> finalizarPartida(Partida partida) async {
    try {
      final db = await _helper.database;
      return await db.transaction<int>((txn) async {
        final id = await txn.insert(_tP, partida.toMap());
        // Si algo falla despues de insertar, la transaccion revierte ambos cambios
        await txn.delete(_tG);
        return id;
      });
    } on DatabaseException catch (e) {
      throw DatosException('No se pudo registrar el final de la partida', e);
    }
  }

  // Devuelve el historial ordenado de mas reciente a mas antiguo aplicando filtros opcionales
  Future<List<Partida>> obtenerHistorial({
    String? jugador,
    int? fichaMinima,
  }) async {
    final condiciones = <String>[];
    final argumentos = <Object?>[];

    final texto = jugador?.trim() ?? '';
    if (texto.isNotEmpty) {
      condiciones.add('u.usuario LIKE ?');
      // Pasa el patron como argumento para evitar inyeccion SQL
      argumentos.add('%$texto%');
    }
    if (fichaMinima != null) {
      condiciones.add('p.ficha_maxima >= ?');
      argumentos.add(fichaMinima);
    }

    // Construye la clausula WHERE solo cuando hay al menos un filtro activo
    final where =
        condiciones.isEmpty ? '' : 'WHERE ${condiciones.join(' AND ')}';

    try {
      final db = await _helper.database;
      final filas = await db.rawQuery(
        '$_selectConJugador $where ORDER BY p.fecha DESC',
        argumentos,
      );
      return filas.map(Partida.fromMap).toList();
    } on DatabaseException catch (e) {
      throw DatosException('No se pudo cargar el historial', e);
    }
  }

  // Busca una partida por su id y devuelve null si no se encuentra
  Future<Partida?> obtenerPorId(int id) async {
    try {
      final db = await _helper.database;
      final filas = await db.rawQuery(
        '$_selectConJugador WHERE p.id = ? LIMIT 1',
        [id],
      );
      return filas.isEmpty ? null : Partida.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DatosException('No se pudo cargar la partida', e);
    }
  }

  // Borra una partida concreta y devuelve cuantas filas se eliminaron
  Future<int> eliminar(int id) async {
    try {
      final db = await _helper.database;
      return await db.delete(_tP, where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      throw DatosException('No se pudo eliminar la partida', e);
    }
  }

  // Borra todas las partidas registradas en el historial
  Future<int> eliminarTodo() async {
    try {
      final db = await _helper.database;
      return await db.delete(_tP);
    } on DatabaseException catch (e) {
      throw DatosException('No se pudo borrar el historial', e);
    }
  }

  // Obtiene las 10 mejores puntuaciones y desempata por fecha mas antigua primero
  Future<List<Partida>> obtenerTop10() async {
    try {
      final db = await _helper.database;
      final filas = await db.rawQuery(
        '$_selectConJugador ORDER BY p.puntuacion DESC, p.fecha ASC LIMIT ?',
        [10],
      );
      return filas.map(Partida.fromMap).toList();
    } on DatabaseException catch (e) {
      throw DatosException('No se pudo cargar el ranking', e);
    }
  }

  // Calcula totales, promedios y maximos generales de todas las partidas
  Future<EstadisticasGlobales> obtenerEstadisticasGlobales() async {
    try {
      final db = await _helper.database;
      final filas = await db.rawQuery('''
        SELECT COUNT(*)               AS partidas,
               MAX(puntuacion)        AS puntuacion_maxima,
               AVG(puntuacion)        AS puntuacion_media,
               MAX(ficha_maxima)      AS ficha_maxima,
               SUM(duracion_segundos) AS tiempo_total
        FROM $_tP
      ''');
      return EstadisticasGlobales.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DatosException('No se pudieron calcular las estadísticas', e);
    }
  }

  // Agrupa las partidas por usuario para obtener su mejor marca y cantidad jugada
  Future<List<EstadisticaJugador>> obtenerEstadisticasPorJugador() async {
    try {
      final db = await _helper.database;
      final filas = await db.rawQuery('''
        SELECT u.usuario         AS usuario,
               MAX(p.puntuacion) AS mejor_puntuacion,
               COUNT(p.id)       AS partidas
        FROM $_tP p
        INNER JOIN $_tU u ON u.id = p.usuario_id
        GROUP BY p.usuario_id
        ORDER BY mejor_puntuacion DESC
      ''');
      return filas.map(EstadisticaJugador.fromMap).toList();
    } on DatabaseException catch (e) {
      throw DatosException('No se pudieron calcular las estadísticas por jugador', e);
    }
  }

  // Devuelve la puntuacion mas alta de un jugador o de todo el sistema si usuarioId es null
  Future<int> obtenerMejorPuntuacion({int? usuarioId}) async {
    try {
      final db = await _helper.database;
      final filas = usuarioId == null
          ? await db.rawQuery('SELECT MAX(puntuacion) FROM $_tP')
          : await db.rawQuery(
              'SELECT MAX(puntuacion) FROM $_tP WHERE usuario_id = ?',
              [usuarioId],
            );
      // Si no hay filas o el valor es null, devuelve 0 por defecto
      return Sqflite.firstIntValue(filas) ?? 0;
    } on DatabaseException catch (e) {
      throw DatosException('No se pudo leer la mejor puntuación', e);
    }
  }
}
