import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/datos_exception.dart';
import '../data/partida_dao.dart';
import '../data/partida_guardada_dao.dart';
import '../game/juego_2048.dart';
import '../models/partida.dart';
import '../models/partida_guardada.dart';
import '../models/usuario.dart';
import '../services/preferencias_service.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/board_widget.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/controles_direccion.dart';
import '../widgets/score_card.dart';

enum _OpcionSalida { guardar, descartar, cancelar }

enum _OpcionFin { jugarDeNuevo, volverAlInicio }

class JuegoScreen extends StatefulWidget {
  const JuegoScreen({super.key, this.continuar = false});

  /// true: se restaura la partida guardada en la base de datos.
  final bool continuar;

  @override
  State<JuegoScreen> createState() => _JuegoScreenState();
}

class _JuegoScreenState extends State<JuegoScreen> with WidgetsBindingObserver {
  final _partidaDao = PartidaDao();
  final _guardadaDao = PartidaGuardadaDao();

  late PreferenciasService _prefs;
  late Usuario _usuario;

  Juego2048? _juego;
  ResultadoMovimiento _ultimo = ResultadoMovimiento.sinCambios;
  Timer? _cronometro;
  int _segundos = 0;
  int _mejor = 0;
  bool _vibracion = true;
  bool _terminada = false;
  bool _avisado2048 = false;
  bool _mostrarDetalles = false;
  bool _inicializado = false;

  /// Hay algo que perder si se sale: se ha movido al menos una vez.
  bool get _enCurso => _juego != null && !_terminada && _juego!.movimientos > 0;

