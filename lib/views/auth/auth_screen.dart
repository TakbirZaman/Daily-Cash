import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../controllers/auth_controller.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_input.dart';
import '../../core/widgets/status_message.dart';
import 'reset_password_sheet.dart';

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

  Future<void> _forgot() async {
    FocusScope.of(context).unfocus();
    final bool sent = await widget.controller.sendResetCode(_email.text);
    if (!sent || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext _) =>
          ResetPasswordSheet(controller: widget.controller, email: _email.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;
    final AuthController c = widget.controller;

    return Scaffold(
      body: ListenableBuilder(
        listenable: c,
        builder: (BuildContext context, Widget? _) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.fromLTRB(
                      Space.x24, MediaQuery.of(context).padding.top + Space.x48, Space.x24, Space.x32),
                  decoration: BoxDecoration(color: pal.header, borderRadius: Rad.bottom(Rad.r24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 56,
                        height: 56,
                        decoration:
                            const BoxDecoration(color: Brand.income, shape: BoxShape.circle),
                        child: const Center(
                          child: PhosphorIcon(PhosphorIconsRegular.wallet,
                              size: 32, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: Space.x16),
                      Text(S.t('app_name'), style: AppText.heading4(pal.onHeader)),
                      const SizedBox(height: Space.x8),
                      Text(S.t('tagline'), style: AppText.body6(pal.onHeaderMuted)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Space.x24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(_isSignUp ? S.t('create_account') : S.t('welcome_back'),
                          style: AppText.heading5(pal.text)),
                      const SizedBox(height: Space.x24),
                      if (_isSignUp) ...<Widget>[
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          style: AppText.body3(pal.text),
                          decoration: appInput(context,
                              label: S.t('your_name'), prefixIcon: PhosphorIconsRegular.user),
                        ),
                        const SizedBox(height: Space.x12),
                      ],
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: AppText.body3(pal.text),
                        decoration: appInput(context,
                            label: S.t('email'), prefixIcon: PhosphorIconsRegular.envelope),
                      ),
                      const SizedBox(height: Space.x12),
                      TextField(
                        controller: _password,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        style: AppText.body3(pal.text),
                        decoration: appInput(
                          context,
                          label: S.t('password'),
                          prefixIcon: PhosphorIconsRegular.lockSimple,
                          suffixIcon: IconButton(
                            icon: PhosphorIcon(
                              _hidePassword ? PhosphorIconsRegular.eye : PhosphorIconsRegular.eyeSlash,
                              size: 24,
                              color: pal.muted,
                            ),
                            onPressed: () => setState(() => _hidePassword = !_hidePassword),
                          ),
                        ),
                      ),
                      if (!_isSignUp)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(44, 44),
                              foregroundColor: pal.incomeText,
                              textStyle: AppText.buttonSm(),
                            ),
                            onPressed: c.isLoading ? null : _forgot,
                            child: Text(S.t('forgot')),
                          ),
                        ),
                      if (c.info != null) ...<Widget>[
                        const SizedBox(height: Space.x12),
                        StatusMessage.success(c.info!),
                      ],
                      if (c.error != null) ...<Widget>[
                        const SizedBox(height: Space.x12),
                        StatusMessage.error(c.error!),
                      ],
                      const SizedBox(height: Space.x24),
                      AppButton(
                        label: _isSignUp ? S.t('sign_up') : S.t('log_in'),
                        loading: c.isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: Space.x8),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 48),
                          foregroundColor: pal.text,
                          textStyle: AppText.buttonSm(),
                        ),
                        onPressed: c.isLoading
                            ? null
                            : () {
                                c.clearMessages();
                                setState(() => _isSignUp = !_isSignUp);
                              },
                        child: Text(_isSignUp ? S.t('have_account') : S.t('new_here')),
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
}
