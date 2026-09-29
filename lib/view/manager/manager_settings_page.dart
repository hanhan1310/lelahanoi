import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lelahanoi/public/l10n/language_provider.dart';
import 'package:lelahanoi/public/widget/app_colors.dart';
import 'package:lelahanoi/public/widget/custom_toast.dart';
import 'package:lelahanoi/utils/auth_service.dart';
import 'package:lelahanoi/utils/firestore_service.dart';
import 'package:lelahanoi/utils/notification_service.dart';
import 'package:provider/provider.dart';

class ManagerSettingsPage extends StatefulWidget {
  const ManagerSettingsPage({super.key});

  @override
  State<ManagerSettingsPage> createState() => _ManagerSettingsPageState();
}

class _ManagerSettingsPageState extends State<ManagerSettingsPage> {
  final _service = FirestoreService();
  bool _loading = true;
  bool _notificationsEnabled = true;
  int _reminderMinutes = 15;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _service.getManagerSettings();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = settings['notifications_enabled'] as bool? ?? true;
      _reminderMinutes = settings['reminder_minutes'] as int? ?? 15;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _service.saveManagerSettings({
      'notifications_enabled': _notificationsEnabled,
      'reminder_minutes': _reminderMinutes,
    });
    if (!_notificationsEnabled) {
      await NotificationService.cancelAll();
    }
    ShowToast("Đã lưu cài đặt", true);
  }

  Future<void> _logout() async {
    await AuthService.logout();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final t = languageProvider.strings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t.settings, style: GoogleFonts.merriweather(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _panel(
                  children: [
                    Text(t.changeLanguage, style: GoogleFonts.merriweather(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: languageProvider.currentCode,
                      items: LanguageProvider.supportedLanguages.entries
                          .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                          .toList(),
                      onChanged: (code) {
                        if (code != null) languageProvider.setLanguage(code);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _panel(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.notifications),
                      subtitle: Text(t.reminderBeforeMinutes),
                      value: _notificationsEnabled,
                      onChanged: (value) => setState(() => _notificationsEnabled = value),
                    ),
                    const SizedBox(height: 8),
                    Text("${t.reminderBeforeMinutes}: $_reminderMinutes"),
                    Slider(
                      value: _reminderMinutes.toDouble(),
                      min: 5,
                      max: 60,
                      divisions: 11,
                      label: "$_reminderMinutes",
                      onChanged: (value) => setState(() => _reminderMinutes = value.round()),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(t.saveSettings),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: Text(t.logout, style: const TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _panel({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
