import 'package:drift/drift.dart';

import '../models/tarea.dart';
import 'database.dart';

class TareasRepository {
  final AppDatabase _db;

  TareasRepository([AppDatabase? db]) : _db = db ?? AppDatabase();

  Future<List<Tarea>> listar() {
    return (_db.select(_db.tareas)..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  // Devuelve false si el título queda vacío al quitar los espacios.
  Future<bool> agregar(String titulo) async {
    final limpio = titulo.trim();
    if (limpio.isEmpty) return false;
    await _db.into(_db.tareas).insert(TareasCompanion.insert(titulo: limpio));
    return true;
  }

  // Devuelve false si el nuevo título queda vacío al quitar los espacios.
  Future<bool> editarTitulo(int id, String titulo) async {
    final limpio = titulo.trim();
    if (limpio.isEmpty) return false;
    await (_db.update(_db.tareas)..where((t) => t.id.equals(id)))
        .write(TareasCompanion(titulo: Value(limpio)));
    return true;
  }

  Future<void> cambiarEstado(int id, bool completada) {
    return (_db.update(_db.tareas)..where((t) => t.id.equals(id)))
        .write(TareasCompanion(completada: Value(completada)));
  }

  Future<void> eliminar(int id) {
    return (_db.delete(_db.tareas)..where((t) => t.id.equals(id))).go();
  }

  Future<void> cerrar() => _db.close();
}
