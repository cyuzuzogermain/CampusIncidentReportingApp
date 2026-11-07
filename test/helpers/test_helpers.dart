import 'package:bloc_test/bloc_test.dart';
import 'package:campus_incident_app/core/constants/incident_category.dart';
import 'package:campus_incident_app/core/constants/incident_status.dart';
import 'package:campus_incident_app/data/models/app_user.dart';
import 'package:campus_incident_app/data/models/incident.dart';
import 'package:campus_incident_app/data/models/status_change.dart';
import 'package:campus_incident_app/data/repositories/auth_repository.dart';
import 'package:campus_incident_app/data/repositories/incident_repository.dart';
import 'package:campus_incident_app/logic/cubits/auth/auth_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockIncidentRepository extends Mock implements IncidentRepository {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

final DateTime testDate = DateTime(2026, 11, 3, 9, 30);

final AppUser testStudent = AppUser(
  uid: 'student-1',
  name: 'Jane Student',
  email: 'jane@alustudent.com',
  role: UserRole.student,
  department: 'Computer Science',
  createdAt: testDate,
);

final AppUser otherStudent = AppUser(
  uid: 'student-2',
  name: 'Omar Classmate',
  email: 'omar@alustudent.com',
  role: UserRole.student,
  department: 'Engineering',
  createdAt: testDate,
);

final AppUser testStaff = AppUser(
  uid: 'staff-1',
  name: 'Sam Staff',
  email: 'sam@alueducation.com',
  role: UserRole.staff,
  department: 'Estates',
  createdAt: testDate,
);

Incident buildIncident({
  String id = 'incident-1',
  String title = 'Broken light',
  String description = 'The corridor light keeps flickering.',
  IncidentCategory category = IncidentCategory.electricity,
  String location = 'Library',
  IncidentStatus status = IncidentStatus.submitted,
  String? imageUrl,
  DateTime? createdAt,
  List<String> affectedUserIds = const [],
}) {
  final created = createdAt ?? testDate;
  return Incident(
    id: id,
    title: title,
    description: description,
    category: category,
    location: location,
    imageUrl: imageUrl,
    status: status,
    reporterId: testStudent.uid,
    reporterName: testStudent.name,
    createdAt: created,
    updatedAt: created,
    statusHistory: [
      StatusChange(
        status: IncidentStatus.submitted,
        changedBy: testStudent.uid,
        changedByName: testStudent.name,
        timestamp: created,
      ),
    ],
    affectedUserIds: affectedUserIds,
  );
}

/// Call once from `setUpAll` before using `any()` with these types.
void registerTestFallbacks() {
  registerFallbackValue(IncidentStatus.submitted);
  registerFallbackValue(IncidentCategory.facilities);
  registerFallbackValue(testStudent);
}
