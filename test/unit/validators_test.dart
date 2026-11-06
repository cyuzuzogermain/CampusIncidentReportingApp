import 'package:campus_incident_app/core/constants/incident_category.dart';
import 'package:campus_incident_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.required', () {
    test('rejects null, empty and whitespace', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });

    test('accepts text and names the field', () {
      expect(Validators.required('x'), isNull);
      expect(Validators.name(''), 'Name is required');
      expect(Validators.department(''), 'Department is required');
    });
  });

  group('Validators.email', () {
    test('requires a value', () {
      expect(Validators.email(''), 'Email is required');
    });

    test('rejects malformed addresses', () {
      for (final bad in [
        'jane',
        'jane@',
        'jane@uni',
        '@uni.edu',
        'a b@c.com',
      ]) {
        expect(
          Validators.email(bad),
          'Enter a valid email address',
          reason: bad,
        );
      }
    });

    test('accepts valid addresses', () {
      expect(Validators.email('jane@uni.edu'), isNull);
      expect(Validators.email(' jane.doe+1@alu.ac.rw '), isNull);
    });
  });

  group('Validators.password', () {
    test('requires at least 6 characters', () {
      expect(Validators.password(''), 'Password is required');
      expect(
        Validators.password('12345'),
        'Password must be at least 6 characters',
      );
      expect(Validators.password('123456'), isNull);
    });

    test('confirmPassword must match', () {
      expect(
        Validators.confirmPassword('', 'secret1'),
        'Please confirm your password',
      );
      expect(
        Validators.confirmPassword('secret2', 'secret1'),
        'Passwords do not match',
      );
      expect(Validators.confirmPassword('secret1', 'secret1'), isNull);
    });
  });

  group('Report fields', () {
    test('title is required and at most 60 characters', () {
      expect(Validators.title(''), 'Title is required');
      expect(Validators.title('a' * 60), isNull);
      expect(Validators.title('a' * 61), 'Title must be at most 60 characters');
    });

    test('description needs at least 10 characters', () {
      expect(Validators.description('too short'), isNotNull);
      expect(Validators.description('          '), isNotNull);
      expect(Validators.description('Long enough'), isNull);
    });

    test('location and category are required', () {
      expect(Validators.location(null), 'Please select a location');
      expect(Validators.location('Library'), isNull);
      expect(Validators.category(null), 'Please select a category');
      expect(Validators.category(IncidentCategory.water), isNull);
    });
  });
}
