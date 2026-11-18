/// Created by Anu Alias on 17-11-2026.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/app_repository.dart';
import '../models/app_models.dart';

class AppState extends ChangeNotifier {
  final HrmsRepository repo;

  AppState(this.repo);

  Employee? employee;
  int leaveBalance = 0;
  List<AttendanceEvent> attendance = [];
  List<LeaveRequest> leaves = [];
  bool loading = true, syncing = false, offline = false;
  String? error;
  StreamSubscription? _connectivity;

  Future<void> initialize() async {
    _connectivity = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final wasOffline = offline;
      offline = results.contains(ConnectivityResult.none);
      if (wasOffline && !offline) await syncNow();
      notifyListeners();
    });
    await refresh();
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      employee = await repo.loadEmployee();
      leaveBalance = await repo.loadBalance();
      attendance = await repo.loadAttendance();
      leaves = await repo.loadLeaves();
      offline = !(await repo.online);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> attendanceAction(String type, double lat, double lng) async {
    await repo.recordAttendance(type, lat, lng);
    attendance = await repo.loadAttendance();
    notifyListeners();
    await syncNow();
  }

  Future<void> syncNow() async {
    if (syncing) return;
    syncing = true;
    notifyListeners();
    try {
      await repo.sync();
      attendance = await repo.loadAttendance();
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  Future<void> submitLeave(
    String type,
    DateTime start,
    DateTime end,
    String reason,
  ) async {
    final l = await repo.applyLeave(
      type,
      start,
      end,
      reason,
      leaveBalance,
      leaves,
    );
    leaves = [l, ...leaves];
    leaveBalance -= end.difference(start).inDays + 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivity?.cancel();
    super.dispose();
  }
}
