class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _vin = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'error.email.required';
    }
    if (!_email.hasMatch(text)) {
      return 'error.email.invalid';
    }
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').length < 8) {
      return 'error.password.tooShort';
    }
    return null;
  }

  static String? vin(String? value) {
    final text = (value ?? '').trim().toUpperCase();
    if (text.isEmpty) {
      return 'error.vin.required';
    }
    if (!_vin.hasMatch(text)) {
      return 'error.vin.invalid';
    }
    return null;
  }
}
