import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_local/data/database.dart';
import 'package:gestor_tareas_local/data/tareas_repository.dart';

void main() {
  group('con base en memoria', () {
    late TareasRepository repositorio;

    setUp(() {
      // Cada prueba empieza con la tabla vacía.
      repositorio = TareasRepository(AppDatabase(NativeDatabase.memory()));
    });

    tearDown(() async {
      await repositorio.cerrar();
    });

    test('agregar guarda la tarea como pendiente', () async {
      final agregada = await repositorio.agregar('Comprar pan');
      final tareas = await repositorio.listar();

      expect(agregada, true);
      expect(tareas.length, 1);
      expect(tareas.first.titulo, 'Comprar pan');
      expect(tareas.first.completada, false);
    });

    test('agregar quita los espacios de los extremos del título', () async {
      await repositorio.agregar('  Comprar pan  ');
      final tareas = await repositorio.listar();

      expect(tareas.first.titulo, 'Comprar pan');
    });

    test('agregar rechaza un título vacío o de solo espacios', () async {
      final vacia = await repositorio.agregar('');
      final espacios = await repositorio.agregar('   ');
      final tareas = await repositorio.listar();

      expect(vacia, false);
      expect(espacios, false);
      expect(tareas, isEmpty);
    });

    test('editarTitulo cambia el título y rechaza uno vacío', () async {
      await repositorio.agregar('Uno');
      final id = (await repositorio.listar()).first.id;

      final editada = await repositorio.editarTitulo(id, '  Uno editado ');
      final vacia = await repositorio.editarTitulo(id, '   ');
      final tareas = await repositorio.listar();

      expect(editada, true);
      expect(vacia, false);
      expect(tareas.first.titulo, 'Uno editado');
    });

    test('cambiarEstado afecta solo a la tarea indicada', () async {
      await repositorio.agregar('Uno');
      await repositorio.agregar('Dos');
      final tareas = await repositorio.listar();

      await repositorio.cambiarEstado(tareas[1].id, true);
      final despues = await repositorio.listar();

      expect(despues[0].completada, false);
      expect(despues[1].completada, true);
    });

    test('eliminar borra solo la tarea con ese id', () async {
      await repositorio.agregar('Uno');
      await repositorio.agregar('Dos');
      await repositorio.agregar('Tres');
      final tareas = await repositorio.listar();

      await repositorio.eliminar(tareas[1].id);
      final despues = await repositorio.listar();

      expect(despues.map((t) => t.titulo).toList(), ['Uno', 'Tres']);
    });
  });

  // Va fuera del grupo para no tener otra base abierta al mismo tiempo.
  test('las tareas siguen ahí al cerrar y volver a abrir la base', () async {
    final carpeta = Directory.systemTemp.createTempSync('gestor_tareas_test');
    addTearDown(() => carpeta.deleteSync(recursive: true));
    final archivo = File('${carpeta.path}/tareas.sqlite');

    final primera = TareasRepository(AppDatabase(NativeDatabase(archivo)));
    await primera.agregar('Estudiar SQLite');
    await primera.cerrar();

    final segunda = TareasRepository(AppDatabase(NativeDatabase(archivo)));
    final tareas = await segunda.listar();
    await segunda.cerrar();

    expect(tareas.map((t) => t.titulo).toList(), ['Estudiar SQLite']);
  });
}
