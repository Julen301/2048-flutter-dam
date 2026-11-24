/// Resultado de la consulta de agregación global (COUNT, MAX, AVG, SUM).
class EstadisticasGlobales {
  const EstadisticasGlobales({
    required this.partidasJugadas,
    required this.puntuacionMaxima,
    required this.puntuacionMedia,
    required this.fichaMaxima,
    required this.tiempoTotalSegundos,
  });

  final int partidasJugadas;
  final int puntuacionMaxima;
  final double puntuacionMedia;
  final int fichaMaxima;
  final int tiempoTotalSegundos;

  /// Con la tabla vacía, MAX/AVG/SUM devuelven NULL: se tratan como 0.
  factory EstadisticasGlobales.fromMap(Map<String, Object?> map) {
    return EstadisticasGlobales(
      partidasJugadas: (map['partidas'] as int?) ?? 0,
      puntuacionMaxima: (map['puntuacion_maxima'] as int?) ?? 0,
      puntuacionMedia: ((map['puntuacion_media'] as num?) ?? 0).toDouble(),
      fichaMaxima: (map['ficha_maxima'] as int?) ?? 0,
      tiempoTotalSegundos: (map['tiempo_total'] as int?) ?? 0,
    );
  }
}

/// Fila de la consulta GROUP BY por jugador.
class EstadisticaJugador {
  const EstadisticaJugador({
    required this.usuario,
    required this.mejorPuntuacion,
    required this.partidas,
  });

  final String usuario;
  final int mejorPuntuacion;
  final int partidas;

  factory EstadisticaJugador.fromMap(Map<String, Object?> map) {
    return EstadisticaJugador(
      usuario: map['usuario'] as String,
      mejorPuntuacion: map['mejor_puntuacion'] as int,
      partidas: map['partidas'] as int,
    );
  }
}
