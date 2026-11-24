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

  Future<void> cerrar() => _db.close();
}
