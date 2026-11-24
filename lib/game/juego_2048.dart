import 'dart:math';

/// Direcciones de movimiento del tablero.
enum Direccion { arriba, abajo, izquierda, derecha }

/// Información de un movimiento, útil para animar el tablero.
class ResultadoMovimiento {
  const ResultadoMovimiento({
    required this.movido,
    this.puntosGanados = 0,
    this.fusiones = const {},
    this.posicionNueva,
  });

  static const ResultadoMovimiento sinCambios = ResultadoMovimiento(movido: false);

  final bool movido;
  final int puntosGanados;

  /// Índices del tablero donde se ha producido una fusión.
  final Set<int> fusiones;

  /// Índice donde ha aparecido la ficha nueva.
  final int? posicionNueva;
}

/// Lógica pura del 2048, sin dependencias de Flutter (testeable con dart test).
///
/// El tablero es una lista de `tamano * tamano` enteros, fila a fila;
/// 0 representa una celda vacía.
class Juego2048 {
  Juego2048({this.tamano = 4, Random? random})
      : _random = random ?? Random(),
        _tablero = List<int>.filled(tamano * tamano, 0);

  /// Restaura una partida guardada.
  Juego2048.desdeEstado({
    required List<int> tablero,
    required this.puntuacion,
    required this.movimientos,
    this.tamano = 4,
    Random? random,
  })  : assert(tablero.length == tamano * tamano),
        _random = random ?? Random(),
        _tablero = List<int>.of(tablero);

  static const int objetivo = 2048;
  static const double _probabilidadCuatro = 0.1;

  final int tamano;
  final Random _random;
  final List<int> _tablero;

  int puntuacion = 0;
  int movimientos = 0;

  List<int> get tablero => List<int>.unmodifiable(_tablero);

  int get fichaMaxima => _tablero.reduce(max);

  bool get haGanado => fichaMaxima >= objetivo;

  /// Hay movimiento posible si queda una celda vacía o dos vecinas iguales.
  bool get puedeMover {
    if (_tablero.contains(0)) return true;
    for (var f = 0; f < tamano; f++) {
      for (var c = 0; c < tamano; c++) {
        final v = _tablero[f * tamano + c];
        if (c + 1 < tamano && v == _tablero[f * tamano + c + 1]) return true;
        if (f + 1 < tamano && v == _tablero[(f + 1) * tamano + c]) return true;
      }
    }
    return false;
  }

  bool get terminado => !puedeMover;

  /// Empieza una partida nueva con dos fichas.
  void iniciar() {
    _tablero.fillRange(0, _tablero.length, 0);
    puntuacion = 0;
    movimientos = 0;
    _anadirFichaAleatoria();
    _anadirFichaAleatoria();
  }

  ResultadoMovimiento mover(Direccion direccion) {
    var movido = false;
    var puntos = 0;
    final fusiones = <int>{};

    for (final linea in _lineas(direccion)) {
      final valores = [for (final i in linea) _tablero[i]];
      final resultado = _comprimirLinea(valores);

      for (var k = 0; k < linea.length; k++) {
        if (_tablero[linea[k]] != resultado.valores[k]) movido = true;
        _tablero[linea[k]] = resultado.valores[k];
      }
      puntos += resultado.puntos;
      fusiones.addAll(resultado.posicionesFusion.map((k) => linea[k]));
    }

    if (!movido) return ResultadoMovimiento.sinCambios;

    puntuacion += puntos;
    movimientos++;
    final nueva = _anadirFichaAleatoria();
    return ResultadoMovimiento(
      movido: true,
      puntosGanados: puntos,
      fusiones: fusiones,
      posicionNueva: nueva,
    );
  }

  /// Índices de cada línea ordenados en el sentido del movimiento:
  /// el primer índice es la celda hacia la que se desplazan las fichas.
  List<List<int>> _lineas(Direccion direccion) {
    final n = tamano;
    return List.generate(n, (a) {
      final linea = List.generate(n, (b) {
        return switch (direccion) {
          Direccion.izquierda => a * n + b,
          Direccion.derecha => a * n + (n - 1 - b),
          Direccion.arriba => b * n + a,
          Direccion.abajo => (n - 1 - b) * n + a,
        };
      });
      return linea;
    });
  }

  /// Desplaza y fusiona una línea hacia su inicio. Cada ficha solo
  /// puede fusionarse una vez por movimiento ([2,2,2,2] -> [4,4,0,0]).
  static ({List<int> valores, int puntos, List<int> posicionesFusion})
      _comprimirLinea(List<int> linea) {
    final fichas = linea.where((v) => v != 0).toList();
    final salida = <int>[];
    final posicionesFusion = <int>[];
    var puntos = 0;

    var i = 0;
    while (i < fichas.length) {
      if (i + 1 < fichas.length && fichas[i] == fichas[i + 1]) {
        final suma = fichas[i] * 2;
        posicionesFusion.add(salida.length);
        salida.add(suma);
        puntos += suma;
        i += 2;
      } else {
        salida.add(fichas[i]);
        i++;
      }
    }
    while (salida.length < linea.length) {
      salida.add(0);
    }
    return (valores: salida, puntos: puntos, posicionesFusion: posicionesFusion);
  }

  /// Coloca un 2 (90 %) o un 4 (10 %) en una celda vacía al azar.
  int? _anadirFichaAleatoria() {
    final vacias = [
      for (var i = 0; i < _tablero.length; i++)
        if (_tablero[i] == 0) i,
    ];
    if (vacias.isEmpty) return null;
    final posicion = vacias[_random.nextInt(vacias.length)];
    _tablero[posicion] = _random.nextDouble() < _probabilidadCuatro ? 4 : 2;
    return posicion;
  }
}
