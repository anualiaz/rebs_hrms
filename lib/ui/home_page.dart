/// Created by Anu Alias on 17-11-2026.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';
import '../models/app_models.dart';
import 'leave_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('REBS HRMS'),
        actions: [
          IconButton(onPressed: s.refresh, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: s.syncNow,
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Now',
          ),
        ],
      ),
      body: s.loading
          ? const Center(child: CircularProgressIndicator())
          : s.error != null && s.employee == null
          ? Center(child: Text(s.error!))
          : RefreshIndicator(
              onRefresh: s.refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (s.offline)
                    const _Notice(
                      text: 'You are offline. Cached information is shown.',
                      icon: Icons.wifi_off,
                    ),
                  if (s.employee != null) _EmployeeCard(employee: s.employee!),
                  _AttendanceCard(state: s),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          title: 'Leave balance',
                          value: '${s.leaveBalance} days',
                          icon: Icons.event_available,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Metric(
                          title: 'Pending sync',
                          value:
                              '${s.attendance.where((e) => e.status == 'pending').length}',
                          icon: Icons.cloud_upload,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent attendance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: s.syncNow,
                        child: const Text('Sync Now'),
                      ),
                    ],
                  ),
                  if (s.attendance.isEmpty)
                    const _Empty(text: 'No attendance records yet.')
                  else
                    ...s.attendance
                        .take(5)
                        .map(
                          (e) => Card(
                            child: ListTile(
                              leading: Icon(
                                e.type == 'check_in'
                                    ? Icons.login
                                    : Icons.logout,
                              ),
                              title: Text(
                                e.type == 'check_in' ? 'Check-in' : 'Check-out',
                              ),
                              subtitle: Text(
                                DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(e.timestamp),
                              ),
                              trailing: _Status(status: e.status),
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LeavePage()),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Apply for leave'),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Employee employee;

  const _EmployeeCard({required this.employee});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const CircleAvatar(radius: 27, child: Icon(Icons.person, size: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('${employee.id} • ${employee.department}'),
                Text(
                  employee.officeName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _AttendanceCard extends StatelessWidget {
  final AppState state;

  const _AttendanceCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final events =
        state.attendance
            .where(
              (e) =>
                  e.timestamp.year == today.year &&
                  e.timestamp.month == today.month &&
                  e.timestamp.day == today.day &&
                  e.status != 'rejected',
            )
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    // final checkedIn=events.any((e)=>e.type=='check_in'), checkedOut=events.any((e)=>e.type=='check_out');
    // final status=!checkedIn?'Not Checked In':checkedOut?'Checked Out':'Checked In';
    // final checkIns=events.where((e)=>e.type=='check_in').toList();
    // final checkOuts=events.where((e)=>e.type=='check_out').toList();
    final lastEvent = events.isEmpty ? null : events.last;

    final canCheckIn = lastEvent == null || lastEvent.type == 'check_out';
    final canCheckOut = lastEvent?.type == 'check_in';

    final status = lastEvent == null
        ? 'Not Checked In'
        : lastEvent.type == 'check_in'
        ? 'Checked In'
        : 'Checked Out';

    final checkIns = events.where((e) => e.type == 'check_in').toList();
    final checkOuts = events.where((e) => e.type == 'check_out').toList();

    final ci = checkIns.isEmpty ? null : checkIns.first;
    final co = checkOuts.isEmpty ? null : checkOuts.last;
    // final ci=checkIns.isEmpty?null:checkIns.first;
    // final co=checkOuts.isEmpty?null:checkOuts.first;
    final elapsed = ci == null
        ? Duration.zero
        : (co?.timestamp ?? DateTime.now()).difference(ci.timestamp);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Today’s attendance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(child: Chip(label: Text(status))),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _TimeCell(
                    label: 'Check-in',
                    value: ci == null
                        ? '--'
                        : DateFormat('hh:mm a').format(ci.timestamp),
                  ),
                ),
                Expanded(
                  child: _TimeCell(
                    label: 'Check-out',
                    value: co == null
                        ? '--'
                        : DateFormat('hh:mm a').format(co.timestamp),
                  ),
                ),
                Expanded(
                  child: _TimeCell(
                    label: 'Duration',
                    value:
                        '${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}m',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (canCheckIn && !state.syncing)
                        ? () => _mark(context, 'check_in')
                        : null,
                    icon: const Icon(Icons.login),
                    label: const Text('Check In'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (canCheckOut && !state.syncing)
                        ? () => _mark(context, 'check_out')
                        : null,
                    icon: const Icon(Icons.logout),
                    label: const Text('Check Out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mark(BuildContext context, String type) async {
    final s = context.read<AppState>();
    try {
      final permission = await Geolocator.checkPermission();
      var p = permission;
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
      if (p == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. Enable it in Settings.',
        );
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled.');
      }
      final pos = await Geolocator.getCurrentPosition();
      final emp = s.employee!;
      final distance = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        emp.officeLat,
        emp.officeLng,
      );
      if (distance > 200) {
        throw Exception(
          'You are ${distance.round()} metres from the office. Attendance is allowed within 200 metres.',
        );
      }
      await s.attendanceAction(type, pos.latitude, pos.longitude);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Attendance saved.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }
}

class _Metric extends StatelessWidget {
  final String title, value;
  final IconData icon;

  const _Metric({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(title),
        ],
      ),
    ),
  );
}

class _TimeCell extends StatelessWidget {
  final String label, value;

  const _TimeCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

class _Status extends StatelessWidget {
  final String status;

  const _Status({required this.status});

  @override
  Widget build(BuildContext context) => Text(
    status.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: status == 'synced'
          ? Colors.green
          : status == 'rejected'
          ? Colors.red
          : Colors.orange,
    ),
  );
}

class _Notice extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Notice({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.amber.shade50,
    child: ListTile(leading: Icon(icon), title: Text(text)),
  );
}

class _Empty extends StatelessWidget {
  final String text;

  const _Empty({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Center(child: Text(text)),
  );
}
