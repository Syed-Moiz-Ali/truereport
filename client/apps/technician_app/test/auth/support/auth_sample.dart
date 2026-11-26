import 'package:flutter/material.dart';
import 'package:technician_app/src/features/auth/signin/technician_sign_in_view.dart';

/// Test-only strings for the sign-in audit. The production view reads the same
/// backend keys; these samples mirror the English catalog and a realistic
/// Arabic translation so RTL can be exercised without a backend.
class PreviewAuthData {
  const PreviewAuthData({required this.arabic});

  final bool arabic;

  Map<String, String> get messages => arabic
      ? const <String, String>{
          'technicianSignInHeadline': 'كل فحص يبدأ بشكل صحيح.',
          'technicianSignInTagline': 'تقارير فحص المركبات للورش الشريكة.',
          'technicianSignInSheetTitle': 'تسجيل دخول الفني',
          'technicianSignInSheetBody': 'استخدم الحساب الذي أنشأه مسؤول الورشة.',
          'emailLabel': 'البريد الإلكتروني',
          'passwordLabel': 'كلمة المرور',
          'twoFactorLabel': 'رمز المصادقة',
          'technicianEmailHint': 'name@workshop.com',
          'technicianPasswordHint': 'أدخل كلمة المرور',
          'signInButton': 'تسجيل الدخول',
          'verifyButton': 'تحقق',
          'signingIn': 'جارٍ تسجيل الدخول…',
          'technicianNeedTechnicianAccess': 'تحتاج إلى دخول الفني؟',
          'technicianContactAdmin': 'تواصل مع مسؤول الورشة.',
          'technicianSecurityLine': 'للموظفين المعتمدين فقط',
          'showPassword': 'إظهار كلمة المرور',
          'hidePassword': 'إخفاء كلمة المرور',
          'invalidCredentials': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
          'requiredField': 'هذا الحقل مطلوب.',
          'invalidEmail': 'أدخل بريدًا إلكترونيًا صالحًا.',
        }
      : const <String, String>{
          'technicianSignInHeadline': 'Every inspection, started right.',
          'technicianSignInTagline':
              'Vehicle inspection reports for partner workshops.',
          'technicianSignInSheetTitle': 'Technician sign in',
          'technicianSignInSheetBody':
              'Use the account your workshop admin created.',
          'emailLabel': 'Email',
          'passwordLabel': 'Password',
          'twoFactorLabel': 'Authentication code',
          'technicianEmailHint': 'name@workshop.com',
          'technicianPasswordHint': 'Enter your password',
          'signInButton': 'Sign in',
          'verifyButton': 'Verify',
          'signingIn': 'Signing in…',
          'technicianNeedTechnicianAccess': 'Need technician login?',
          'technicianContactAdmin': 'Contact your workshop admin.',
          'technicianSecurityLine': 'Authorised workshop staff only',
          'showPassword': 'Show password',
          'hidePassword': 'Hide password',
          'invalidCredentials': 'Email or password is incorrect.',
          'requiredField': 'This field is required.',
          'invalidEmail': 'Enter a valid email address.',
        };

  /// Localized string for a key, falling back to the key so a missing sample
  /// can never paint an empty control.
  String message(String key) => messages[key] ?? key;

  String get email => 'omar.haddad@truereport.test';
  String get password => 'baydoor-pass';
  String get code => '482913';
}

enum PreviewAuthState { normal, challenge, error, submitting }

/// Test-only fixture that mounts the production Bay Door view with dummy
/// controllers and validators. The tests provide the MaterialApp and strings.
class AuthPreviewScreen extends StatefulWidget {
  const AuthPreviewScreen({required this.data, required this.state, super.key});

  final PreviewAuthData data;
  final PreviewAuthState state;

  @override
  State<AuthPreviewScreen> createState() => _AuthPreviewScreenState();
}

class _AuthPreviewScreenState extends State<AuthPreviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _codeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    final state = widget.state;
    if (state != PreviewAuthState.normal) {
      _email.text = widget.data.email;
    }
    if (state == PreviewAuthState.error ||
        state == PreviewAuthState.submitting) {
      _password.text = widget.data.password;
    }
    if (state == PreviewAuthState.challenge) {
      _code.text = widget.data.code;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final strings = widget.data;
    return TechnicianSignInView(
      emailController: _email,
      passwordController: _password,
      codeController: _code,
      formKey: _formKey,
      emailFocus: _emailFocus,
      passwordFocus: _passwordFocus,
      codeFocus: _codeFocus,
      challenge: state == PreviewAuthState.challenge,
      submitting: state == PreviewAuthState.submitting,
      errorText: state == PreviewAuthState.error
          ? strings.message('invalidCredentials')
          : null,
      onSubmit: () => _formKey.currentState?.validate(),
      onValidateEmail: (value) {
        if (value == null || value.trim().isEmpty) {
          return strings.message('requiredField');
        }
        return value.contains('@') ? null : strings.message('invalidEmail');
      },
      onValidateRequired: (value) => value == null || value.trim().isEmpty
          ? strings.message('requiredField')
          : null,
      onValidateCode: (value) => value == null || value.trim().isEmpty
          ? strings.message('requiredField')
          : null,
    );
  }
}
