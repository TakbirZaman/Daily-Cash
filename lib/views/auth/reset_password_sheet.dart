import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_input.dart';
import '../../core/widgets/status_message.dart';

/// Step 2 of "Forgot password": the code from the email plus a new password.
/// On success the user is signed in, so the auth gate takes over.
class ResetPasswordSheet extends StatefulWidget {
  const ResetPasswordSheet({super.key, required this.controller, required this.email});

  final AuthController controller;
  final String email;

  @override
  State<ResetPasswordSheet> createState() => _ResetPasswordSheetState();
}

class _ResetPasswordSheetState extends State<ResetPasswordSheet> {
  final TextEditingController _code = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final String? err = await widget.controller.confirmReset(
      widget.email,
      S.toEnglishDigits(_code.text),
      _password.text,
    );
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(color: pal.bg, borderRadius: Rad.top(Rad.r24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.x24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(S.t('reset_title'), style: AppText.heading6(pal.text)),
              const SizedBox(height: Space.x8),
              Text(S.t('reset_help'), style: AppText.body6(pal.muted)),
              const SizedBox(height: Space.x16),
              TextField(
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: AppText.body3(pal.text),
                decoration: appInput(context, label: S.t('reset_code')),
              ),
              const SizedBox(height: Space.x12),
              TextField(
                controller: _password,
                obscureText: true,
                style: AppText.body3(pal.text),
                decoration: appInput(context, label: S.t('new_password')),
                onSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: Space.x12),
                StatusMessage.error(_error!),
              ],
              const SizedBox(height: Space.x24),
              AppButton(label: S.t('reset_save'), loading: _busy, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
