import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/strings.dart';

/// Shown only if a signed-in user has no name saved yet.
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
    final AuthController c = widget.controller;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: c,
          builder: (BuildContext context, Widget? _) {
            return Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(S.t('name_title'),
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: context.pal.text)),
                  const SizedBox(height: 8),
                  Text(S.t('name_sub'),
                      style: TextStyle(fontSize: 15, color: context.pal.muted)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _name,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(color: context.pal.text),
                    onSubmitted: (_) => c.saveName(_name.text),
                    decoration: InputDecoration(
                      labelText: S.t('your_name'),
                      prefixIcon: const Icon(Icons.person_outline),
                      filled: true,
                      fillColor: context.pal.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (c.error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(c.error!,
                        style: const TextStyle(
                            color: AppColors.expense, fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.income,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: c.isLoading ? null : () => c.saveName(_name.text),
                      child: Text(S.t('continue'),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ),
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
