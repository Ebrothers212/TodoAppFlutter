import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<Todo> _todos = [];
  final _textController = TextEditingController();
  final _uuid = const Uuid();
  final _dateFormat = DateFormat('MMM d, y h:mm a');
  final _activeScrollController = ScrollController();
  final _completedScrollController = ScrollController();
  DateTime? _selectedDueDate;
  SharedPreferences? _prefs;
  bool _isLoading = true;
  bool _showCompleted = true;  // Toggle for completed section visibility

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _activeScrollController.addListener(_onActiveScroll);
    _completedScrollController.addListener(_onCompletedScroll);
  }

  void _onActiveScroll() {
    if (_activeScrollController.position.pixels == _activeScrollController.position.maxScrollExtent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You\'ve reached the end of active todos'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _onCompletedScroll() {
    if (_completedScrollController.position.pixels == _completedScrollController.position.maxScrollExtent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You\'ve reached the end of completed todos'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  List<Todo> get _activeTodos => _todos.where((todo) => !todo.isCompleted).toList()
    ..sort((a, b) {
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate == null && b.dueDate != null) return 1;
      if (a.dueDate != null && b.dueDate == null) return -1;
      return b.createdAt.compareTo(a.createdAt);
    });

  List<Todo> get _completedTodos => _todos.where((todo) => todo.isCompleted).toList()
    ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTodos();
  }

  Future<void> _loadTodos() async {
    if (_prefs == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final todosJson = _prefs!.getStringList('todos') ?? [];
      final loadedTodos = todosJson
          .map((todo) => Todo.fromJson(jsonDecode(todo)))
          .toList();

      setState(() {
        _todos.clear();
        _todos.addAll(loadedTodos);
      });
    } catch (e) {
      debugPrint('Error loading todos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error loading todos'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortTodos() {
    _todos.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate == null && b.dueDate != null) return 1;
      if (a.dueDate != null && b.dueDate == null) return -1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> _saveTodos() async {
    if (_prefs == null) return;

    try {
      final todosJson = _todos.map((todo) => jsonEncode(todo.toJson())).toList();
      await _prefs!.setStringList('todos', todosJson);
    } catch (e) {
      debugPrint('Error saving todos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error saving todos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addTodo(String title) {
    if (title.trim().isEmpty) return;

    setState(() {
      _todos.add(Todo(
        id: _uuid.v4(),
        title: title.trim(),
        dueDate: _selectedDueDate,
      ));
      _selectedDueDate = null;
      _sortTodos();
    });
    _textController.clear();
    _saveTodos();
  }

  void _toggleTodo(String id) {
    setState(() {
      final todoIndex = _todos.indexWhere((todo) => todo.id == id);
      if (todoIndex != -1) {
        final todo = _todos[todoIndex];
        _todos[todoIndex] = todo.copyWith(
          isCompleted: !todo.isCompleted,
          completedAt: !todo.isCompleted ? DateTime.now() : null,
        );
      }
    });
    _saveTodos();
  }

  void _deleteTodo(String id) {
    setState(() {
      _todos.removeWhere((todo) => todo.id == id);
    });
    _saveTodos();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      // ignore: use_build_context_synchronously
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDueDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _updateDueDate(String id) async {
    final todoIndex = _todos.indexWhere((todo) => todo.id == id);
    if (todoIndex == -1) return;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _todos[todoIndex].dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      // ignore: use_build_context_synchronously
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _todos[todoIndex].dueDate ?? DateTime.now(),
        ),
      );

      if (pickedTime != null) {
        setState(() {
          _todos[todoIndex] = _todos[todoIndex].copyWith(
            dueDate: DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            ),
          );
        });
        _saveTodos();
      }
    }
  }

  Widget _buildSection({
    required String title,
    required List<Todo> todos,
    required ScrollController scrollController,
    required Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title (${todos.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
        const Divider(),
        if (todos.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No $title todos',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        else
          ListView.builder(
            controller: scrollController,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return Dismissible(
                key: Key(todo.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteTodo(todo.id),
                child: ListTile(
                  leading: Checkbox(
                    value: todo.isCompleted,
                    onChanged: (_) => _toggleTodo(todo.id),
                  ),
                  title: Text(
                    todo.title,
                    style: TextStyle(
                      decoration: todo.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created: ${_dateFormat.format(todo.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (todo.dueDate != null)
                        Text(
                          'Due: ${_dateFormat.format(todo.dueDate!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: todo.dueDate!.isBefore(DateTime.now())
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                        ),
                      if (todo.isCompleted && todo.completedAt != null)
                        Text(
                          'Completed: ${_dateFormat.format(todo.completedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                              ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => _updateDueDate(todo.id),
                        tooltip: 'Update due date',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteTodo(todo.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TaskMaster'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          automaticallyImplyLeading: false,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: _loadTodos,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _textController,
                                    decoration: const InputDecoration(
                                      hintText: 'Add a new todo',
                                      border: OutlineInputBorder(),
                                    ),
                                    onSubmitted: _addTodo,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _selectDateTime(context),
                                  icon: const Icon(Icons.calendar_today),
                                  tooltip: 'Set due date',
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _addTodo(_textController.text),
                                  icon: const Icon(Icons.add),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedDueDate != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Due date: ${_dateFormat.format(_selectedDueDate!)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildSection(
                        title: 'Active',
                        todos: _activeTodos,
                        scrollController: _activeScrollController,
                        trailing: null,
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Completed (${_completedTodos.length})',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(_showCompleted ? Icons.expand_less : Icons.expand_more),
                                  onPressed: () {
                                    setState(() {
                                      _showCompleted = !_showCompleted;
                                    });
                                  },
                                  tooltip: _showCompleted ? 'Hide completed' : 'Show completed',
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                          if (_showCompleted)
                            if (_completedTodos.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: Text(
                                    'No completed todos',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              )
                            else
                              ListView.builder(
                                controller: _completedScrollController,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _completedTodos.length,
                                itemBuilder: (context, index) {
                                  final todo = _completedTodos[index];
                                  return Dismissible(
                                    key: Key(todo.id),
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 16.0),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (_) => _deleteTodo(todo.id),
                                    child: ListTile(
                                      leading: Checkbox(
                                        value: todo.isCompleted,
                                        onChanged: (_) => _toggleTodo(todo.id),
                                      ),
                                      title: Text(
                                        todo.title,
                                        style: TextStyle(
                                          decoration: todo.isCompleted
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Created: ${_dateFormat.format(todo.createdAt)}',
                                            style: Theme.of(context).textTheme.bodySmall,
                                          ),
                                          if (todo.dueDate != null)
                                            Text(
                                              'Due: ${_dateFormat.format(todo.dueDate!)}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: todo.dueDate!.isBefore(DateTime.now())
                                                        ? Colors.red
                                                        : Colors.orange,
                                                  ),
                                            ),
                                          if (todo.isCompleted && todo.completedAt != null)
                                            Text(
                                              'Completed: ${_dateFormat.format(todo.completedAt!)}',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.green,
                                                  ),
                                            ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.calendar_today),
                                            onPressed: () => _updateDueDate(todo.id),
                                            tooltip: 'Update due date',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => _deleteTodo(todo.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        ],
                      ),
                      if (_showCompleted) const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _activeScrollController.dispose();
    _completedScrollController.dispose();
    super.dispose();
  }
} 