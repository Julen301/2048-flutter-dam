import 'package:flutter/material.dart';

import 'routes.dart';
import 'services/preferencias_service.dart';
import 'state/app_scope.dart';
import 'state/sesion_controller.dart';
import 'state/tema_controller.dart';
import 'theme/app_theme.dart';

class App2048 extends StatelessWidget {
  const App2048({
    super.key,
    required this.tema,
    required this.preferencias,
    required this.sesion,
  });

  final TemaController tema;
  final PreferenciasService preferencias;
  final SesionController sesion;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      tema: tema,
      preferencias: preferencias,
      sesion: sesion,
      // Cada cambio en TemaController reconstruye MaterialApp en tiempo real.
      child: ListenableBuilder(
        listenable: tema,
        builder: (context, _) => MaterialApp(
          title: '2048',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro(tema.paleta),
          darkTheme: AppTheme.oscuro(tema.paleta),
          themeMode: tema.modo,
          // Si había sesión guardada se entra directo a Inicio.
          initialRoute: sesion.haySesion ? AppRoutes.home : AppRoutes.login,
          onGenerateRoute: AppRoutes.generar,
          // Evita que '/login' apile también '/' debajo (comportamiento por defecto).
          onGenerateInitialRoutes: AppRoutes.rutasIniciales,
        ),
      ),
    );
  }
}