  // ------------------------------------------------------------ Ciclo de vida

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inicializado) return;
    _inicializado = true;
    final scope = AppScope.of(context);
    _prefs = scope.preferencias;
    _usuario = scope.sesion.usuario!;
    _cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cronometro?.cancel();
    super.dispose();
  }

  /// Guardado automático al pasar a segundo plano.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pararCronometro();
        _guardar();
      case AppLifecycleState.resumed:
        if (_juego != null && !_terminada) _iniciarCronometro();
      case AppLifecycleState.inactive:
        break;
    }
  }

  // ------------------------------------------------------------------ Datos

  Future<void> _cargar() async {
    PartidaGuardada? guardada;
    try {
      _mejor = max(
        await _prefs.leerMejorPuntuacion(),
        await _partidaDao.obtenerMejorPuntuacion(),
      );
      _vibracion = await _prefs.leerVibracion();
      if (widget.continuar) {
        guardada = await _guardadaDao.obtener(_usuario.id!);
      }
    } on DatosException catch (e) {
      _mostrar(e.mensaje);
    }
    if (!mounted) return;

    final g = guardada;
    setState(() {
      _juego = g == null
          ? (Juego2048()..iniciar())
          : Juego2048.desdeEstado(
              tablero: g.tablero,
              puntuacion: g.puntuacion,
              movimientos: g.movimientos,
            );
      _segundos = g?.segundosTranscurridos ?? 0;
      _avisado2048 = _juego!.haGanado;
    });
    _iniciarCronometro();
    if (g != null) _mostrar('Partida recuperada');
  }

  /// Guarda la partida en curso. Devuelve true si se ha guardado.
  Future<bool> _guardar({bool avisar = false}) async {
    final juego = _juego;
    if (juego == null || !_enCurso) return false;
    try {
      await _guardadaDao.guardar(PartidaGuardada(
        usuarioId: _usuario.id!,
        tablero: juego.tablero,
        puntuacion: juego.puntuacion,
        movimientos: juego.movimientos,
        segundosTranscurridos: _segundos,
      ));
      if (avisar) _mostrar('Partida guardada');
      return true;
    } on DatosException catch (e) {
      _mostrar(e.mensaje);
      return false;
    }
  }

  // ----------------------------------------------------------------- Juego

  void _iniciarCronometro() {
    _cronometro?.cancel();
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _segundos++);
    });
  }

  void _pararCronometro() {
    _cronometro?.cancel();
    _cronometro = null;
  }

  void _mover(Direccion direccion) {
    final juego = _juego;
    if (juego == null || _terminada) return;

    final resultado = juego.mover(direccion);
    if (!resultado.movido) return;

    if (_vibracion && resultado.fusiones.isNotEmpty) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _ultimo = resultado;
      _mejor = max(_mejor, juego.puntuacion);
    });

    if (!_avisado2048 && juego.haGanado) {
      _avisado2048 = true;
      _mostrar('¡Has llegado a ${Juego2048.objetivo}! Puedes seguir jugando.');
    }
    if (juego.terminado) _finalizar();
  }

  void _nuevaPartida() {
    setState(() {
      _juego = Juego2048()..iniciar();
      _ultimo = ResultadoMovimiento.sinCambios;
      _segundos = 0;
      _terminada = false;
      _avisado2048 = false;
    });
    _iniciarCronometro();
  }

  Future<void> _reiniciar() async {
    if (_enCurso) {
      final ok = await ConfirmDialog.confirmar(
        context,
        titulo: 'Reiniciar partida',
        mensaje: 'Se perderá el progreso de la partida actual.',
        textoConfirmar: 'Reiniciar',
        destructivo: true,
        icono: Icons.restart_alt,
      );
      if (!ok) return;
    }
    try {
      await _guardadaDao.eliminar();
    } on DatosException catch (e) {
      _mostrar(e.mensaje);
    }
    _nuevaPartida();
  }

  /// Fin de partida: TRANSACCIÓN (insertar en historial + borrar guardada)
  /// y diálogo de resultado.
  Future<void> _finalizar() async {
    final juego = _juego!;
    setState(() => _terminada = true);
    _pararCronometro();

    var record = false;
    try {
      await _partidaDao.finalizarPartida(Partida(
        usuarioId: _usuario.id!,
        puntuacion: juego.puntuacion,
        fichaMaxima: juego.fichaMaxima,
        movimientos: juego.movimientos,
        duracionSegundos: _segundos,
        fecha: DateTime.now(),
      ));
      record = await _prefs.actualizarMejorPuntuacion(juego.puntuacion);
      _mostrar('Partida guardada en el historial');
    } on DatosException catch (e) {
      _mostrar(e.mensaje);
    }
    if (!mounted) return;

    final opcion = await ConfirmDialog.elegir<_OpcionFin>(
      context,
      titulo: record ? '¡Nuevo récord!' : 'Fin de la partida',
      icono: record ? Icons.emoji_events : Icons.flag,
      mensaje: 'Puntuación: ${juego.puntuacion}\n'
          'Ficha máxima: ${juego.fichaMaxima}\n'
          'Movimientos: ${juego.movimientos}\n'
          'Duración: ${formatearDuracion(_segundos)}',
      opciones: const [
        OpcionDialogo(texto: 'Volver al inicio', valor: _OpcionFin.volverAlInicio),
        OpcionDialogo(
          texto: 'Jugar de nuevo',
          valor: _OpcionFin.jugarDeNuevo,
          principal: true,
        ),
      ],
    );
    if (!mounted) return;
    switch (opcion) {
      case _OpcionFin.jugarDeNuevo:
        _nuevaPartida();
      case _OpcionFin.volverAlInicio:
        Navigator.pop(context, true);
      case null:
        break; // se queda viendo el tablero final
    }
  }

  /// Botón "atrás" con partida en curso: guardar y salir, salir sin
  /// guardar o cancelar.
  Future<void> _alIntentarSalir() async {
    final opcion = await ConfirmDialog.elegir<_OpcionSalida>(
      context,
      titulo: '¿Salir de la partida?',
      mensaje: 'Tienes una partida en curso. ¿Qué quieres hacer?',
      icono: Icons.exit_to_app,
      opciones: const [
        OpcionDialogo(texto: 'Cancelar', valor: _OpcionSalida.cancelar),
        OpcionDialogo(
          texto: 'Salir sin guardar',
          valor: _OpcionSalida.descartar,
          destructiva: true,
        ),
        OpcionDialogo(
          texto: 'Guardar y salir',
          valor: _OpcionSalida.guardar,
          principal: true,
        ),
      ],
    );
    if (!mounted) return;

    switch (opcion) {
      case _OpcionSalida.guardar:
        if (!await _guardar(avisar: true)) return;
      case _OpcionSalida.descartar:
        try {
          await _guardadaDao.eliminar();
        } on DatosException catch (e) {
          _mostrar(e.mensaje);
        }
      case _OpcionSalida.cancelar:
      case null:
        return;
    }
    _pararCronometro();
    if (mounted) Navigator.pop(context, true);
  }

  void _mostrar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // -------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_enCurso,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _alIntentarSalir();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('2048'),
          actions: [
            IconButton(
              tooltip: 'Guardar partida',
              onPressed: _enCurso ? () => _guardar(avisar: true) : null,
              icon: const Icon(Icons.save_outlined),
            ),
            IconButton(
              tooltip: 'Reiniciar',
              onPressed: _juego == null ? null : _reiniciar,
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        ),
        body: SafeArea(
          child: _juego == null
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(AppEspacios.m),
                  child: MediaQuery.orientationOf(context) == Orientation.landscape
                      ? _disenoHorizontal()
                      : _disenoVertical(),
                ),
        ),
      ),
    );
  }

  Widget _disenoVertical() {
    return Column(
      children: [
        _marcadores(),
        const SizedBox(height: AppEspacios.s),
        _informacion(),
        _detalles(),
        const SizedBox(height: AppEspacios.m),
        Expanded(child: Center(child: _tablero())),
        const SizedBox(height: AppEspacios.m),
        ControlesDireccion(onMover: _mover),
      ],
    );
  }

  Widget _disenoHorizontal() {
    return Row(
      children: [
        Expanded(child: Center(child: _tablero())),
        const SizedBox(width: AppEspacios.l),
        SizedBox(
          width: 280,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _marcadores(),
                const SizedBox(height: AppEspacios.s),
                _informacion(),
                _detalles(),
                const SizedBox(height: AppEspacios.m),
                ControlesDireccion(onMover: _mover),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tablero() {
    final juego = _juego!;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppTamanos.anchoMaxTablero),
      child: BoardWidget(
        tablero: juego.tablero,
        tamano: juego.tamano,
        onMover: _mover,
        revision: juego.movimientos,
        fusiones: _ultimo.fusiones,
        posicionNueva: _ultimo.posicionNueva,
      ),
    );
  }

  Widget _marcadores() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppEspacios.s,
      runSpacing: AppEspacios.s,
      children: [
        ScoreCard(
          etiqueta: 'Puntos',
          valor: _juego!.puntuacion,
          // Doble toque: mostrar u ocultar los detalles de la partida.
          onDoubleTap: () => setState(() => _mostrarDetalles = !_mostrarDetalles),
        ),
        ScoreCard(etiqueta: 'Mejor', valor: _mejor),
      ],
    );
  }

  Widget _informacion() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppEspacios.s,
      children: [
        Chip(
          avatar: const Icon(Icons.swipe, size: 18),
          label: Text('${_juego!.movimientos} movimientos'),
        ),
        Chip(
          avatar: const Icon(Icons.timer_outlined, size: 18),
          label: Text(formatearDuracion(_segundos)),
        ),
      ],
    );
  }

  Widget _detalles() {
    final juego = _juego!;
    return AnimatedSize(
      duration: AppDuraciones.aparicion,
      child: !_mostrarDetalles
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: AppEspacios.s),
              child: Text(
                'Jugador: ${_usuario.usuario} · '
                'Ficha máxima: ${juego.fichaMaxima} · '
                'Te faltan ${max(0, Juego2048.objetivo - juego.fichaMaxima)} para ${Juego2048.objetivo}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
    );
  }
}
