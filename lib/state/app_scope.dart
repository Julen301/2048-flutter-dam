import 'package:flutter/widgets.dart';

import '../services/preferencias_service.dart';
import 'sesion_controller.dart';
import 'tema_controller.dart';

/// Inyecta las dependencias compartidas en el árbol de widgets.
/// Las pantallas acceden con `AppScope.of(context)`.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.tema,
    required this.preferencias,
    required this.sesion,
    required super.child,
  });

  final TemaController tema;
  final PreferenciasService preferencias;
  final SesionController sesion;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No hay un AppScope en el árbol de widgets');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      tema != oldWidget.tema ||
      preferencias != oldWidget.preferencias ||
      sesion != oldWidget.sesion;
}
