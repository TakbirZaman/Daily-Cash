import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/strings.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _isSignUp = true;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSignUp) {
      await widget.controller.signUp(_name.text, _email.text, _password.text);
    } else {
      await widget.controller.signIn(_email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController c = widget.controller;

    return Scaffold(
      body: ListenableBuilder(
        listenable: c,
        builder: (BuildContext context, Widget? _) {
          return SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                      28, MediaQuery.of(context).padding.top + 56, 28, 40),
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('৳',
                          style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: AppColors.income)),
                      const SizedBox(height: 8),
                      Text(S.t('app_name'),
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                      const SizedBox(height: 6),
                      Text(S.t('tagline'),
                          style: const TextStyle(fontSize: 15, color: Colors.white70)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(_isSignUp ? S.t('create_account') : S.t('welcome_back'),
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: context.pal.text)),
                      const SizedBox(height: 20),
                      if (_isSignUp) ...<Widget>[
                        _field(_name, S.t('your_name'), Icons.person_outline,
                            action: TextInputAction.next,
                            caps: TextCapitalization.words),
                        const SizedBox(height: 14),
                      ],
                      _field(_email, S.t('email'), Icons.mail_outline,
                          type: TextInputType.emailAddress,
                          action: TextInputAction.next),
                      const SizedBox(height: 14),
                      _field(_password, S.t('password'), Icons.lock_outline,
                          obscure: _hidePassword,
                          action: TextInputAction.done,
                          suffix: IconButton(
                            icon: Icon(_hidePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _hidePassword = !_hidePassword),
                          ),
                          onSubmit: (_) => _submit()),
                      if (!_isSignUp)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: c.isLoading ? null : () => c.resetPassword(_email.text),
                            child: Text(S.t('forgot')),
                          ),
                        ),
                      if (c.info != null) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(c.info!,
                            style: const TextStyle(
                                color: AppColors.income, fontWeight: FontWeight.w600)),
                      ],
                      if (c.error != null) ...<Widget>[
                        const SizedBox(height: 14),
                        Text(c.error!,
                            style: const TextStyle(
                                color: AppColors.expense,
                                fontWeight: FontWeight.w600)),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.income,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: c.isLoading ? null : _submit,
                          child: c.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : Text(_isSignUp ? S.t('sign_up') : S.t('log_in'),
                                  style: const TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: c.isLoading
                            ? null
                            : () {
                                c.error = null;
                                c.info = null;
                                setState(() => _isSignUp = !_isSignUp);
                              },
                        child: Text(_isSignUp
                            ? S.t('have_account')
                            : S.t('new_here')),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    TextCapitalization caps = TextCapitalization.none,
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onSubmit,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: context.pal.text),
      keyboardType: type,
      textInputAction: action,
      textCapitalization: caps,
      obscureText: obscure,
      onSubmitted: onSubmit,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        filled: true,
        fillColor: context.pal.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
