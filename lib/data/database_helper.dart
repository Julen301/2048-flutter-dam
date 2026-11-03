import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper{
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal(); //se usa para que toda la app usa la misma instas asi no se crean varias
  static const String nombreBD = 'game2048.db';

  static const int version = 2; //veriosn de la bd
  static const String tablaUsuarios = 'usuarios'; //nombre tabla usuarios
  static const String tablaPartidas = 'partidas'; //nombre tabla partidas
  static const String tablaPartidaGuardada = 'partida_guardada'; //nombre tabla partidas guardadas

  Database? _db; //guardamos la conexion y puede ser nula

Future<Database> get database async{
  return _db ??= await _abrir();

}

Future<Database> _abrir() async {
  final ruta = join (await getDatabasesPath(), nombreBD); //obtener carpeta donde se guarda las bases de datos

  return openDatabase( //se abre la bd o se crea si no existe
    ruta,
    version: version,
    onConfigure: _onConfigure,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
  );
}

Future<void> _onConfigure(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
}

Future<void> _onCreate(Database db, int version) async{
  await _crearEsquemaV1(db); //crea las tablas iniciales
  await _onUpgrade(db, 1, version); //aplica las migraciones necesarias
}
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async{
  if(oldVersion < 2){
    await _migrarAV2(db);
  }
}

Future<void> _crearEsquemaV1(Database db) async{
  final batch = db.batch(); // prepara varias instruciones sql para ejectularas conjutamente

  batch.execute('''
      CREATE TABLE $tablaUsuarios (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario         TEXT    NOT NULL UNIQUE,
        fecha_registro  TEXT    NOT NULL,
        email           TEXT    NOT NULL UNIQUE,
        contrasena_hash TEXT    NOT NULL,
        salt            TEXT    NOT NULL
      )
    ''');
  batch.execute('''
      CREATE TABLE $tablaPartidas (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id        INTEGER NOT NULL,
        puntuacion        INTEGER NOT NULL,
        ficha_maxima      INTEGER NOT NULL,
        movimientos       INTEGER NOT NULL,
        duracion_segundos INTEGER NOT NULL,
        fecha             TEXT    NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES $tablaUsuarios (id)
          ON DELETE CASCADE
      )
    ''');
  batch.execute('''
      CREATE TABLE $tablaPartidaGuardada (
        id                     INTEGER PRIMARY KEY CHECK (id = 1),
        usuario_id             INTEGER NOT NULL,
        tablero                TEXT    NOT NULL,
        puntuacion             INTEGER NOT NULL,
        movimientos            INTEGER NOT NULL,
        segundos_transcurridos INTEGER NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES $tablaUsuarios (id)
          ON DELETE CASCADE
      )
    ''');

    batch.execute(
        'CREATE INDEX idx_partidas_usuario ON $tablaPartidas (usuario_id)');
    batch.execute(
        'CREATE INDEX idx_partidas_puntuacion ON $tablaPartidas (puntuacion DESC)');
    batch.execute(
        'CREATE INDEX idx_partidas_fecha ON $tablaPartidas (fecha DESC)');

    await batch.commit(noResult: true);


}
Future<void> _migrarAV2(Database db) async{
  await db.execute(
      'ALTER TABLE $tablaPartidas '
      'ADD COLUMN tamano_tablero INTEGER NOT NULL DEFAULT 4'
  );
}
Future<void> cerrar() async{
  final db = _db;
  if(db != null && db.isOpen){
    await db.close();
  }
  _db = null; // es null para indicar que no tenemos una conexion abierta
}

}