import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const TaskPlannerApp());
}

class TaskPlannerApp extends StatelessWidget {
  const TaskPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agenda de tarefas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class UserStore {
  static final Map<String, String> _users = {};
  static String? currentUserEmail;

  static void clearAllUsers() {
    _users.clear();
    currentUserEmail = null;
  }

  static bool register(String email, String password) {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      return false;
    }

    if (password.length < 6) {
      return false;
    }

    if (_users.containsKey(normalizedEmail)) {
      return false;
    }

    _users[normalizedEmail] = password;
    currentUserEmail = normalizedEmail;
    return true;
  }

  static bool login(String email, String password) {
    final normalizedEmail = email.trim();
    final storedPassword = _users[normalizedEmail];

    if (storedPassword == null) {
      return false;
    }

    final isValid = storedPassword == password;
    if (isValid) {
      currentUserEmail = normalizedEmail;
    }

    return isValid;
  }

  static void logout() {
    currentUserEmail = null;
  }
}

class TaskItem {
  TaskItem({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  final String id;
  final String title;
  bool isDone;
}

class TaskStore {
  static final Map<String, List<TaskItem>> _tasksByDay = {};

  static void clearAllTasks() {
    _tasksByDay.clear();
  }

  static String _dayKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String();
  }

  static List<TaskItem> tasksFor(DateTime date) {
    final key = _dayKey(date);
    return List<TaskItem>.from(_tasksByDay[key] ?? const []);
  }

  static List<TaskItem> sortedTasksFor(DateTime date) {
    final tasks = tasksFor(date);
    tasks.sort((a, b) {
      if (a.isDone != b.isDone) {
        return a.isDone ? 1 : -1;
      }

      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return tasks;
  }

  static void addTask(DateTime date, String title) {
    final taskTitle = title.trim();
    if (taskTitle.isEmpty) {
      return;
    }

    final key = _dayKey(date);
    final list = _tasksByDay.putIfAbsent(key, () => []);
    final uniqueId = '${DateTime.now().microsecondsSinceEpoch}_${list.length}';
    list.add(
      TaskItem(
        id: uniqueId,
        title: taskTitle,
      ),
    );
  }

  static void toggleTask(DateTime date, String taskId) {
    final key = _dayKey(date);
    final list = _tasksByDay[key];
    if (list == null) {
      return;
    }

    for (final task in list) {
      if (task.id == taskId) {
        task.isDone = !task.isDone;
        return;
      }
    }
  }

  static void removeTask(DateTime date, String taskId) {
    final key = _dayKey(date);
    final list = _tasksByDay[key];
    if (list == null) {
      return;
    }

    list.removeWhere((task) => task.id == taskId);
    if (list.isEmpty) {
      _tasksByDay.remove(key);
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _login() {
    final email = emailController.text;
    final password = passwordController.text;

    if (UserStore.login(email, password)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credenciais inválidas. Tente novamente.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.calendar_month, size: 60, color: Colors.green),
                    const SizedBox(height: 12),
                    const Text(
                      'Entrar na agenda',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _login,
                      icon: const Icon(Icons.login),
                      label: const Text('Entrar'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text('Criar conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _register() {
    final email = emailController.text;
    final password = passwordController.text;

    final isCreated = UserStore.register(email, password);
    if (isCreated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Não foi possível cadastrar. Verifique e-mail e senha (mínimo 6 caracteres).',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.person_add_alt_1, size: 54, color: Colors.green),
                    const SizedBox(height: 12),
                    const Text(
                      'Crie sua conta',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _register,
                      icon: const Icon(Icons.check),
                      label: const Text('Cadastrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  void _showAddTaskDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adicionar tarefa'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome da tarefa',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text;
                if (text.trim().isNotEmpty) {
                  TaskStore.addTask(_selectedDay, text);
                  setState(() {});
                }
                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = TaskStore.sortedTasksFor(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário de tarefas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              UserStore.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) => TaskStore.tasksFor(day),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tarefas de ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text('${tasks.length} itens'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tasks.isEmpty
                ? const Center(
                    child: Text('Nenhuma tarefa cadastrada neste dia.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Card(
                        child: ListTile(
                          leading: Checkbox(
                            value: task.isDone,
                            onChanged: (_) {
                              TaskStore.toggleTask(_selectedDay, task.id);
                              setState(() {});
                            },
                          ),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isDone ? TextDecoration.lineThrough : null,
                              color: task.isDone ? Colors.grey : null,
                            ),
                          ),
                          subtitle: Text(task.isDone ? 'Concluída' : 'Pendente'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              TaskStore.removeTask(_selectedDay, task.id);
                              setState(() {});
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
