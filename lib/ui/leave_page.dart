/// Created by Anu Alias on 17-11-2026.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../state/app_state.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  String type = 'Casual';
  DateTime? start, end;
  final reason = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Leave application')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New request',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      labelText: 'Leave type',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Casual', 'Sick']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => type = v!),
                  ),
                  const SizedBox(height: 12),
                  _dateField(
                    'Start date',
                    start,
                    (d) => setState(() => start = d),
                  ),
                  const SizedBox(height: 12),
                  _dateField('End date', end, (d) => setState(() => end = d)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reason,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: saving ? null : () => _submit(s),
                      child: saving
                          ? const CircularProgressIndicator()
                          : const Text('Submit leave request'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'My leave requests',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (s.leaves.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No leave requests available.'),
            )
          else
            ...s.leaves.map(
              (l) => Card(
                child: ListTile(
                  title: Text(
                    '${l.type} • ${l.startDate.day}/${l.startDate.month}/${l.startDate.year} – ${l.endDate.day}/${l.endDate.month}/${l.endDate.year}',
                  ),
                  subtitle: Text(l.reason),
                  trailing: Text(
                    l.status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: l.status == 'Approved'
                          ? Colors.green
                          : l.status == 'Rejected'
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPicked,
  ) => InkWell(
    onTap: () async {
      final now = DateTime.now();
      final d = await showDatePicker(
        context: context,
        initialDate: value ?? DateTime(now.year, now.month, now.day),
        firstDate: DateTime(now.year, now.month, now.day),
        lastDate: DateTime(now.year + 3),
      );
      if (d != null) onPicked(d);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.calendar_month),
      ),
      child: Text(
        value == null ? 'Select date' : DateFormat('dd MMM yyyy').format(value),
      ),
    ),
  );

  Future<void> _submit(AppState s) async {
    if (start == null || end == null) {
      _message('Select both dates.');
      return;
    }
    setState(() => saving = true);
    try {
      await s.submitLeave(type, start!, end!, reason.text);
      if (mounted) {
        _message('Leave request submitted.');
        Navigator.pop(context);
      }
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _message(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}
