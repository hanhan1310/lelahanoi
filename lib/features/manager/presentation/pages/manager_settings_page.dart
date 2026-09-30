import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lelahanoi/core/l10n/language_cubit.dart';
import 'package:lelahanoi/core/theme/app_colors.dart';
import 'package:lelahanoi/core/widgets/custom_toast.dart';
import 'package:lelahanoi/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:lelahanoi/features/manager/presentation/bloc/manager_settings_cubit.dart';

class ManagerSettingsPage extends StatelessWidget {
  const ManagerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageCubit>();
    final t = language.strings;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text(t.settings,
              style: GoogleFonts.merriweather(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: BlocListener<ManagerSettingsCubit, ManagerSettingsState>(
        listenWhen: (previous, current) =>
            (previous.status == ManagerSettingsStatus.saving &&
                current.status == ManagerSettingsStatus.ready) ||
            current.status == ManagerSettingsStatus.failure,
        listener: (context, state) {
          if (state.status == ManagerSettingsStatus.ready) {
            showToast('Đã lưu cài đặt', true);
          } else if (state.status == ManagerSettingsStatus.failure) {
            showToast('${t.errorSystem}: ${state.error}', false);
          }
        },
        child: BlocBuilder<ManagerSettingsCubit, ManagerSettingsState>(
          builder: (context, state) {
            if (state.status == ManagerSettingsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            final saving = state.status == ManagerSettingsStatus.saving;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _panel(children: [
                  Text(t.changeLanguage,
                      style: GoogleFonts.merriweather(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: language.currentCode,
                    items: LanguageCubit.supportedLanguages.entries
                        .map((entry) => DropdownMenuItem(
                            value: entry.key, child: Text(entry.value)))
                        .toList(),
                    onChanged: (code) {
                      if (code != null) language.setLanguage(code);
                    },
                  ),
                ]),
                const SizedBox(height: 12),
                _panel(children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.notifications),
                    subtitle: Text(t.reminderBeforeMinutes),
                    value: state.notificationsEnabled,
                    onChanged: context
                        .read<ManagerSettingsCubit>()
                        .setNotificationsEnabled,
                  ),
                  const SizedBox(height: 8),
                  Text('${t.reminderBeforeMinutes}: ${state.reminderMinutes}'),
                  Slider(
                    value: state.reminderMinutes.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '${state.reminderMinutes}',
                    onChanged: (value) => context
                        .read<ManagerSettingsCubit>()
                        .setReminderMinutes(value.round()),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () => context.read<ManagerSettingsCubit>().save(),
                        child: Text(saving ? '...' : t.saveSettings))),
                const SizedBox(height: 12),
                SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                        onPressed: () => context.read<AuthCubit>().logout(),
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        label: Text(t.logout,
                            style: const TextStyle(color: Colors.redAccent)))),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _panel({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
