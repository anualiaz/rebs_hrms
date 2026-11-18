/// Created by Anu Alias on 17-11-2026.

enum AttendanceStatus { notCheckedIn, checkedIn, checkedOut }

enum SyncStatus { pending, synced, rejected }

class Employee {
  final String id, name, department, officeName;
  final double officeLat, officeLng;
  final String timezone;

  const Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.officeName,
    required this.officeLat,
    required this.officeLng,
    this.timezone = 'Asia/Kolkata',
  });

  factory Employee.fromJson(Map<String, dynamic> j) => Employee(
    id: j['id'],
    name: j['name'],
    department: j['department'],
    officeName: j['officeName'] ?? 'Main Office',
    officeLat: (j['officeLat'] as num).toDouble(),
    officeLng: (j['officeLng'] as num).toDouble(),
    timezone: j['timezone'] ?? 'Asia/Kolkata',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'department': department,
    'officeName': officeName,
    'officeLat': officeLat,
    'officeLng': officeLng,
    'timezone': timezone,
  };
}

class AttendanceEvent {
  final String id, type, status;
  final DateTime timestamp;
  final double latitude, longitude;
  final String? message;

  const AttendanceEvent({
    required this.id,
    required this.type,
    required this.status,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.message,
  });

  factory AttendanceEvent.fromMap(Map<String, dynamic> m) => AttendanceEvent(
    id: m['id'],
    type: m['type'],
    status: m['status'],
    timestamp: DateTime.parse(m['timestamp']),
    latitude: (m['latitude'] as num).toDouble(),
    longitude: (m['longitude'] as num).toDouble(),
    message: m['message'],
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'message': message,
  };

  AttendanceEvent withStatus(String s, [String? msg]) => AttendanceEvent(
    id: id,
    type: type,
    status: s,
    timestamp: timestamp,
    latitude: latitude,
    longitude: longitude,
    message: msg,
  );
}

class LeaveRequest {
  final String id, type, reason, status;
  final DateTime startDate, endDate;

  const LeaveRequest({
    required this.id,
    required this.type,
    required this.reason,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> j) => LeaveRequest(
    id: j['id'],
    type: j['type'],
    reason: j['reason'],
    status: j['status'],
    startDate: DateTime.parse(j['startDate']),
    endDate: DateTime.parse(j['endDate']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'reason': reason,
    'status': status,
    'startDate': _day(startDate),
    'endDate': _day(endDate),
  };
}

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
