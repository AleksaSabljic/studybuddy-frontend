import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';

class CreateEditTaskScreen extends StatefulWidget {
  const CreateEditTaskScreen({super.key});

  @override
  State<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends State<CreateEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  TaskModel? _editingTask;
  List<UserModel> _students = [];
  int? _selectedStudentId;
  bool _loading = false;
  bool _loadingStudents = true;

  bool get _isEdit => _editingTask != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is TaskModel) {
      _editingTask = arg;
      _titleCtrl.text = arg.title;
      _descCtrl.text = arg.description ?? '';
      _selectedStudentId = arg.assignedTo;
    }
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final students = await TaskService.getStudents();
    if (mounted) {
      setState(() {
        _students = students;
        _loadingStudents = false;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    Map<String, dynamic> result;
    if (_isEdit) {
      result = await TaskService.updateTask(
        id: _editingTask!.id,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        assignedTo: _selectedStudentId,
      );
    } else {
      result = await TaskService.createTask(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        assignedTo: _selectedStudentId,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      final isOffline = result['offline'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isOffline
              ? 'Task saved offline — will sync when connected'
              : _isEdit
                  ? 'Task updated!'
                  : 'Task created!'),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error saving task')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Task' : 'Create Task'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  prefixIcon: Icon(Icons.task_alt),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Assign to student
              const Text('Assign to Student',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              _loadingStudents
                  ? const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator()))
                  : _students.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: scheme.surfaceVariant.withOpacity(.5),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 18, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('No students registered yet',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : DropdownButtonFormField<int>(
                          value: _selectedStudentId,
                          decoration: const InputDecoration(
                            labelText: 'Select Student',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Unassigned'),
                            ),
                            ..._students.map((s) => DropdownMenuItem<int>(
                                  value: s.id,
                                  child: Text(s.username),
                                )),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedStudentId = v),
                        ),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          _isEdit ? 'Save Changes' : 'Create Task',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
