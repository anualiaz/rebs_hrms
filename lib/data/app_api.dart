/// Created by Anu Alias on 17-11-2026.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_models.dart';

class HrmsApi {
  final String baseUrl;
  final http.Client client;

  HrmsApi({required this.baseUrl, http.Client? client})
    : client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<dynamic> _get(String path) async {
    final r = await client.get(_uri(path)).timeout(const Duration(seconds: 8));
    if (r.statusCode >= 400) throw Exception(_error(r));
    return jsonDecode(r.body);
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final r = await client
        .post(
          _uri(path),
          headers: {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));
    if (r.statusCode >= 400) throw ApiException(r.statusCode, _error(r));
    return jsonDecode(r.body);
  }

  String _error(http.Response r) {
    try {
      return jsonDecode(r.body)['message'] ??
          'Request failed (${r.statusCode})';
    } catch (_) {
      return 'Request failed (${r.statusCode})';
    }
  }

  Future<Employee> employee() async =>
      Employee.fromJson(await _get('/employee/me'));

  Future<List<AttendanceEvent>> attendance() async =>
      ((await _get('/attendance')) as List)
          .map((e) => AttendanceEvent.fromMap({...e, 'status': 'synced'}))
          .toList();

  Future<Map<String, dynamic>> submitEvent(AttendanceEvent e) async =>
      Map<String, dynamic>.from(await _post('/attendance/events', e.toMap()));

  Future<int> leaveBalance() async =>
      (await _get('/leave/balance'))['available'] as int;

  Future<List<LeaveRequest>> leaveRequests() async =>
      ((await _get('/leave/requests')) as List)
          .map((e) => LeaveRequest.fromJson(e))
          .toList();

  Future<LeaveRequest> submitLeave(LeaveRequest l) async =>
      LeaveRequest.fromJson(await _post('/leave/requests', l.toJson()));
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
