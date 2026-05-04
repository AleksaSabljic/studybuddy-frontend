import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/task_service.dart';
import '../../utils/app_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TaskModel> _tasks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tasks = await TaskService.getTasks();
      if (mounted) setState(() => _tasks = tasks);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await TaskService.deleteTask(task.id);
    if (!mounted) return;
    if (result['success']) {
      setState(() => _tasks.removeWhere((t) => t.id == task.id));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final chat = context.watch<ChatProvider>();
    final scheme = Theme.of(context).colorScheme;
    final isLeader = auth.isGroupLeader;

    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyBuddy'),
        actions: [
          IconButton(
            icon: Icon(theme.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: theme.toggle,
            tooltip: 'Toggle dark mode',
          ),
          Badge(
            isLabelVisible: chat.unreadCount > 0,
            label: Text(chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}'),
            child: IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.chat);
                if (mounted) context.read<ChatProvider>().markAsRead();
              },
              tooltip: 'Group Chat',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.location_on_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.location),
            tooltip: 'Location',
          ),
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
            onSelected: (val) async {
              if (val == 'logout') {
                context.read<ChatProvider>().disconnect();
                await auth.logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              } else if (val == 'profile') {
                Navigator.pushNamed(context, AppRoutes.profile);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('Could not connect — showing cached tasks'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _loadTasks, child: const Text('Retry')),
                    ],
                  ))
                : _tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.task_alt,
                                size: 64, color: scheme.primary.withOpacity(.4)),
                            const SizedBox(height: 12),
                            Text(isLeader
                                ? 'No tasks yet. Create one!'
                                : 'No tasks assigned to you yet.'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasks.length,
                        itemBuilder: (_, i) {
                          final task = _tasks[i];
                          return _TaskCard(
                            task: task,
                            isLeader: isLeader,
                            onTap: () async {
                              await Navigator.pushNamed(
                                  context, AppRoutes.taskDetail,
                                  arguments: task);
                              _loadTasks();
                            },
                            onEdit: isLeader
                                ? () async {
                                    await Navigator.pushNamed(
                                        context, AppRoutes.editTask,
                                        arguments: task);
                                    _loadTasks();
                                  }
                                : null,
                            onDelete: isLeader ? () => _deleteTask(task) : null,
                          );
                        },
                      ),
      ),
      floatingActionButton: isLeader
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.createTask);
                _loadTasks();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Task'),
            )
          : null,
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isLeader;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TaskCard({
    required this.task,
    required this.isLeader,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateStr = task.createdAt != null
        ? DateFormat('MMM d, yyyy').format(task.createdAt!)
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Pending sync badge
                  if (task.isPendingSync)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('Pending sync',
                          style:
                              TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isLeader)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: onEdit,
                          tooltip: 'Edit',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Colors.red),
                          onPressed: onDelete,
                          tooltip: 'Delete',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                ],
              ),
              if (task.description != null &&
                  task.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurface.withOpacity(.6)),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (task.assignedToName != null) ...[
                    Icon(Icons.person_outline,
                        size: 14,
                        color: scheme.onSurface.withOpacity(.5)),
                    const SizedBox(width: 4),
                    Text(task.assignedToName!,
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withOpacity(.6))),
                    const SizedBox(width: 12),
                  ],
                  const Spacer(),
                  Text(dateStr,
                      style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurface.withOpacity(.5))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
