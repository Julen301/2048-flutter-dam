# Documentación — Interfaz, gestos y widgets

## 1. Pantallas

| Pantalla | Archivo | Contenido |
|---|---|---|
| Login / Registro | `login_screen.dart`, `registro_screen.dart` | Formularios validados (email con `@`, contraseña mínima 6) |
| Inicio | `inicio_screen.dart` | Título, mejor puntuación, Nueva partida, Continuar (solo si hay guardada), accesos a Historial, Ranking y Ajustes |
| Juego | `juego_screen.dart` | Tablero 4×4, puntos, mejor, movimientos, cronómetro, reiniciar, guardar |
| Historial | `historial_screen.dart` | Lista con filtros por jugador y ficha mínima |
| Detalle | `detalle_screen.dart` | Puntuación, ficha máxima, movimientos, duración, fecha, tamaño de tablero |
| Ranking | `ranking_screen.dart` | Top 10, estadísticas globales y por jugador |
| Ajustes | `ajustes_screen.dart` | Tema claro/oscuro/sistema, paleta de fichas, vibración, borrar historial, cerrar sesión |

## 2. Tabla de gestos

| Gesto | Widget / callback | Pantalla | Comportamiento |
|---|---|---|---|
| Swipe 4 direcciones | `GestureDetector` `onPanStart/onPanUpdate/onPanEnd` (`BoardWidget`) | Juego | Acumula el desplazamiento; si no supera `AppTamanos.umbralSwipe` (24 px) se ignora; si lo supera, gana el eje con mayor valor absoluto |
| Teclado (flechas / WASD) | `Focus` + `onKeyEvent` (`BoardWidget`) | Juego | Alternativa accesible al gesto |
| Botones de dirección | `IconButton.filledTonal` (`ControlesDireccion`) | Juego | Alternativa accesible al gesto |
| Deslizar para descartar | `Dismissible` (`endToStart`) | Historial | Borra la partida y muestra `SnackBar` con **Deshacer**, que la vuelve a insertar con el mismo id |
| Pulsación larga | `ListTile.onLongPress` (`PartidaListItem`) | Historial | `showModalBottomSheet` con *Ver detalle* y *Eliminar* (con `ConfirmDialog`) |
| Pulsación simple | `ListTile.onTap` (`PartidaListItem`) | Historial, Ranking | Navega al detalle pasando el id |
| Arrastrar hacia abajo | `RefreshIndicator` | Historial, Ranking | Vuelve a consultar la base de datos |
| Doble toque | `GestureDetector.onDoubleTap` (`ScoreCard` "PUNTOS") | Juego | Muestra/oculta los detalles de la partida (jugador, ficha máxima y lo que falta para 2048) |
| Atrás del sistema | `PopScope` | Juego | Con partida en curso: Guardar y salir / Salir sin guardar / Cancelar |
| Atrás del sistema | `PopScope` | HomeShell | En otra pestaña vuelve a Inicio |

**¿Por qué `onPan*` y no `onHorizontalDragEnd` + `onVerticalDragEnd`?** Si se registran los dos reconocedores en el mismo `GestureDetector` compiten en la *gesture arena* y el que gana es el primero que supera su *slop*, lo que en diagonales provoca movimientos en el eje equivocado. Con `onPan*` se recibe el desplazamiento 2D completo y se decide la dirección dominante al soltar, aplicando además el umbral mínimo.

**Ninguna acción destructiva sin vía de escape**: el swipe del historial tiene *Deshacer*; los borrados desde menú, detalle y ajustes, reiniciar y salir del juego usan `ConfirmDialog`.

## 3. Tabla de reutilización de widgets

| Widget (`lib/widgets/`) | Tipo | Se usa en |
|---|---|---|
| `TileWidget` | Stateless | Juego (vía `BoardWidget`), Historial y Ranking (vía `PartidaListItem`), Detalle, Ajustes (vista previa) |
| `BoardWidget` | Stateful* | Juego |
| `ScoreCard` | Stateless | Juego, Inicio |
| `StatCard` | Stateless | Ranking, Detalle |
| `PartidaListItem` | Stateless | Historial, Ranking |
| `ConfirmDialog` | Stateless | Juego (reiniciar, salir con 3 opciones, fin), Inicio (nueva partida, cerrar sesión), Historial, Detalle, Ajustes |
| `EmptyStateView` | Stateless | Historial, Ranking, Detalle, `AsyncDataView` (errores) |
| `AsyncDataView<T>` | Stateless | Inicio, Historial, Detalle, Ranking |
| `ControlesDireccion` | Stateless | Juego |

\* `BoardWidget` solo guarda estado de interacción (desplazamiento acumulado y `FocusNode`); el estado del juego vive en `JuegoScreen`.

Todos reciben datos y callbacks por constructor, tienen constructor `const` y **ninguno accede a la base de datos**.

## 4. Tema y estilo

- `lib/theme/app_theme.dart` concentra espaciados (`AppEspacios`), tamaños (`AppTamanos`), duraciones (`AppDuraciones`), estilos de texto (`AppTextos`) y colores de fichas (`FichasTheme`, una `ThemeExtension`).
- Los widgets leen los colores con `Theme.of(context)` / `FichasTheme.of(context)`, así que cambian al instante al modificar el modo.
- En modo oscuro se baja la luminosidad de las fichas y el texto de cada ficha se elige según su luminancia (oscuro sobre fichas claras, claro sobre oscuras).
- **Animaciones**: `AnimatedContainer` (color de la ficha), `TweenAnimationBuilder` (escala al aparecer y al fusionarse), `AnimatedSize` (panel de detalles).

## 5. Justificación de decisiones

**Navegación — `NavigationBar`**: Inicio, Historial, Ranking y Ajustes son cuatro destinos del mismo nivel que se visitan a menudo; la barra inferior los deja siempre a un toque y es el patrón Material 3 para 3–5 destinos. Un `Drawer` los esconde tras un toque más y un `TabBar` se reserva para subsecciones de una misma pantalla. Juego y Detalle son pantallas apiladas encima (rutas con nombre), no pestañas.

**Gestor de estado — `ChangeNotifier` + `InheritedWidget` propio (`AppScope`)**: el estado global es pequeño (tema y sesión), así que no hace falta añadir dependencias como Provider. `AppScope` inyecta `TemaController`, `SesionController` y `PreferenciasService`; `ListenableBuilder` reconstruye `MaterialApp` cuando cambia el tema. El estado de cada pantalla (lista, filtros, partida) es local con `StatefulWidget` y los datos asíncronos se cargan con `FutureBuilder` dentro de `AsyncDataView`.

**Estructura de carpetas**: por capas (`models`, `data`, `services`, `state`, `game`, `theme`, `screens`, `widgets`, `utils`). La lógica del 2048 (`game/`) es Dart puro y tiene tests unitarios; las pantallas solo coordinan y delegan en DAOs y widgets.
