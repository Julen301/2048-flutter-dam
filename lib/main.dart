import 'package:flutter/material.dart';

import 'app.dart';
import 'data/usuario_dao.dart';
import 'services/auth_service.dart';
import 'services/preferencias_service.dart';
import 'state/sesion_controller.dart';
import 'state/tema_controller.dart';

Future<void> main() async {
  // Necesario para usar plugins (shared_preferences, sqflite) antes de runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Se cargan las preferencias ANTES de runApp: así el primer frame ya
  // usa el tema correcto y no hay parpadeo.
  final preferencias = await PreferenciasService.crear();
  final tema = TemaController(
    preferencias,
    modoInicial: await preferencias.leerModoTema(),
    paletaInicial: await preferencias.leerPaletaFichas(),
  );

  final sesion = SesionController(preferencias, AuthService(UsuarioDao()));
  await sesion.restaurar();

  runApp(App2048(tema: tema, preferencias: preferencias, sesion: sesion));
}
