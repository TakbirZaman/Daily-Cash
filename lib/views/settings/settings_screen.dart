import 'package:flutter/material.dart';

import '../../core/l10n/strings.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/app_bar.dart';
import '../../core/widgets/app_choice_chip.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _group(AppPalette pal, String title, List<Widget> chips) {
    return Container(
      padding: const EdgeInsets.all(Space.x16),
      decoration: BoxDecoration(color: pal.card, borderRadius: Rad.all(Rad.r16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppText.title3(pal.text)),
          const SizedBox(height: Space.x12),
          Wrap(spacing: Space.x8, runSpacing: Space.x8, children: chips),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;
    final AppSettings settings = AppSettings.instance;

    return Scaffold(
      appBar: appBarFor(context, S.t('settings')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (BuildContext context, Widget? _) {
          return ListView(
            padding: const EdgeInsets.all(Space.x24),
            children: <Widget>[
              _group(pal, S.t('language'), <Widget>[
                AppChoiceChip(
                  label: 'English',
                  selected: !settings.isBangla,
                  onTap: () => settings.setBangla(false),
                ),
                AppChoiceChip(
                  label: 'বাংলা',
                  selected: settings.isBangla,
                  onTap: () => settings.setBangla(true),
                ),
              ]),
              const SizedBox(height: Space.x16),
              _group(pal, S.t('theme'), <Widget>[
                AppChoiceChip(
                  label: S.t('theme_system'),
                  selected: settings.themeMode == ThemeMode.system,
                  onTap: () => settings.setThemeMode(ThemeMode.system),
                ),
                AppChoiceChip(
                  label: S.t('theme_light'),
                  selected: settings.themeMode == ThemeMode.light,
                  onTap: () => settings.setThemeMode(ThemeMode.light),
                ),
                AppChoiceChip(
                  label: S.t('theme_dark'),
                  selected: settings.themeMode == ThemeMode.dark,
                  onTap: () => settings.setThemeMode(ThemeMode.dark),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }
}
