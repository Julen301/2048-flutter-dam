# 2048 en Flutter

Práctica de **Acceso a datos** (sqflite + shared_preferences) y **Desarrollo de interfaces** (pantallas, navegación, gestos y widgets reutilizables).

## Cómo ejecutarlo

```bash
flutter create . --platforms=android   # genera la carpeta android/ si no existe
flutter pub get
flutter run                            # en emulador o dispositivo Android
flutter test                           # tests de la lógica del juego
```

> Si `flutter create .` genera `test/widget_test.dart`, borradlo: hace referencia a `MyApp`, que no existe en este proyecto.

> sqflite no funciona en web sin configuración extra: usad un emulador Android.

## Estructura de carpetas

```
lib/
├── main.dart            # Arranque: carga preferencias y sesión antes de runApp
├── app.dart             # MaterialApp (theme, darkTheme, themeMode, rutas)
├── routes.dart          # Rutas con nombre centralizadas (onGenerateRoute)
├── models/              # Clases modelo con toMap()/fromMap()
├── data/                # DatabaseHelper (singleton) y DAOs
├── services/            # PreferenciasService, AuthService
├── state/               # TemaController, SesionController, AppScope
├── game/                # Lógica pura del 2048 (sin Flutter)
├── theme/               # app_theme.dart: colores, tamaños, espaciados
├── screens/             # Una pantalla por archivo
├── widgets/             # Widgets reutilizables, uno por archivo
└── utils/               # Formateo de fechas y duraciones
```

## Flujo de trabajo Git

- `main`: versión entregable.
- `develop`: integración.
- `julen/*` y `manel/*`: una rama por tarea, se fusiona en `develop` con `--no-ff`.

Documentación: carpeta [`docs/`](docs/).
