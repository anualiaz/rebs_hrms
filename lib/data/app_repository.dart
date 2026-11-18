/// Created by Anu Alias on 17-11-2026.

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../models/app_models.dart';
import 'app_database.dart';
import 'app_api.dart';

class HrmsRepository {
  final AppDatabase db;
  final HrmsApi api;
  final _uuid = const Uuid();

  HrmsRepository(this.db, this.api);

  Future<bool> get online async => !(await Connectivity().checkConnectivity())
      .contains(ConnectivityResult.none);

  Future<Employee> loadEmployee() async {
    try {
      final e = await api.employee();
      await db.cache('employee', jsonEncode(e.toJson()));
      return e;
    } catch (_) {
      final s = await db.readCache('employee');
      if (s != null) return Employee.fromJson(jsonDecode(s));
      rethrow;
    }
  }

  Future<dynamic> loadBalance() async {
    try {
      final n = await api.leaveBalance();
      await db.cache('balance', '$n');
      return n;
    } catch (_) {
      int.tryParse(await db.readCache('balance') ?? '') ?? 0;
    }
  }

  Future<List<AttendanceEvent>> loadAttendance() async {
    try {
      final remote = await api.attendance();
      for (final e in remote) {
        await db.saveEvent(e);
      }
    } catch (_) {}
    return db.events();
  }

  Future<List<LeaveRequest>> loadLeaves() async {
    try {
      final l = await api.leaveRequests();
      await db.replaceLeaves(l);
    } catch (_) {}
    return db.leaves();
  }

  Future<void> recordAttendance(String type, double lat, double lng) async {
    final existing = await db.events();
    final today = DateTime.now();

    final todayEvents = existing
        .where(
          (e) =>
              e.timestamp.year == today.year &&
              e.timestamp.month == today.month &&
              e.timestamp.day == today.day &&
              e.status != 'rejected',
        )
        .toList();

    // Sort attendance records by time
    todayEvents.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Get the latest attendance record
    final lastEvent = todayEvents.isEmpty ? null : todayEvents.last;

    // Validate attendance sequence
    if (type == 'check_in') {
      if (lastEvent != null && lastEvent.type == 'check_in') {
        throw Exception('Please check out before checking in again.');
      }
    } else if (type == 'check_out') {
      if (lastEvent == null || lastEvent.type != 'check_in') {
        throw Exception('Please check in before checking out.');
      }
    }

    // Save a new attendance record
    await db.saveEvent(
      AttendanceEvent(
        id: _uuid.v4(),
        type: type,
        status: 'pending',
        timestamp: DateTime.now(),
        latitude: lat,
        longitude: lng,
      ),
    );
  }

  Future<void> sync() async {
    if (!await online) return;
    final pending = await db.pendingEvents();
    for (final e in pending) {
      try {
        await api.submitEvent(e);
        await db.updateEvent(e.withStatus('synced'));
      } on ApiException catch (x) {
        await db.updateEvent(e.withStatus('rejected', x.message));
      } catch (_) {
        // Timeout/network error is ambiguous: leave pending and retry with same UUID.
        break;
      }
    }
  }

  Future<LeaveRequest> applyLeave(
    String type,
    DateTime start,
    DateTime end,
    String reason,
    int balance,
    List<LeaveRequest> existing,
  ) async {
    final clean = reason.trim();
    if (start.isBefore(
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
    ))
      throw Exception('Start date cannot be in the past.');
    if (end.isBefore(start))
      throw Exception('End date cannot be before start date.');
    if (clean.length < 10)
      throw Exception(
        'Reason must contain at least 10 non-whitespace characters.',
      );
    final days = end.difference(start).inDays + 1;
    if (days > balance)
      throw Exception('Requested days exceed your available leave balance.');
    for (final l in existing.where(
      (l) => l.status == 'Pending' || l.status == 'Approved',
    )) {
      if (!end.isBefore(l.startDate) && !start.isAfter(l.endDate))
        throw Exception(
          'These dates overlap an existing ${l.status.toLowerCase()} request.',
        );
    }
    if (!await online)
      throw Exception('Internet connection is required to submit leave.');
    final request = LeaveRequest(
      id: _uuid.v4(),
      type: type,
      reason: clean,
      status: 'Pending',
      startDate: start,
      endDate: end,
    );
    final saved = await api.submitLeave(request);
    await db.saveLeave(saved);
    return saved;
  }
}
