/// Created by Anu Alias on 17-11-2026.

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_models.dart';

class AppDatabase {
  late Database db;

  Future<void> open() async {
    final path = p.join(await getDatabasesPath(), 'rebs_hrms.db');
    db = await openDatabase(
      path,
      version: 1,
      onCreate: (d, _) async {
        await d.execute(
          'CREATE TABLE attendance(id TEXT PRIMARY KEY,type TEXT,status TEXT,timestamp TEXT,latitude REAL,longitude REAL,message TEXT)',
        );
        await d.execute(
          'CREATE TABLE leaves(id TEXT PRIMARY KEY,type TEXT,reason TEXT,status TEXT,startDate TEXT,endDate TEXT)',
        );
        await d.execute('CREATE TABLE cache(key TEXT PRIMARY KEY,value TEXT)');
      },
    );
  }

  Future<void> saveEvent(AttendanceEvent e) async => db.insert(
    'attendance',
    e.toMap(),
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );

  Future<List<AttendanceEvent>> events() async {
    final rows = await db.query('attendance', orderBy: 'timestamp DESC');
    return rows.map(AttendanceEvent.fromMap).toList();
  }

  Future<List<AttendanceEvent>> pendingEvents() async {
    final rows = await db.query(
      'attendance',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'timestamp ASC',
    );
    return rows.map(AttendanceEvent.fromMap).toList();
  }

  Future<void> updateEvent(AttendanceEvent e) async =>
      db.update('attendance', e.toMap(), where: 'id = ?', whereArgs: [e.id]);

  Future<void> replaceLeaves(List<LeaveRequest> leaves) async {
    final b = db.batch();
    b.delete('leaves');
    for (final l in leaves) {
      b.insert('leaves', l.toJson());
    }
    await b.commit(noResult: true);
  }

  Future<List<LeaveRequest>> leaves() async {
    final rows = await db.query('leaves', orderBy: 'startDate DESC');
    return rows.map(LeaveRequest.fromJson).toList();
  }

  Future<void> saveLeave(LeaveRequest l) async => db.insert(
    'leaves',
    l.toJson(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );

  Future<void> cache(String key, String value) async => db.insert('cache', {
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<String?> readCache(String key) async {
    final r = await db.query(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return r.isEmpty ? null : r.first['value'] as String;
  }
}
