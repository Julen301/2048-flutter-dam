import 'package:flutter/material.dart';

import '../data/datos_exception.dart';
import '../data/partida_dao.dart';
import '../data/partida_guardada_dao.dart';
import '../models/partida_guardada.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/async_data_view.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/score_card.dart';
import '../widgets/titulo_juego.dart';

/// Numero de cada pestaña en la NavigationBar del HomeShell.
/// Los uso para que los botones de inicio salten a esa pestaña.
abstract final class PestanasInicio {
  static const int historial = 1;
  static const int ranking = 2;
  static const int ajustes = 3;
}

// clase solo para juntar los datos que carga la pantalla y devolverlos
// en un unico Future
class _DatosInicio {
  const _DatosInicio({
    required this.mejorGlobal,
    required this.mejorPropia,
    required this.guardada,
  });

  final int mejorGlobal; // record de todos los jugadores
  final int mejorPropia; // record del usuario logueado
  final PartidaGuardada? guardada; // null si no tiene partida a medias
}

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key, this.onNavegar});

  /// Funcion que nos pasa HomeShell para cambiar de pestaña
  /// (historial, ranking o ajustes).
  final ValueChanged<int>? onNavegar;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final _partidaDao = PartidaDao();
  final _guardadaDao = PartidaGuardadaDao();
  Future<_DatosInicio>? _future;

  // Cargo los datos aqui y no en initState porque _cargar usa
  // AppScope.of(context), y en initState todavia no se puede usar el context
  // para eso. El ??= hace que solo se cargue la primera vez.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _cargar();
  }

  Future<_DatosInicio> _cargar() async {
    final scope = AppScope.of(context);
    // aqui siempre hay usuario porque a esta pantalla solo se llega con login
    final usuarioId = scope.sesion.usuario!.id!;
    // la mejor puntuacion la miro en preferencias (B.3) y en la base de
    // datos, y me quedo con la mas alta de las dos
    final mejorPrefs = await scope.preferencias.leerMejorPuntuacion();
    final mejorBD = await _partidaDao.obtenerMejorPuntuacion();
    return _DatosInicio(
      mejorGlobal: mejorPrefs > mejorBD ? mejorPrefs : mejorBD,
      mejorPropia: await _partidaDao.obtenerMejorPuntuacion(usuarioId: usuarioId),
      guardada: await _guardadaDao.obtener(usuarioId),
    );
  }

  // al cambiar el future con setState, el AsyncDataView vuelve a cargar
  void _recargar() => setState(() => _future = _cargar());

  /// Abre la pantalla de juego.
  /// continuar = true -> sigue la partida guardada
  /// continuar = false -> partida nueva
  Future<void> _jugar(_DatosInicio datos, {required bool continuar}) async {
    // si va a empezar una nueva pero tiene una guardada, primero le avisamos
    // porque la guardada se va a perder
    if (!continuar && datos.guardada != null) {
      final ok = await ConfirmDialog.confirmar(
        context,
        titulo: 'Nueva partida',
        mensaje: 'Tienes una partida guardada. Si empiezas otra, se descartará.',
        textoConfirmar: 'Empezar nueva',
        destructivo: true,
      );
      if (!ok) return;
      try {
        await _guardadaDao.eliminar();
      } on DatosException catch (e) {
        // mounted: comprobar que la pantalla sigue abierta despues del await
        // antes de usar el context
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.mensaje)));
        }
        return;
      }
    }
    if (!mounted) return;
    // el bool se pasa como argumento de la ruta (mirar routes.dart)
    await Navigator.pushNamed(context, AppRoutes.juego, arguments: continuar);
    // al volver del juego recargo, puede que haya nuevo record o partida guardada
    if (mounted) _recargar();
  }

  Future<void> _cerrarSesion() async {
    final ok = await ConfirmDialog.confirmar(
      context,
      titulo: 'Cerrar sesión',
      mensaje: '¿Seguro que quieres salir?',
      textoConfirmar: 'Salir',
    );
    if (!ok || !mounted) return;
    await AppScope.of(context).sesion.cerrarSesion();
    if (!mounted) return;
    // vamos al login y borramos todas las pantallas de antes, asi con el
    // boton atras no se puede volver a entrar sin login
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AppScope.of(context).sesion.usuario;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      // AsyncDataView se encarga del "cargando" y de los errores,
      // y cuando hay datos llama al builder
      body: AsyncDataView<_DatosInicio>(
        future: _future!,
        onReintentar: _recargar,
        builder: (context, datos) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppEspacios.l),
            // limito el ancho para que en horizontal o tablet no se estire tanto
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: AppTamanos.anchoMaxFormulario),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TituloJuego(),
                  const SizedBox(height: AppEspacios.m),
                  Text(
                    'Hola, ${usuario?.usuario ?? 'jugador'}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppEspacios.l),
                  // Wrap por si la pantalla es estrecha y no caben en una fila
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppEspacios.s,
                    runSpacing: AppEspacios.s,
                    children: [
                      ScoreCard(etiqueta: 'Mejor', valor: datos.mejorGlobal),
                      ScoreCard(etiqueta: 'Tu mejor', valor: datos.mejorPropia),
                    ],
                  ),
                  const SizedBox(height: AppEspacios.xl),
                  // con partida guardada: boton grande de continuar y otro
                  // de nueva partida. Sin guardada: solo el de nueva partida
                  if (datos.guardada != null) ...[
                    FilledButton.icon(
                      onPressed: () => _jugar(datos, continuar: true),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        'Continuar partida (${datos.guardada!.puntuacion} pts · '
                        '${formatearDuracion(datos.guardada!.segundosTranscurridos)})',
                      ),
                    ),
                    const SizedBox(height: AppEspacios.s),
                    OutlinedButton.icon(
                      onPressed: () => _jugar(datos, continuar: false),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva partida'),
                    ),
                  ] else
                    FilledButton.icon(
                      onPressed: () => _jugar(datos, continuar: false),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva partida'),
                    ),
                  const SizedBox(height: AppEspacios.l),
                  // accesos directos a las otras pestañas: tres tarjetas en fila
                  Row(
                    children: [
                      _BotonSeccion(
                        icono: Icons.history,
                        texto: 'Historial',
                        onPressed: () => widget.onNavegar?.call(PestanasInicio.historial),
                      ),
                      const SizedBox(width: AppEspacios.s),
                      _BotonSeccion(
                        icono: Icons.leaderboard_outlined,
                        texto: 'Ranking',
                        onPressed: () => widget.onNavegar?.call(PestanasInicio.ranking),
                      ),
                      const SizedBox(width: AppEspacios.s),
                      _BotonSeccion(
                        icono: Icons.settings_outlined,
                        texto: 'Ajustes',
                        onPressed: () => widget.onNavegar?.call(PestanasInicio.ajustes),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// tarjeta cuadrada con icono y texto para ir a otra seccion. Lo saco a un
// widget aparte porque se repite 3 veces igual. Ya viene envuelta en
// Expanded para que las tres midan lo mismo dentro del Row.
class _BotonSeccion extends StatelessWidget {
  const _BotonSeccion({
    required this.icono,
    required this.texto,
    required this.onPressed,
  });

  final IconData icono;
  final String texto;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    return Expanded(
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias, // para que el efecto del toque respete las esquinas
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppEspacios.m,
              horizontal: AppEspacios.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, color: esquema.primary),
                const SizedBox(height: AppEspacios.s),
                Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: tema.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
