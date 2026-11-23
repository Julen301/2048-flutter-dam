class Partida {
  const Partida({
    this.id,
    required this.usuarioId,
    this.usuario,
    required this.puntuacion,
    required this.fichaMaxima,
    required this.movimientos,
    required this.duracionSegundos,
    required this.fecha,
    this.tamanoTablero = 4,
  });

  final int? id;
  final int usuarioId;

  /// Nombre del jugador. Solo viene relleno en las consultas con JOIN.
  final String? usuario;
  final int puntuacion;
  final int fichaMaxima;
  final int movimientos;
  final int duracionSegundos;
  final DateTime fecha;

  /// Añadido en la versión 2 de la base de datos.
  final int tamanoTablero;

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'usuario_id': usuarioId,
      'puntuacion': puntuacion,
      'ficha_maxima': fichaMaxima,
      'movimientos': movimientos,
      'duracion_segundos': duracionSegundos,
      'fecha': fecha.toIso8601String(),
      'tamano_tablero': tamanoTablero,
    };
  }

  factory Partida.fromMap(Map<String, Object?> map) {
    return Partida(
      id: map['id'] as int?,
      usuarioId: map['usuario_id'] as int,
      usuario: map['usuario'] as String?,
      puntuacion: map['puntuacion'] as int,
      fichaMaxima: map['ficha_maxima'] as int,
      movimientos: map['movimientos'] as int,
      duracionSegundos: map['duracion_segundos'] as int,
      fecha: DateTime.parse(map['fecha'] as String),
      tamanoTablero: (map['tamano_tablero'] as int?) ?? 4,
    );
  }
}
