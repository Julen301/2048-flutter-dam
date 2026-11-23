import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/game/juego_2048.dart';

List<int> fila(List<int> primera) => [...primera, ...List.filled(12, 0)];

/// Primera fila del tablero ignorando la ficha aleatoria que aparece tras mover.
List<int> primeraFila(Juego2048 juego, ResultadoMovimiento r) {
  final t = [...juego.tablero];
  if (r.posicionNueva != null) t[r.posicionNueva!] = 0;
  return t.sublist(0, 4);
}

void main() {
  group('Juego2048', () {
    test('iniciar coloca dos fichas', () {
      final juego = Juego2048(random: Random(1))..iniciar();
      expect(juego.tablero.where((v) => v != 0).length, 2);
      expect(juego.puntuacion, 0);
    });

    test('fusiona hacia la izquierda y suma puntos', () {
      final juego = Juego2048.desdeEstado(
        tablero: fila([2, 2, 4, 0]),
        puntuacion: 0,
        movimientos: 0,
        random: Random(1),
      );
      final r = juego.mover(Direccion.izquierda);
      expect(r.movido, isTrue);
      expect(primeraFila(juego, r), [4, 4, 0, 0]);
      expect(juego.puntuacion, 4);
      expect(juego.movimientos, 1);
    });

    test('cada ficha solo se fusiona una vez: [2,2,2,2] -> [4,4,0,0]', () {
      final juego = Juego2048.desdeEstado(
        tablero: fila([2, 2, 2, 2]),
        puntuacion: 0,
        movimientos: 0,
        random: Random(1),
      );
      final r = juego.mover(Direccion.izquierda);
      expect(primeraFila(juego, r), [4, 4, 0, 0]);
      expect(juego.puntuacion, 8);
    });

    test('hacia la derecha', () {
      final juego = Juego2048.desdeEstado(
        tablero: fila([4, 4, 8, 0]),
        puntuacion: 0,
        movimientos: 0,
        random: Random(1),
      );
      final r = juego.mover(Direccion.derecha);
      expect(primeraFila(juego, r), [0, 0, 8, 8]);
    });

    test('un movimiento sin cambios no cuenta', () {
      final juego = Juego2048.desdeEstado(
        tablero: fila([2, 4, 8, 16]),
        puntuacion: 0,
        movimientos: 0,
      );
      final r = juego.mover(Direccion.izquierda);
      expect(r.movido, isFalse);
      expect(juego.movimientos, 0);
    });

    test('detecta el fin de partida', () {
      final juego = Juego2048.desdeEstado(
        tablero: const [
          2, 4, 2, 4, //
          4, 2, 4, 2,
          2, 4, 2, 4,
          4, 2, 4, 2,
        ],
        puntuacion: 0,
        movimientos: 0,
      );
      expect(juego.terminado, isTrue);
    });
  });
}
