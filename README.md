# Gestor de tareas local

App Flutter que guarda las tareas en una base SQLite del propio dispositivo, sin servidor. Las tareas siguen ahí después de cerrar y volver a abrir la app. Práctica de Programación de Dispositivos Móviles.

## Qué hace
Agrega tareas (no acepta títulos vacíos ni de solo espacios), las lista, edita el título, las marca como completadas o pendientes y las elimina.

## Cómo ejecutarlo
```
flutter pub get
flutter run -d chrome
```
Cambia `chrome` por otro identificador de `flutter devices` para probar en Windows o Android.

## Persistencia
Uso Drift con `drift_flutter`. Con un mismo código funciona en web, móvil y escritorio. `sqflite` no cubre web ni escritorio por sí solo, y la consigna no acepta una lista en memoria ni guardar JSON en `shared_preferences`.

La pantalla se actualiza con `watch()` y un `StreamBuilder`: Drift avisa cuando cambia la tabla y la lista se redibuja sola, sin volver a consultar a mano. El stream se crea en `initState`, no dentro de `build()`.

## Tabla `tareas`
| Columna | Tipo en SQLite | Restricciones |
|---|---|---|
| `id` | INTEGER | llave primaria, autoincremental |
| `titulo` | TEXT | no nulo |
| `completada` | INTEGER (0 o 1) | no nulo, por defecto 0 |

Edición y eliminación van por `id`, no por la posición en la lista. El título se recorta con `trim()` y se rechaza si queda vacío; esa validación está en la app y no en la tabla.
