import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import 'package:sizer/sizer.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/floating_gradients.dart';
import '../../core/providers/localization_provider.dart';
import '../../main.dart'; // To access AuthRouter

class LanguageSelectionScreen extends StatefulWidget {
  final bool isFromSettings;

  const LanguageSelectionScreen({super.key, this.isFromSettings = false});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLang = 'en';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final locProvider = Provider.of<LocalizationProvider>(context, listen: false);
        setState(() {
          _selectedLang = locProvider.locale.languageCode;
        });
      }
    });
  }

  void _onLangSelect(String code) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedLang = code;
    });
  }

  Future<void> _handleContinue() async {
    HapticFeedback.mediumImpact();
    final locProvider = Provider.of<LocalizationProvider>(context, listen: false);
    await locProvider.setLocale(Locale(_selectedLang));

    if (mounted) {
      if (widget.isFromSettings) {
        Navigator.of(context).pop();
      } else {
        // First Launch: proceed to authentication router
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthRouter()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isFromSettings
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                },
              ),
            )
          : null,
      body: AmbientGlowBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(height: AppSpacing.sm),
                
                // Text Headers
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getTitleText(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      _getSubtitleText(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Quicksand',
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),

                // Language options list (English & Hindi)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLangOption('en', 'English', 'English'),
                    SizedBox(height: AppSpacing.md),
                    _buildLangOption('hi', 'हिन्दी', 'Hindi'),
                  ],
                ),

                // Continue Button
                GestureDetector(
                  onTapDown: (_) => HapticFeedback.selectionClick(),
                  child: Container(
                    height: 6.5.h,
                    width: double.infinity,
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
                      onPressed: _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3.25.h),
                        ),
                      ),
                      child: Text(
                        _getButtonText(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLangOption(String code, String name, String englishName) {
    final bool isSelected = _selectedLang == code;
    return GestureDetector(
      onTap: () => _onLangSelect(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: isSelected ? 0.9 : 0.5),
          borderRadius: BorderRadius.circular(2.5.h),
          border: isSelected ? AppColors.activeGlassBorder : AppColors.glassBorder,
          boxShadow: isSelected ? AppColors.glowShadow : AppColors.softShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  englishName,
                  style: TextStyle(
                    fontFamily: 'Quicksand',
                    fontSize: 10.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Container(
                height: 3.h,
                width: 3.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: Icon(
                  Icons.check,
                  size: 14,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper titles based on temporary local choice
  String _getTitleText() {
    switch (_selectedLang) {
      case 'hi':
        return 'भाषा चुनें';
      default:
        return 'Select Language';
    }
  }

  String _getSubtitleText() {
    switch (_selectedLang) {
      case 'hi':
        return 'ऐप अनुभव के लिए अपनी पसंदीदा भाषा चुनें।';
      default:
        return 'Choose your preferred language for the app experience.';
    }
  }

  String _getButtonText() {
    if (widget.isFromSettings) {
      switch (_selectedLang) {
        case 'hi':
          return 'सहेजें';
        default:
          return 'Save';
      }
    } else {
      switch (_selectedLang) {
        case 'hi':
          return 'जारी रखें';
        default:
          return 'Continue';
      }
    }
  }
}
