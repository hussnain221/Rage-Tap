import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../audio/audio_service.dart';
import '../../core/constants.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../data/save_service.dart';
import '../widgets/neon_button.dart';

/// Settings screen per spec §12.6 and Prompt 3.8.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.saveService,
    this.privacyPolicyUrl = C.privacyPolicyUrl,
  });

  final SaveService? saveService;
  final String privacyPolicyUrl;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SaveService _saveService;
  late bool _soundEnabled;
  late bool _hapticsEnabled;

  static const String privacyPolicyText = '''
Privacy Policy for Rage Tap

Rage Tap ("the app") is an offline game published by ${C.publisherName}.

Information we collect:
The app does not collect, store on our servers, or share any personal information. It does not require an account and does not use the internet during gameplay.

Data stored on your device:
The app saves your best score and your settings (sound and vibration) locally on your device. This data never leaves your device and is removed when you uninstall the app.

Third parties:
This version of the app contains no advertising, analytics, or other third-party data-collecting services.

Children:
The app is not directed to children under 13.

Changes:
If a future version adds advertising or other features that process data, this policy will be updated before release and the app's Data safety information will be updated accordingly.

Contact: stormlogix1@gmail.com
''';

  @override
  void initState() {
    super.initState();
    _saveService = widget.saveService ?? SaveService.instance;
    _soundEnabled = _saveService.soundEnabled;
    _hapticsEnabled = _saveService.hapticsEnabled;
  }

  Future<void> _toggleSound(bool value) async {
    setState(() => _soundEnabled = value);
    await _saveService.setSoundEnabled(value);
    AudioService.instance.onSoundEnabledChanged(value);
  }

  Future<void> _toggleHaptics(bool value) async {
    setState(() => _hapticsEnabled = value);
    await _saveService.setHapticsEnabled(value);
  }

  Future<void> _openPrivacyPolicy() async {
    if (widget.privacyPolicyUrl.isNotEmpty) {
      final uri = Uri.tryParse(widget.privacyPolicyUrl);
      if (uri != null) {
        try {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) return;
        } catch (_) {
          // Fall through to show dialog on error
        }
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.bgPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Palette.cyan.withValues(alpha: 0.5), width: 1.5),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Palette.cyan,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: const SingleChildScrollView(
          child: Text(
            privacyPolicyText,
            style: TextStyle(
              color: Palette.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
        actions: [
          NeonButton(
            text: 'CLOSE',
            variant: NeonButtonVariant.secondary,
            height: 48,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _showCredits() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.bgPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Palette.cyan.withValues(alpha: 0.5), width: 1.5),
        ),
        title: const Text(
          'Credits',
          style: TextStyle(
            color: Palette.cyan,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'Rage Tap — made by ${C.publisherName}.\n\nSound effects generated procedurally.\n\nBuilt with Flutter and Flame.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          NeonButton(
            text: 'OK',
            variant: NeonButtonVariant.primary,
            height: 48,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.bgPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Palette.magenta, width: 1.5),
        ),
        title: const Text(
          'Reset Progress?',
          style: TextStyle(
            color: Palette.magenta,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        content: const Text(
          'This resets your best score. This cannot be undone.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: NeonButton(
                  text: 'CANCEL',
                  variant: NeonButtonVariant.secondary,
                  height: 48,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NeonButton(
                  text: 'RESET',
                  variant: NeonButtonVariant.danger,
                  height: 48,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _saveService.resetProgress();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Progress reset successfully.',
            style: TextStyle(color: Palette.cyan),
          ),
          backgroundColor: Palette.bgPurple,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.bgPurple,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Palette.cyan.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Palette.cyan, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: Palette.cyan,
            activeTrackColor: Palette.cyan.withValues(alpha: 0.4),
            inactiveThumbColor: Palette.muted,
            inactiveTrackColor: Palette.bgDeep,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Palette.cyan, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Palette.muted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  NeonIconButton(
                    icon: const Icon(Icons.arrow_back, color: Palette.cyan, size: 22),
                    tooltip: 'Back',
                    size: 48,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'SETTINGS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                children: [
                  // Audio & Haptics section
                  _buildCard(
                    children: [
                      _buildSwitchRow(
                        icon: Icons.volume_up,
                        title: 'Sound Effects',
                        value: _soundEnabled,
                        onChanged: _toggleSound,
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Palette.cyan.withValues(alpha: 0.15),
                      ),
                      _buildSwitchRow(
                        icon: Icons.vibration,
                        title: 'Vibration',
                        value: _hapticsEnabled,
                        onChanged: _toggleHaptics,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Information section
                  _buildCard(
                    children: [
                      _buildNavRow(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: _openPrivacyPolicy,
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Palette.cyan.withValues(alpha: 0.15),
                      ),
                      _buildNavRow(
                        icon: Icons.info_outline,
                        title: 'Credits',
                        onTap: _showCredits,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Danger section: Reset Progress
                  Center(
                    child: NeonButton(
                      text: 'RESET PROGRESS',
                      variant: NeonButtonVariant.danger,
                      width: 240,
                      height: 48,
                      onPressed: _confirmResetProgress,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Footer: Version
                  const Center(
                    child: Text(
                      C.appVersion,
                      style: AppTheme.caption,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
