import 'package:flutter_test/flutter_test.dart';
import 'package:test/main.dart';

void main() {
  test('register and login work with stored users', () {
    UserStore.clearAllUsers();

    final created = UserStore.register('ana@email.com', '123456');
    expect(created, isTrue);

    final loginOk = UserStore.login('ana@email.com', '123456');
    expect(loginOk, isTrue);

    final invalidLogin = UserStore.login('ana@email.com', 'senhaerrada');
    expect(invalidLogin, isFalse);
  });

  test('pending tasks are sorted before completed tasks and alphabetically', () {
    final date = DateTime(2026, 9, 19);
    TaskStore.clearAllTasks();

    TaskStore.addTask(date, 'Zebra');
    TaskStore.addTask(date, 'alfa');
    TaskStore.addTask(date, 'Beta');
    TaskStore.addTask(date, 'delta');

    final zebraId = TaskStore.tasksFor(date).firstWhere((task) => task.title == 'Zebra').id;
    final betaId = TaskStore.tasksFor(date).firstWhere((task) => task.title == 'Beta').id;

    TaskStore.toggleTask(date, zebraId);
    TaskStore.toggleTask(date, betaId);

    final sorted = TaskStore.sortedTasksFor(date);

    expect(sorted.map((task) => task.title).toList(), equals(['alfa', 'delta', 'Beta', 'Zebra']));
    expect(sorted[0].isDone, isFalse);
    expect(sorted[1].isDone, isFalse);
    expect(sorted[2].isDone, isTrue);
    expect(sorted[3].isDone, isTrue);
  });
}
