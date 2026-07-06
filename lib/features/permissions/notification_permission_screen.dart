import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import 'package:sizer/sizer.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/floating_gradients.dart';
import '../../core/services/notification_service.dart';
import '../../core/providers/localization_provider.dart';
import '../../core/localization/app_localizations.dart';
import '../language/language_selection_screen.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientGlowBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(height: AppSpacing.md),
                
                // Content Column
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing Notification Bell
                    Container(
                      height: 14.h,
                      width: 14.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.card,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.notifications_active_outlined,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xl),
                    
                    // Title
                    Text(
                      context.l10n.notificationPermissionTitle,
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    
                    // Glassmorphic explanation banner
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.card.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2.5.h),
                        border: AppColors.glassBorder,
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Text(
                        context.l10n.notificationPermissionSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Quicksand',
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // CTA Action Buttons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Allow Notifications (Gradient)
                    GestureDetector(
                      onTapDown: (_) => HapticFeedback.selectionClick(),
                      child: Container(
                        height: 6.5.h,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(3.25.h),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            )
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
                            final locProvider = Provider.of<LocalizationProvider>(context, listen: false);
                            
                            await notifProvider.requestNotificationPermission();
                            await locProvider.markNotificationPermissionShown();
                            
                            if (context.mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3.25.h),
                            ),
                          ),
                          child: Text(
                            context.l10n.allowNotifications,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    
                    // Not Now (Text Button)
                    TextButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
                        final locProvider = Provider.of<LocalizationProvider>(context, listen: false);
                        
                        await notifProvider.setNotificationsEnabled(false);
                        await locProvider.markNotificationPermissionShown();
                        
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3.25.h),
                        ),
                      ),
                      child: Text(
                        context.l10n.notNow,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
