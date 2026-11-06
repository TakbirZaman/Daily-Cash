import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/l10n/strings.dart';
import '../../core/settings/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _choice(BuildContext context, String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : context.pal.text)),
      selected: selected,
      selectedColor: AppColors.income,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppPalette pal = context.pal;
    final AppSettings settings = AppSettings.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.t('settings'), style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListenableBuilder(
        listenable: settings,
        builder: (BuildContext context, Widget? _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: pal.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(S.t('language'),
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800, color: pal.text)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: <Widget>[
                        _choice(context, 'English', !settings.isBangla,
                            () => settings.setBangla(false)),
                        _choice(context, 'বাংলা', settings.isBangla,
                            () => settings.setBangla(true)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: pal.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(S.t('theme'),
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800, color: pal.text)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: <Widget>[
                        _choice(context, S.t('theme_system'),
                            settings.themeMode == ThemeMode.system,
                            () => settings.setThemeMode(ThemeMode.system)),
                        _choice(context, S.t('theme_light'),
                            settings.themeMode == ThemeMode.light,
                            () => settings.setThemeMode(ThemeMode.light)),
                        _choice(context, S.t('theme_dark'),
                            settings.themeMode == ThemeMode.dark,
                            () => settings.setThemeMode(ThemeMode.dark)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
