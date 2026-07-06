import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/colors.dart';
import 'package:sizer/sizer.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/floating_gradients.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/constants/app_constants.dart';
import '../language/language_selection_screen.dart';
import '../../main.dart'; // To route back to AuthRouter upon logout

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final locProvider = Provider.of<LocalizationProvider>(context);
    final notificationProvider = Provider.of<NotificationProvider>(context);

    final currentTheme = themeProvider.themeMode;
    final notificationsEnabled = notificationProvider.enabled;
    final currentLocale = locProvider.locale;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          l10n.settingsTitle,
          style: TextStyle(
            fontFamily: 'Quicksand',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: AmbientGlowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            children: [
              SizedBox(height: AppSpacing.sm),
              
              // Section: General Preferences
              _buildSectionHeader(context, l10n.translate('preferences')),
              SizedBox(height: AppSpacing.sm),
              _buildSettingsCard(
                children: [
                  // Row: Theme Selector
                  _buildThemeSelectorRow(context, themeProvider, currentTheme),
                  _buildDivider(),
                  // Row: Language Selection
                  _buildClickableRow(
                    context: context,
                    icon: Icons.language_rounded,
                    title: l10n.languageSettings,
                    subtitle: _getLanguageName(currentLocale.languageCode),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LanguageSelectionScreen(isFromSettings: true),
                        ),
                      );
                    },
                  ),
                  _buildDivider(),
                  // Row: Notification Toggle
                  _buildToggleRow(
                    context: context,
                    icon: Icons.notifications_none_rounded,
                    title: l10n.notificationsSettings,
                    value: notificationsEnabled,
                    onChanged: (val) async {
                      HapticFeedback.mediumImpact();
                      await notificationProvider.setNotificationsEnabled(val);
                    },
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              
              // Section: Legal Info
              _buildSectionHeader(context, l10n.translate('legal')),
              SizedBox(height: AppSpacing.sm),
              _buildSettingsCard(
                children: [
                  // Row: Privacy Policy
                  _buildClickableRow(
                    context: context,
                    icon: Icons.privacy_tip_outlined,
                    title: l10n.privacyPolicy,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showDocDialog(context, l10n.privacyPolicy, AppConstants.privacyPolicyText);
                    },
                  ),
                  _buildDivider(),
                  // Row: Terms & Conditions
                  _buildClickableRow(
                    context: context,
                    icon: Icons.description_outlined,
                    title: l10n.termsConditions,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showDocDialog(context, l10n.termsConditions, AppConstants.termsConditionsText);
                    },
                  ),
                ],
              ),
              
              SizedBox(height: AppSpacing.xl),
              
              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: OutlinedButton(
                  onPressed: () => _handleLogout(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: AppColors.error.withValues(alpha: 0.05),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        l10n.translate('logOut'),
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: AppColors.glassBorder,
        boxShadow: AppColors.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.divider,
    );
  }

  Widget _buildThemeSelectorRow(BuildContext context, ThemeProvider themeProvider, ThemeMode currentTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: 14),
              Text(
                AppLocalizations.of(context)!.themeSettings,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          
          DropdownButton<ThemeMode>(
            value: currentTheme,
            dropdownColor: AppColors.card,
            underline: const SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('System', style: TextStyle(fontFamily: 'Quicksand', fontSize: 14)),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Light', style: TextStyle(fontFamily: 'Quicksand', fontSize: 14)),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark', style: TextStyle(fontFamily: 'Quicksand', fontSize: 14)),
              ),
            ],
            onChanged: (mode) {
              if (mode != null) {
                HapticFeedback.selectionClick();
                themeProvider.setThemeMode(mode);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Quicksand',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.disabledText,
            inactiveTrackColor: AppColors.borderColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildClickableRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Quicksand',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null) ...[
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Quicksand',
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
        ],
      ),
      onTap: onTap,
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'hi':
        return 'हिन्दी';
      default:
        return 'English';
    }
  }

  void _showDocDialog(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 75.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: TextStyle(
                      fontFamily: 'Quicksand',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    HapticFeedback.selectionClick();
    final l10n = AppLocalizations.of(context)!;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.translate('logOut'),
          style: TextStyle(fontFamily: 'Quicksand', color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.translate('logOutConfirm'),
          style: TextStyle(fontFamily: 'Quicksand', color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel'), style: TextStyle(fontFamily: 'Quicksand', color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.translate('logOut'), style: TextStyle(fontFamily: 'Quicksand', color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
      if (context.mounted) {
        // Pop back to auth screen router
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthRouter()),
          (route) => false,
        );
      }
    }
  }
}
