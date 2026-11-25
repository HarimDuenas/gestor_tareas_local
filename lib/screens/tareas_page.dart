import 'package:flutter/material.dart';
import '../data/tareas_repository.dart';
import '../models/tarea.dart';

// Pantalla base SIN persistencia ni operaciones CRUD implementadas.
// Conserva las indicaciones TODO para orientar tu trabajo.
class TareasPage extends StatefulWidget {
  const TareasPage({super.key});

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  final TextEditingController _tituloController = TextEditingController();

  final TareasRepository _tareasRepository = TareasRepository();

  List<Tarea> _tareas = [];

  @override
  void initState() {
    super.initState();
    _cargarTareas();
  }

  // La consulta se hace aquí y no dentro de build().
  Future<void> _cargarTareas() async {
    try {
      final resultado = await _tareasRepository.listar();
      if (!mounted) return;
      setState(() {
        _tareas = resultado;
      });
    } catch (e) {
      if (!mounted) return;
      _pendiente('No se pudieron cargar las tareas');
    }
  }

  Future<void> _agregarTarea() async {
    try {
      final agregada = await _tareasRepository.agregar(_tituloController.text);
      if (!mounted) return;
      if (!agregada) {
        _pendiente('El título no puede estar vacío');
        return;
      }
      _tituloController.clear();
      await _cargarTareas();
    } catch (e) {
      if (!mounted) return;
      _pendiente('No se pudo guardar la tarea');
    }
  }

  Future<void> _alternarCompletada(Tarea tarea, bool completada) async {
    try {
      await _tareasRepository.cambiarEstado(tarea.id, completada);
      if (!mounted) return;
      await _cargarTareas();
    } catch (e) {
      if (!mounted) return;
      _pendiente('No se pudo cambiar el estado de la tarea');
    }
  }

  Future<void> _editarTarea(Tarea tarea) async {
    final nuevoTitulo = await showDialog<String>(
      context: context,
      builder: (_) => _EditarTituloDialogo(tituloInicial: tarea.titulo),
    );
    if (nuevoTitulo == null) return;

    try {
      final editada = await _tareasRepository.editarTitulo(
        tarea.id,
        nuevoTitulo,
      );
      if (!mounted) return;
      if (!editada) {
        _pendiente('El título no puede estar vacío');
        return;
      }
      await _cargarTareas();
    } catch (e) {
      if (!mounted) return;
      _pendiente('No se pudo editar la tarea');
    }
  }

  Future<void> _eliminarTarea(Tarea tarea) async {
    try {
      await _tareasRepository.eliminar(tarea.id);
      if (!mounted) return;
      await _cargarTareas();
    } catch (e) {
      if (!mounted) return;
      _pendiente('No se pudo eliminar la tarea');
    }
  }

  void _pendiente(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _tareasRepository.cerrar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final pendientes = _tareas.where((t) => !t.completada).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestor de tareas'),
        centerTitle: true,
        backgroundColor: colores.primary,
        foregroundColor: colores.onPrimary,
      ),
      // Ancho máximo para que en web y escritorio no se estire a toda la pantalla.
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _tituloController,
                  onSubmitted: (_) => _agregarTarea(),
                  decoration: const InputDecoration(
                    labelText: 'Nueva tarea',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _agregarTarea,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar tarea'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mis tareas', style: TextStyle(fontSize: 18)),
                    Text(
                      pendientes == 1
                          ? '1 pendiente'
                          : '$pendientes pendientes',
                      style: TextStyle(color: colores.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _tareas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.checklist,
                                size: 64,
                                color: colores.outline,
                              ),
                              const SizedBox(height: 8),
                              const Text('Todavía no hay tareas guardadas'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _tareas.length,
                          itemBuilder: (context, index) {
                            final tarea = _tareas[index];
                            return Card(
                              color: tarea.completada
                                  ? colores.surfaceContainerHighest
                                  : null,
                              child: ListTile(
                                leading: Checkbox(
                                  value: tarea.completada,
                                  onChanged: (valor) {
                                    if (valor != null) {
                                      _alternarCompletada(tarea, valor);
                                    }
                                  },
                                ),
                                title: Text(
                                  tarea.titulo,
                                  style: tarea.completada
                                      ? TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: colores.onSurfaceVariant,
                                        )
                                      : null,
                                ),
                                subtitle: Text('ID: ${tarea.id}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Editar',
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editarTarea(tarea),
                                    ),
                                    IconButton(
                                      tooltip: 'Eliminar',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _eliminarTarea(tarea),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Diálogo con su propio controlador: se libera en su dispose, cuando la
// animación de cierre ya terminó.
class _EditarTituloDialogo extends StatefulWidget {
  const _EditarTituloDialogo({required this.tituloInicial});

  final String tituloInicial;

  @override
  State<_EditarTituloDialogo> createState() => _EditarTituloDialogoState();
}

class _EditarTituloDialogoState extends State<_EditarTituloDialogo> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tituloInicial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar tarea'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Título',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
