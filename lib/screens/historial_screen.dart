import 'dart:async';

import 'package:flutter/material.dart';

import '../data/datos_exception.dart';
import '../data/partida_dao.dart';
import '../models/partida.dart';
import '../routes.dart';
import '../theme/app_theme.dart';
import '../widgets/async_data_view.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/partida_list_item.dart';

enum _AccionPartida { verDetalle, eliminar }

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  static const List<int> _opcionesFicha = [128, 256, 512, 1024, 2048];
  static const Duration _esperaFiltro = Duration(milliseconds: 350);

  final _dao = PartidaDao();
  final _jugadorCtrl = TextEditingController();
  Timer? _debounce;
  int? _fichaMinima;
  late Future<List<Partida>> _future;

  bool get _hayFiltros => _jugadorCtrl.text.trim().isNotEmpty || _fichaMinima != null;

  @override
  void initState() {
    super.initState();
    _future = _consultar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _jugadorCtrl.dispose();
    super.dispose();
  }

  /// Los filtros se pasan al DAO, que hace la consulta parametrizada.
  Future<List<Partida>> _consultar() {
    return _dao.obtenerHistorial(
      jugador: _jugadorCtrl.text,
      fichaMinima: _fichaMinima,
    );
  }

  // llaves y no flecha: setState no puede devolver un Future
  void _recargar() {
    setState(() {
      _future = _consultar();
    });
  }

  Future<void> _refrescar() async {
    _recargar();
    try {
      await _future;
    } catch (_) {
      // El error ya lo muestra AsyncDataView.
    }
  }

  void _alEscribir(String _) {
    _debounce?.cancel();
    _debounce = Timer(_esperaFiltro, _recargar);
  }

  // --------------------------------------------------------- Navegación

  /// Se pasa SOLO el id; el detalle consulta la BD. Si devuelve true es
  /// que se ha eliminado la partida y hay que refrescar la lista.
  Future<void> _abrirDetalle(Partida partida) async {
    // Sin parámetro de tipo: onGenerateRoute crea MaterialPageRoute<dynamic>.
    final eliminada = await Navigator.pushNamed(
      context,
      AppRoutes.detalle,
      arguments: partida.id,
    );
    if (!mounted || eliminada != true) return;
    _recargar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La partida se ha eliminado')),
    );
  }

  // ----------------------------------------------------------- Borrado

  /// Borra y ofrece "Deshacer", que vuelve a insertar el mismo registro.
  Future<void> _eliminarConDeshacer(Partida partida) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _dao.eliminar(partida.id!);
    } on DatosException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
      _recargar();
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Partida de ${partida.puntuacion} pts eliminada'),
        action: SnackBarAction(
          label: 'Deshacer',
          onPressed: () async {
            try {
              await _dao.insertar(partida);
              if (mounted) _recargar();
            } on DatosException catch (e) {
              messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
            }
          },
        ),
      ));
  }

  Future<void> _mostrarMenu(Partida partida, List<Partida> lista) async {
    final accion = await showModalBottomSheet<_AccionPartida>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Ver detalle'),
              onTap: () => Navigator.pop(context, _AccionPartida.verDetalle),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: const Text('Eliminar'),
              onTap: () => Navigator.pop(context, _AccionPartida.eliminar),
            ),
          ],
        ),
      ),
    );
    if (!mounted || accion == null) return;

    switch (accion) {
      case _AccionPartida.verDetalle:
        await _abrirDetalle(partida);
      case _AccionPartida.eliminar:
        final ok = await ConfirmDialog.confirmar(
          context,
          titulo: 'Eliminar partida',
          mensaje: '¿Eliminar la partida de ${partida.puntuacion} puntos?',
          textoConfirmar: 'Eliminar',
          destructivo: true,
        );
        if (!ok || !mounted) return;
        setState(() => lista.remove(partida));
        await _eliminarConDeshacer(partida);
    }
  }

  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: Column(
        children: [
          _filtros(),
          Expanded(
            child: AsyncDataView<List<Partida>>(
              future: _future,
              onReintentar: _recargar,
              builder: (context, partidas) => RefreshIndicator(
                onRefresh: _refrescar,
                child: partidas.isEmpty ? _vacio() : _lista(partidas),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppEspacios.m, AppEspacios.s, AppEspacios.m, AppEspacios.s),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _jugadorCtrl,
              onChanged: _alEscribir,
              onSubmitted: (_) => _recargar(),
              decoration: InputDecoration(
                isDense: true,
                labelText: 'Jugador',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _jugadorCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _jugadorCtrl.clear();
                          _recargar();
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppEspacios.s),
          SizedBox(
            width: 140,
            child: DropdownButtonFormField<int?>(
              value: _fichaMinima,
              isDense: true,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Ficha ≥',
              ),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
                for (final v in _opcionesFicha)
                  DropdownMenuItem<int?>(value: v, child: Text('$v')),
              ],
              onChanged: (v) {
                _fichaMinima = v;
                _recargar();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _lista(List<Partida> partidas) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppEspacios.l),
      itemCount: partidas.length,
      itemBuilder: (context, i) {
        final partida = partidas[i];
        return Dismissible(
          key: ValueKey('partida-${partida.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: AppEspacios.l),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Icon(Icons.delete_outline,
                color: Theme.of(context).colorScheme.onErrorContainer),
          ),
          onDismissed: (_) {
            setState(() => partidas.removeAt(i));
            _eliminarConDeshacer(partida);
          },
          child: PartidaListItem(
            partida: partida,
            onTap: () => _abrirDetalle(partida),
            onLongPress: () => _mostrarMenu(partida, partidas),
          ),
        );
      },
    );
  }

  /// Dentro de un scroll para que el "arrastrar para refrescar" funcione
  /// aunque no haya datos.
  Widget _vacio() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: EmptyStateView(
            icono: _hayFiltros ? Icons.filter_alt_off : Icons.history,
            mensaje: _hayFiltros
                ? 'Ninguna partida coincide con los filtros'
                : 'Todavía no hay partidas terminadas',
            detalle: _hayFiltros ? null : '¡Juega una partida para empezar!',
          ),
        ),
      ),
    );
  }
}
