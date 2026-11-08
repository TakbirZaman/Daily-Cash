import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../controllers/auth_controller.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_input.dart';
import '../../core/widgets/status_message.dart';

/// Shown only if a signed in user has no name saved yet.
class NameScreen extends StatefulWidget {
  const NameScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;
    final AuthController c = widget.controller;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: c,
          builder: (BuildContext context, Widget? _) {
            return Padding(
              padding: const EdgeInsets.all(Space.x24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(S.t('name_title'), style: AppText.heading4(pal.text)),
                  const SizedBox(height: Space.x8),
                  Text(S.t('name_sub'), style: AppText.body6(pal.muted)),
                  const SizedBox(height: Space.x24),
                  TextField(
                    controller: _name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    style: AppText.body3(pal.text),
                    onSubmitted: (_) => c.saveName(_name.text),
                    decoration: appInput(context,
                        label: S.t('your_name'), prefixIcon: PhosphorIconsRegular.user),
                  ),
                  if (c.error != null) ...<Widget>[
                    const SizedBox(height: Space.x12),
                    StatusMessage.error(c.error!),
                  ],
                  const SizedBox(height: Space.x24),
                  AppButton(
                    label: S.t('continue'),
                    loading: c.isLoading,
                    onPressed: () => c.saveName(_name.text),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
