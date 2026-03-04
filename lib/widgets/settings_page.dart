import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<AppSettings>(
      valueListenable: controller,
      builder: (context, settings, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F3EF),
          appBar: AppBar(
            title: Text(l10n.appTitleSettings),
            backgroundColor: const Color(0xFFF5F3EF),
            foregroundColor: Colors.black,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Section(
                title: l10n.sectionLanguage,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return DropdownMenu<String>(
                      initialSelection: settings.languageCode,
                      width: constraints.maxWidth,
                      textStyle: const TextStyle(color: Colors.black),
                      inputDecorationTheme: const InputDecorationTheme(
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      dropdownMenuEntries: [
                        DropdownMenuEntry(
                          value: '',
                          label: l10n.languageSystem,
                        ),
                        DropdownMenuEntry(
                          value: 'en',
                          label: l10n.languageEnglish,
                        ),
                        DropdownMenuEntry(
                          value: 'zh',
                          label: l10n.languageChinese,
                        ),
                      ],
                      onSelected: (value) {
                        controller.setLanguageCode(value ?? '');
                      },
                    );
                  },
                ),
              ),
              if (!Platform.isAndroid)
                _Section(
                  title: l10n.sectionAemeathSize,
                  child: _SliderRow(
                    label: l10n.labelSize,
                    value: settings.petScale,
                    min: 0.6,
                    max: 2.0,
                    divisions: 14,
                    format: (v) => '${(v * 100).round()}%',
                    onChanged: controller.setPetScale,
                  ),
                ),
              _Section(
                title: l10n.sectionRoamSpeed,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
                      _SliderRow(
                        label: l10n.labelDesktop,
                        value: settings.desktopRoamSpeed,
                        min: 60,
                        max: 320,
                        divisions: 13,
                        format: (v) => l10n.pxPerSecond(v.round()),
                        onChanged: controller.setDesktopRoamSpeed,
                      ),
                    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
                      const SizedBox(height: 12),
                    if (Platform.isAndroid || Platform.isIOS)
                      _SliderRow(
                        label: l10n.labelMobile,
                        value: settings.mobileRoamSpeed,
                        min: 10,
                        max: 320,
                        divisions: 31,
                        format: (v) => l10n.pxPerSecond(v.round()),
                        onChanged: controller.setMobileRoamSpeed,
                      ),
                  ],
                ),
              ),
              if (Platform.isAndroid)
                _Section(
                  title: l10n.sectionAndroidOverlay,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SliderRow(
                        label: l10n.labelOverlaySize,
                        value: settings.androidOverlayScale,
                        min: 0.1,
                        max: 2.0,
                        divisions: 19,
                        format: (v) => '${v.toStringAsFixed(1)}x',
                        onChanged: controller.setAndroidOverlayScale,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: settings.showOverlayDebug,
                        title: Text(l10n.showOverlayDebug),
                        contentPadding: EdgeInsets.zero,
                        onChanged: controller.setShowOverlayDebug,
                      ),
                    ],
                  ),
                ),
              if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
                _Section(
                  title: l10n.sectionStartup,
                  child: SwitchListTile.adaptive(
                    value: settings.launchAtStartup,
                    title: Text(l10n.launchAtStartup),
                    contentPadding: EdgeInsets.zero,
                    onChanged: controller.setLaunchAtStartup,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.black),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(format(value)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
