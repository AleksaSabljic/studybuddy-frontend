import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../models/file_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../../services/file_service.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TaskModel _task;
  List<FileModel> _files = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _task = ModalRoute.of(context)!.settings.arguments as TaskModel;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() => _loading = true);
    final data = await TaskService.getTaskDetail(_task.id);
    if (mounted && data != null) {
      setState(() {
        _task = TaskModel.fromJson(data['task']);
        _files = (data['files'] as List)
            .map((f) => FileModel.fromJson(f))
            .toList();
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  // ─── Permission helper ───────────────────────────────────────────────────

  Future<bool> _requestPermission(Permission perm) async {
    final status = await perm.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Permission required'),
          action: SnackBarAction(
              label: 'Settings', onPressed: openAppSettings),
        ),
      );
      return false;
    }
    return status.isGranted;
  }

  // ─── Upload from camera ──────────────────────────────────────────────────

  Future<void> _pickFromCamera() async {
    if (!kIsWeb) {
      final ok = await _requestPermission(Permission.camera);
      if (!ok) return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await _uploadBytes(bytes, picked.name);
  }

  // ─── Upload from gallery ─────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    if (!kIsWeb) await _requestPermission(Permission.photos);
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await _uploadBytes(bytes, picked.name);
  }

  // ─── Pick any file ───────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null) return;
    final f = result.files.single;
    Uint8List? bytes = f.bytes;
    if (bytes == null && f.path != null) {
      bytes = await File(f.path!).readAsBytes();
    }
    if (bytes == null) return;
    await _uploadBytes(bytes, f.name);
  }

  // ─── Upload ──────────────────────────────────────────────────────────────

  Future<void> _uploadBytes(Uint8List bytes, String filename) async {
    setState(() => _uploading = true);
    final result = await FileService.uploadFile(
        bytes: bytes, filename: filename, taskId: _task.id);
    if (!mounted) return;
    setState(() => _uploading = false);
    if (result['success']) {
      setState(() => _files.add(result['file'] as FileModel));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Upload failed')));
    }
  }

  // ─── Show upload bottom sheet ─────────────────────────────────────────────

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Upload Study Material',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Choose File (PDF, Doc...)'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Delete file ─────────────────────────────────────────────────────────

  Future<void> _deleteFile(FileModel file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Delete "${file.originalName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await FileService.deleteFile(file.id);
    if (!mounted) return;
    if (result['success']) {
      setState(() => _files.removeWhere((f) => f.id == file.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Detail'),
        actions: [
          if (auth.isGroupLeader)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await Navigator.pushNamed(context, '/edit-task',
                    arguments: _task);
                _loadDetail();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task title
                    Text(_task.title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    // Meta info
                    _MetaRow(
                        icon: Icons.person_outline,
                        label: 'Assigned to',
                        value: _task.assignedToName ?? 'Unassigned'),
                    const SizedBox(height: 4),
                    _MetaRow(
                        icon: Icons.person_4_outlined,
                        label: 'Created by',
                        value: _task.createdByName ?? '—'),
                    const SizedBox(height: 4),
                    if (_task.createdAt != null)
                      _MetaRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Created',
                          value: DateFormat('MMM d, yyyy – HH:mm')
                              .format(_task.createdAt!)),

                    // Description
                    const SizedBox(height: 20),
                    const Text('Description',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: scheme.surfaceVariant.withOpacity(.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _task.description?.isNotEmpty == true
                            ? _task.description!
                            : 'No description provided.',
                        style: TextStyle(
                            color: scheme.onSurface.withOpacity(.8)),
                      ),
                    ),

                    // Files section
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Attached Files',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        if (_uploading)
                          const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (_files.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text('No files attached yet.',
                              style: TextStyle(
                                  color: scheme.onSurface.withOpacity(.5))),
                        ),
                      )
                    else
                      FutureBuilder<String?>(
                        future: AuthService.getToken(),
                        builder: (context, snap) => Column(
                          children: _files.map((f) => _FileRow(
                            file: f,
                            onDelete: () => _deleteFile(f),
                            token: snap.data,
                          )).toList(),
                        ),
                      ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _uploading ? null : _showUploadSheet,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Study Material'),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }
}

class _FileRow extends StatelessWidget {
  final FileModel file;
  final VoidCallback onDelete;
  final String? token;
  const _FileRow({required this.file, required this.onDelete, this.token});

  Future<void> _download() async {
    final url = '${FileService.getFileUrl(file.id)}?token=$token';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(
            file.isImage
                ? Icons.image_outlined
                : file.isPdf
                    ? Icons.picture_as_pdf_outlined
                    : Icons.insert_drive_file_outlined,
            color: scheme.primary,
          ),
        ),
        title: Text(file.originalName,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(file.sizeFormatted,
            style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download_outlined),
              onPressed: _download,
              tooltip: 'Download',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
