import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/juego_2048.dart';
import '../theme/app_theme.dart';
import 'tile_widget.dart';

/// Dibuja la cuadrícula a partir de la lista de valores y reconoce:
///  - Swipe en 4 direcciones (GestureDetector con onPan*): se acumula el
///    desplazamiento y al soltar se elige el eje dominante. Por debajo de
///    [AppTamanos.umbralSwipe] se ignora.
///  - Flechas del teclado / WASD (Focus + onKeyEvent) como alternativa.
///
/// Es StatefulWidget solo para guardar el desplazamiento acumulado y el
/// FocusNode; el estado del juego vive en la pantalla.
class BoardWidget extends StatefulWidget {
  const BoardWidget({
    super.key,
    required this.tablero,
    required this.tamano,
    required this.onMover,
    this.revision = 0,
    this.fusiones = const {},
    this.posicionNueva,
  });

  final List<int> tablero;
  final int tamano;
  final ValueChanged<Direccion> onMover;

  /// Cambia en cada movimiento para relanzar las animaciones.
  final int revision;
  final Set<int> fusiones;
  final int? posicionNueva;

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  final FocusNode _foco = FocusNode(debugLabel: 'tablero');
  Offset _desplazamiento = Offset.zero;

  static final Map<LogicalKeyboardKey, Direccion> _teclas = {
    LogicalKeyboardKey.arrowUp: Direccion.arriba,
    LogicalKeyboardKey.arrowDown: Direccion.abajo,
    LogicalKeyboardKey.arrowLeft: Direccion.izquierda,
    LogicalKeyboardKey.arrowRight: Direccion.derecha,
    LogicalKeyboardKey.keyW: Direccion.arriba,
    LogicalKeyboardKey.keyS: Direccion.abajo,
    LogicalKeyboardKey.keyA: Direccion.izquierda,
    LogicalKeyboardKey.keyD: Direccion.derecha,
  };

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails _) => _desplazamiento = Offset.zero;

  void _onPanUpdate(DragUpdateDetails d) => _desplazamiento += d.delta;

  void _onPanEnd(DragEndDetails _) {
    final dx = _desplazamiento.dx;
    final dy = _desplazamiento.dy;
    _desplazamiento = Offset.zero;

    // Umbral mínimo: un toque o un roce corto no mueve las fichas.
    if (dx.abs() < AppTamanos.umbralSwipe && dy.abs() < AppTamanos.umbralSwipe) {
      return;
    }
    // Dirección dominante: el eje con mayor desplazamiento.
    final direccion = dx.abs() > dy.abs()
        ? (dx > 0 ? Direccion.derecha : Direccion.izquierda)
        : (dy > 0 ? Direccion.abajo : Direccion.arriba);
    widget.onMover(direccion);
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent evento) {
    if (evento is! KeyDownEvent && evento is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final direccion = _teclas[evento.logicalKey];
    if (direccion == null) return KeyEventResult.ignored;
    widget.onMover(direccion);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final fichas = FichasTheme.of(context);
    final n = widget.tamano;
    const sep = AppTamanos.separacionCeldas;

    return Focus(
      focusNode: _foco,
      autofocus: true,
      onKeyEvent: _onKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _foco.requestFocus,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ladoCelda = (constraints.maxWidth - sep * (n + 1)) / n;
              return Container(
                padding: const EdgeInsets.all(sep),
                // tablero tipo "consola": fondo oscuro, borde con el color de
                // marca y un resplandor suave alrededor
                // (el borde va en foregroundDecoration: se pinta encima y no
                // resta espacio a las celdas, que se calculan con ladoCelda)
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTamanos.radioTablero),
                  border: Border.all(
                    color: AppColores.degradadoMarca.first.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                decoration: BoxDecoration(
                  color: fichas.fondoTablero,
                  borderRadius: BorderRadius.circular(AppTamanos.radioTablero),
                  boxShadow: [
                    BoxShadow(
                      color: AppColores.degradadoMarca.first.withValues(alpha: 0.25),
                      blurRadius: 28,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var f = 0; f < n; f++)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (var c = 0; c < n; c++) _celda(f * n + c, ladoCelda),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _celda(int indice, double lado) {
    final esNueva = indice == widget.posicionNueva;
    final esFusion = widget.fusiones.contains(indice);
    final animada = esNueva || esFusion;
    return TileWidget(
      // La clave cambia con la revisión solo en las celdas animadas,
      // para que TweenAnimationBuilder vuelva a ejecutarse.
      key: ValueKey('celda-$indice-${animada ? widget.revision : 0}'),
      valor: widget.tablero[indice],
      lado: lado,
      esNueva: esNueva,
      esFusion: esFusion,
    );
  }
}
