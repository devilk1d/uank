import 'package:flutter_test/flutter_test.dart';
import 'package:uank/core/utils/password_validator.dart';

void main() {
  group('PasswordValidator Unit Tests', () {
    test('rejects empty or null password', () {
      expect(PasswordValidator.validate(null), 'Password is required');
      expect(PasswordValidator.validate(''), 'Password is required');
      expect(PasswordValidator.validate('   '), 'Password is required');
      expect(PasswordValidator.isValid(''), false);
    });

    test('rejects password shorter than 6 characters', () {
      expect(PasswordValidator.validate('Aa=1'), 'Password must be at least 6 characters');
      expect(PasswordValidator.isValid('Aa=1'), false);
    });

    test('rejects password without uppercase letter', () {
      expect(PasswordValidator.validate('password=1'), 'Password must contain at least 1 uppercase letter (A-Z)');
      expect(PasswordValidator.isValid('password=1'), false);
    });

    test('rejects password without lowercase letter', () {
      expect(PasswordValidator.validate('PASSWORD=1'), 'Password must contain at least 1 lowercase letter (a-z)');
      expect(PasswordValidator.isValid('PASSWORD=1'), false);
    });

    test('rejects password without special character', () {
      expect(PasswordValidator.validate('Password123'), 'Password must contain at least 1 special character (e.g. =, -, @, #)');
      expect(PasswordValidator.isValid('Password123'), false);
    });

    test('accepts valid passwords with various special characters (=, -, _, @, #, etc.)', () {
      expect(PasswordValidator.validate('Pass=1'), null);
      expect(PasswordValidator.validate('Pass-1'), null);
      expect(PasswordValidator.validate('Pass_123'), null);
      expect(PasswordValidator.validate('Secure@2026'), null);
      expect(PasswordValidator.validate('Uank#2026!'), null);
      expect(PasswordValidator.validate('Admin+99'), null);

      expect(PasswordValidator.isValid('Pass=1'), true);
      expect(PasswordValidator.isValid('Pass-1'), true);
      expect(PasswordValidator.isValid('Secure@2026'), true);
    });
  });
}
