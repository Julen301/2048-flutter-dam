import 'package:flutter/material.dart';

import '../data/datos_exception.dart';
import '../data/partida_dao.dart';
import '../models/paleta_fichas.dart';
import '../routes.dart';
import '../state/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/tile_widget.dart';

/// Pantalla de ajustes: tema, paleta de fichas, vibracion, borrar historial
/// y cerrar sesion.
class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  // valores que salen en la vista previa de las fichas
  static const List<int> _muestra = [2, 8, 64, 512, 2048];

  final _dao = PartidaDao();

  // es null mientras se lee de preferencias. Mientras tanto el switch
  // se deja desactivado
  bool? _vibracion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // solo la primera vez (cuando todavia es null)
    if (_vibracion == null) {
      AppScope.of(context).preferencias.leerVibracion().then((v) {
        if (mounted) setState(() => _vibracion = v);
      });
    }
  }

  // funcion para no repetir lo del SnackBar. Oculta el anterior si habia
  // uno para que no se pongan en cola
  void _mostrar(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _borrarHistorial() async {
    final ok = await ConfirmDialog.confirmar(
      context,
      titulo: 'Borrar todo el historial',
      mensaje: 'Se eliminarán todas las partidas terminadas de todos los '
          'jugadores. Esta acción no se puede deshacer.',
      textoConfirmar: 'Borrar todo',
      destructivo: true,
      icono: Icons.delete_forever_outlined,
    );
    if (!ok || !mounted) return;
    // lo saco antes del await para no usar el context despues
    final preferencias = AppScope.of(context).preferencias;
    try {
      final borradas = await _dao.eliminarTodo();
      // si no hay partidas tampoco tiene sentido que quede el record guardado
      await preferencias.reiniciarMejorPuntuacion();
      _mostrar('Historial borrado ($borradas partidas)');
    } on DatosException catch (e) {
      _mostrar(e.mensaje);
    }
  }

  // igual que en la pantalla de inicio
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
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final tema = scope.tema; // TemaController (modo y paleta)
    final usuario = scope.sesion.usuario;
    final estilos = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      // ListenableBuilder escucha al TemaController, asi cuando cambias el
      // modo o la paleta la seleccion se actualiza enseguida
      body: ListenableBuilder(
        listenable: tema,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(vertical: AppEspacios.s),
          children: [
            const _Seccion('Apariencia'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppEspacios.m),
              // los 3 botones juntos de claro / oscuro / sistema
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_outlined),
                    label: Text('Claro'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_outlined),
                    label: Text('Oscuro'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.settings_suggest_outlined),
                    label: Text('Sistema'),
                  ),
                ],
                // SegmentedButton trabaja con un Set, por eso las llaves
                // y el .first
                selected: {tema.modo},
                onSelectionChanged: (seleccion) => tema.cambiarModo(seleccion.first),
              ),
            ),
            const _Seccion('Color de las fichas'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppEspacios.m),
              child: Wrap(
                spacing: AppEspacios.s,
                runSpacing: AppEspacios.s,
                children: [
                  // un chip por cada valor del enum PaletaFichas
                  for (final paleta in PaletaFichas.values)
                    ChoiceChip(
                      label: Text(paleta.etiqueta),
                      avatar: _MuestraPaleta(paleta),
                      showCheckmark: false,
                      selected: tema.paleta == paleta,
                      onSelected: (_) => tema.cambiarPaleta(paleta),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppEspacios.m),
            // vista previa de como quedan las fichas con el tema elegido
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppEspacios.s,
              children: [
                for (final v in _muestra)
                  TileWidget(valor: v, lado: AppTamanos.fichaMiniatura),
              ],
            ),
            const _Seccion('Juego'),
            SwitchListTile(
              secondary: const Icon(Icons.vibration),
              title: const Text('Vibración al fusionar fichas'),
              value: _vibracion ?? true,
              // onChanged null = switch desactivado (todavia no se ha leido el valor)
              onChanged: _vibracion == null
                  ? null
                  : (v) {
                      setState(() => _vibracion = v);
                      scope.preferencias.guardarVibracion(v);
                    },
            ),
            const _Seccion('Datos'),
            ListTile(
              leading: Icon(Icons.delete_forever_outlined,
                  color: estilos.colorScheme.error),
              title: Text('Borrar todo el historial',
                  style: TextStyle(color: estilos.colorScheme.error)),
              subtitle: const Text('Pide confirmación antes de borrar'),
              onTap: _borrarHistorial,
            ),
            const _Seccion('Cuenta'),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(usuario?.usuario ?? '-'),
              subtitle: Text(usuario?.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: _cerrarSesion,
            ),
          ],
        ),
      ),
    );
  }
}

// titulo de cada seccion de ajustes (Apariencia, Juego, Datos...)
class _Seccion extends StatelessWidget {
  const _Seccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppEspacios.m, AppEspacios.l, AppEspacios.m, AppEspacios.s),
      child: Text(
        texto,
        style: estilos.textTheme.titleSmall
            ?.copyWith(color: estilos.colorScheme.primary),
      ),
    );
  }
}

/// Circulito con varios colores de la paleta para que se vea como es
/// antes de elegirla.
class _MuestraPaleta extends StatelessWidget {
  const _MuestraPaleta(this.paleta);

  final PaletaFichas paleta;

  @override
  Widget build(BuildContext context) {
    final colores = AppTheme.coloresPaleta(paleta);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // SweepGradient hace el degradado dando la vuelta al circulo.
        // Repito el primer color al final para que no se note el corte
        gradient: SweepGradient(colors: [colores[2], colores[5], colores[10], colores[2]]),
      ),
    );
  }
}
