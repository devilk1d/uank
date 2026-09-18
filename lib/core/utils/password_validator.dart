/// Password complexity validator utility for UANK.
///
/// Rules:
/// - Minimum 6 characters
/// - At least one uppercase letter (A-Z)
/// - At least one lowercase letter (a-z)
/// - At least one special character / symbol (e.g. =, -, @, #, $, !, %, etc.)
class PasswordValidator {
  static const int minLength = 6;

  /// Checks if password meets all complexity requirements.
  static bool isValid(String? password) {
    if (password == null) return false;
    return password.length >= minLength &&
        hasUppercase(password) &&
        hasLowercase(password) &&
        hasSpecialChar(password);
  }

  static bool hasMinLength(String password) => password.length >= minLength;
  static bool hasUppercase(String password) => RegExp(r'[A-Z]').hasMatch(password);
  static bool hasLowercase(String password) => RegExp(r'[a-z]').hasMatch(password);
  static bool hasSpecialChar(String password) => RegExp(r'[^a-zA-Z0-9]').hasMatch(password);

  /// Returns user-friendly validation error message or null if valid.
  static String? validate(String? value, {String requiredMessage = 'Password is required'}) {
    if (value == null || value.trim().isEmpty) {
      return requiredMessage;
    }
    if (value.length < minLength) {
      return 'Password must be at least 6 characters';
    }
    if (!hasUppercase(value)) {
      return 'Password must contain at least 1 uppercase letter (A-Z)';
    }
    if (!hasLowercase(value)) {
      return 'Password must contain at least 1 lowercase letter (a-z)';
    }
    if (!hasSpecialChar(value)) {
      return 'Password must contain at least 1 special character (e.g. =, -, @, #)';
    }
    return null;
  }
}
