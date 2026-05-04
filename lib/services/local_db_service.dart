import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';

class LocalDbService {
  static Database? _db;

  static Future<Database> get database async {
    if (kIsWeb) throw UnsupportedError('sqflite not supported on web');
    _db ??= await _initDb();
    return _db!;
  }

  static Future<List<TaskModel>> getAllTasks() async {
    if (kIsWeb) return [];
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'created_at DESC');
    return maps.map((m) => TaskModel.fromJson(m)).toList();
  }

  static Future<void> insertOrUpdateTask(TaskModel task) async {
    if (kIsWeb) return;
    final db = await database;
    await db.insert('tasks', task.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> insertOrUpdateTasks(List<TaskModel> tasks) async {
    if (kIsWeb) return;
    final db = await database;
    final batch = db.batch();
    for (final t in tasks) {
      batch.insert('tasks', t.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> deleteTask(int id) async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<TaskModel>> getPendingTasks() async {
    if (kIsWeb) return [];
    final db = await database;
    final maps =
        await db.query('tasks', where: 'is_pending_sync = ?', whereArgs: [1]);
    return maps.map((m) => TaskModel.fromJson(m)).toList();
  }

  static Future<void> clearTasks() async {
    if (kIsWeb) return;
    final db = await database;
    await db.delete('tasks');
  }

  static Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'studybuddy.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            created_by INTEGER,
            assigned_to INTEGER,
            created_by_name TEXT,
            assigned_to_name TEXT,
            created_at TEXT,
            updated_at TEXT,
            is_pending_sync INTEGER DEFAULT 0,
            local_id TEXT
          )
        ''');
      },
    );
  }

}
