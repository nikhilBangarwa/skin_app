import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/colors.dart';
import 'package:sizer/sizer.dart';
import '../../core/theme/spacing.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/floating_gradients.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {

  String _getGenderLabel(BuildContext context, String gender) {
    if (gender == 'Male') return context.l10n.genderMale;
    if (gender == 'Female') return context.l10n.genderFemale;
    return context.l10n.genderOther;
  }

  String _getSkinTypeLabel(BuildContext context, String label) {
    if (label == 'Dry') return context.l10n.skinTypeDry;
    if (label == 'Oily') return context.l10n.skinTypeOily;
    if (label == 'Combination') return context.l10n.skinTypeCombination;
    if (label == 'Normal') return context.l10n.skinTypeNormal;
    return label;
  }

  String _getSkinTypeSub(BuildContext context, String label) {
    if (label == 'Dry') return context.l10n.skinTypeDryDesc;
    if (label == 'Oily') return context.l10n.skinTypeOilyDesc;
    if (label == 'Combination') return context.l10n.skinTypeCombinationDesc;
    if (label == 'Normal') return context.l10n.skinTypeNormalDesc;
    return '';
  }

  String _getConcernTranslation(BuildContext context, String key) {
    switch (key) {
      case 'Acne': return context.l10n.concernAcne;
      case 'Dullness': return context.l10n.concernDullness;
      case 'Wrinkles': return context.l10n.concernWrinkles;
      case 'Redness': return context.l10n.concernRedness;
      case 'Pores': return context.l10n.concernPores;
      case 'Uneven Tone': return context.l10n.concernUnevenTone;
      case 'Fine Lines': return context.l10n.concernWrinkles;
      case 'Dark Spots': return context.l10n.concernDarkCircles;
      default: return key;
    }
  }

  String _getStepLabel(BuildContext context, int page) {
    if (page == 0) return context.l10n.step1Title;
    if (page == 1) return context.l10n.step2Title;
    if (page == 2) return context.l10n.step3Title;
    return context.l10n.step4Title;
  }

  String _getStepProgressText(BuildContext context, int page) {
    if (page == 0) return context.l10n.step1Text;
    if (page == 1) return context.l10n.step2Text;
    if (page == 2) return context.l10n.step3Text;
    return context.l10n.step4Text;
  }

  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  int _currentPage = 0;
  bool _showCelebration = false;

  // Step 1 Data
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _ageFocusNode = FocusNode();
  bool _isNameFocused = false;
  bool _isAgeFocused = false;
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Prefer Not To Say'];

  // Step 2 Data
  String? _selectedSkinType;
  final List<Map<String, String>> _skinTypes = [
    {
      'label': 'Dry',
      'sub': 'Skin feels tight and dry',
      'icon': '💧',
    },
    {
      'label': 'Oily',
      'sub': 'Shiny skin, prone to acne',
      'icon': '✨',
    },
    {
      'label': 'Combination',
      'sub': 'Oily in some areas, dry in others',
      'icon': '⚖️',
    },
    {
      'label': 'Normal',
      'sub': 'Balanced, not too oily or dry',
      'icon': '🌿',
    },
  ];

  // Step 3 Data
  final List<String> _selectedConcerns = [];
  final List<String> _skinConcerns = [
    'Acne',
    'Dark Spots',
    'Dullness',
    'Wrinkles',
    'Redness',
    'Pores',
    'Uneven Tone',
    'Fine Lines'
  ];



  // Calibration checklist states
  bool _profileCreated = false;
  bool _preferencesSaved = false;
  bool _calibrationDone = false;

  // Celebration Animation Controllers
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _nameFocusNode.addListener(() {
      setState(() {
        _isNameFocused = _nameFocusNode.hasFocus;
      });
    });
    _ageFocusNode.addListener(() {
      setState(() {
        _isAgeFocused = _ageFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _nameFocusNode.dispose();
    _ageFocusNode.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.selectionClick();
    if (_currentPage == 0) {
      if (!_formKey.currentState!.validate()) return;
      if (_selectedGender == null) {
        _showErrorSnackBar('Please select your gender.');
        return;
      }
    } else if (_currentPage == 1) {
      if (_selectedSkinType == null) {
        _showErrorSnackBar('Please select your skin type.');
        return;
      }
    } else if (_currentPage == 2) {
      if (_selectedConcerns.isEmpty) {
        _showErrorSnackBar('Please select at least one skin concern.');
        return;
      }
    }

    if (_currentPage < 3) {
      FocusScope.of(context).unfocus();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _triggerCelebrationAndSave();
    }
  }

  void _prevPage() {
    HapticFeedback.selectionClick();
    if (_currentPage > 0) {
      FocusScope.of(context).unfocus();
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _triggerCelebrationAndSave() async {
    setState(() {
      _showCelebration = true;
      _profileCreated = false;
      _preferencesSaved = false;
      _calibrationDone = false;
    });

    HapticFeedback.heavyImpact();
    _celebrationController.forward();

    // Sequential checkmark animations
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _profileCreated = true);
        HapticFeedback.lightImpact();
      }
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _preferencesSaved = true);
        HapticFeedback.lightImpact();
      }
    });
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() => _calibrationDone = true);
        HapticFeedback.mediumImpact();
      }
    });

    // Prepare Firestore upload
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _showErrorSnackBar('User session not found.');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _selectedGender,
        'skinType': _selectedSkinType,
        'skinConcerns': _selectedConcerns,
        'onboarded': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show calibration details for a brief moment before navigating
      await Future.delayed(const Duration(milliseconds: 3200));

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _showCelebration = false;
      });
      _showErrorSnackBar('Failed to save profile: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onError)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientGlowBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(height: AppSpacing.md),

                  // Top Branding & Logo
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 4.h,
                          width: 4.h,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Skin',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),

                  // Progress Bar & Labels
                  _buildProgressIndicator(),
                  SizedBox(height: AppSpacing.md),

                  // Step Pages
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      children: [
                        _buildStep1(),
                        _buildStep2(),
                        _buildStep3(),
                        _buildStep4(),
                      ],
                    ),
                  ),

                  // Action Buttons
                  _buildBottomBar(),
                ],
              ),

              // Full Screen Celebration overlay
              if (_showCelebration) _buildCelebrationOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStepLabel(context, _currentPage),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                _getStepProgressText(context, _currentPage),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: List.generate(4, (index) {
              final isPassed = index <= _currentPage;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 0.6.h,
                  margin: EdgeInsets.only(
                    right: index == 3 ? 0 : AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isPassed ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return _SlideFadeTransition(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Animated Profile Avatar
              const Center(
                child: _AnimatedProfileAvatar(),
              ),
              const SizedBox(height: 28),

              const Text(
                'Welcome to SkinAI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Name Field
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isNameFocused ? const Color(0xFFE89A8D) : AppColors.borderColor,
                    width: 1.5,
                  ),
                  boxShadow: _isNameFocused
                      ? [
                    BoxShadow(
                      color: const Color(0xFFE89A8D).withValues(alpha: 0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                      : AppColors.softShadow,
                ),
                child: TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: context.l10n.preferredName,
                    labelStyle: TextStyle(
                      color: _isNameFocused ? const Color(0xFFE89A8D) : AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: _isNameFocused ? const Color(0xFFE89A8D) : AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Age Field
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isAgeFocused ? const Color(0xFFE89A8D) : AppColors.borderColor,
                    width: 1.5,
                  ),
                  boxShadow: _isAgeFocused
                      ? [
                    BoxShadow(
                      color: const Color(0xFFE89A8D).withValues(alpha: 0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                      : AppColors.softShadow,
                ),
                child: TextFormField(
                  controller: _ageController,
                  focusNode: _ageFocusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: context.l10n.ageLabel,
                    labelStyle: TextStyle(
                      color: _isAgeFocused ? const Color(0xFFE89A8D) : AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    prefixIcon: Icon(
                      Icons.cake_outlined,
                      color: _isAgeFocused ? const Color(0xFFE89A8D) : AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your age';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age <= 0 || age > 120) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Gender Selection
              Text(
                context.l10n.genderIdentity,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _genders.map((gender) {
                  final isSelected = _selectedGender == gender;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedGender = gender;
                      });
                    },
                    child: AnimatedScale(
                      scale: isSelected ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                            colors: [Color(0xFFE89A8D), Color(0xFFD97B6C)],
                          )
                              : null,
                          color: isSelected ? null : AppColors.card.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(color: const Color(0xFFE89A8D).withValues(alpha: 0.5), width: 1.0)
                              : Border.all(color: AppColors.borderColor, width: 1.0),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: const Color(0xFFE89A8D).withValues(alpha: 0.25),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ]
                              : [],
                        ),
                        child: Text(
                          _getGenderLabel(context, gender),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Theme.of(context).colorScheme.onPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return _SlideFadeTransition(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              context.l10n.selectSkinTypeTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.selectSkinTypeSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _skinTypes.length,
              itemBuilder: (context, index) {
                final type = _skinTypes[index];
                final isSelected = _selectedSkinType == type['label'];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedSkinType = type['label'];
                      });
                    },
                    child: AnimatedScale(
                      scale: isSelected ? 1.02 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.card : AppColors.card.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFE89A8D) : AppColors.borderColor,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: const Color(0xFFE89A8D).withValues(alpha: 0.15),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ]
                              : AppColors.softShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFE89A8D).withValues(alpha: 0.15)
                                    : AppColors.accentLight,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                type['icon']!,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getSkinTypeLabel(context, type['label']!),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? Theme.of(context).colorScheme.onPrimary : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getSkinTypeSub(context, type['label']!),
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE89A8D),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  size: 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return _SlideFadeTransition(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              context.l10n.selectConcernsTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.selectConcernsSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 12,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _skinConcerns.map((concern) {
                final isSelected = _selectedConcerns.contains(concern);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isSelected) {
                        _selectedConcerns.remove(concern);
                      } else {
                        _selectedConcerns.add(concern);
                      }
                    });
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.card : AppColors.card.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFE89A8D) : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: const Color(0xFFE89A8D).withValues(alpha: 0.15),
                            blurRadius: 8,
                          )
                        ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getConcernTranslation(context, concern),
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Theme.of(context).colorScheme.onPrimary : AppColors.textSecondary,
                            ),
                          ),
                          if (isSelected) ...[
                            SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE89A8D),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStep4() {
    final String name = _nameController.text.trim();
    final String age = _ageController.text.trim();
    final String gender = _selectedGender ?? '';
    final String skinType = _selectedSkinType ?? '';

    return _SlideFadeTransition(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              context.l10n.almostThere,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.reviewProfileSub,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // User Profile Card (Initials Avatar + Summary Table)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.borderColor),
                boxShadow: AppColors.softShadow,
              ),
              child: Column(
                children: [
                  // Initial Avatar
                  Container(
                    height: 76,
                    width: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE89A8D), Color(0xFFD97B6C)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE89A8D).withValues(alpha: 0.25),
                          blurRadius: 15,
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'N',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    name.isNotEmpty ? name : 'Nikhil Bangarwa',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$gender - Age ${age.isNotEmpty ? age : '18'}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Inner table summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.profileSummary,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE89A8D),
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        _buildSummaryRow(context.l10n.step2Title, skinType.isNotEmpty ? _getSkinTypeLabel(context, skinType) : _getSkinTypeLabel(context, 'Combination')),
                        Divider(color: AppColors.borderColor, height: 24, thickness: 0.8),
                        _buildSummaryRow(
                          context.l10n.step3Title,
                          _selectedConcerns.isNotEmpty ? _selectedConcerns.map((c) => _getConcernTranslation(context, c)).join(', ') : '${_getConcernTranslation(context, 'Acne')}, ${_getConcernTranslation(context, 'Dark Spots')}',
                        ),
                        Divider(color: AppColors.borderColor, height: 24, thickness: 0.8),
                        _buildSummaryRow(context.l10n.aiAlgorithm, 'SkinAI v1.0'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        children: [
          // Back Button
          if (_currentPage > 0)
            Expanded(
              child: SizedBox(
                height: 52,
                child: TextButton(
                  onPressed: _prevPage,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    context.l10n.back,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),

          // Next / Finish Button with Gradient
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTapDown: (_) => HapticFeedback.selectionClick(),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE89A8D), Color(0xFFD97B6C)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE89A8D).withValues(alpha: 0.25),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _showCelebration ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentPage == 3 ? context.l10n.calibrationTitle : context.l10n.continueButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Celebratory Overlay Animation Widget (Calibration Screen)
  Widget _buildCelebrationOverlay() {
    return Positioned.fill(
      child: Container(
        color: AppColors.background.withValues(alpha: 0.98),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Pulsing Dash circle loader
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE89A8D).withValues(alpha: 0.15), width: 4),
                  ),
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _celebrationController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            height: 90,
                            width: 90,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE89A8D), Color(0xFFD97B6C)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE89A8D).withValues(alpha: 0.4),
                                  blurRadius: 25,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.done_all_rounded,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Wording matching the image
                Text(
                  context.l10n.calibratingProfile,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.calibrationDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 48),

                // Bullet checklist with transitions
                Container(
                  width: 280,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildChecklistItem('Profile Created', _profileCreated),
                      SizedBox(height: AppSpacing.md),
                      _buildChecklistItem('Preferences Saved', _preferencesSaved),
                      SizedBox(height: AppSpacing.md),
                      _buildChecklistItem('AI Calibration Complete', _calibrationDone),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom CTA Get Started Button appearing once calibration is done
                AnimatedOpacity(
                  opacity: _calibrationDone ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE89A8D), Color(0xFFD97B6C)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE89A8D).withValues(alpha: 0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _calibrationDone
                            ? () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                                (route) => false,
                          );
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          context.l10n.getStarted,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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

  Widget _buildChecklistItem(String title, bool isCompleted) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.withValues(alpha: 0.15) : AppColors.borderColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : Icons.hourglass_empty_rounded,
            color: isCompleted ? Colors.green : AppColors.textSecondary,
            size: 14,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.w500,
            color: isCompleted ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AnimatedProfileAvatar extends StatefulWidget {
  const _AnimatedProfileAvatar();

  @override
  State<_AnimatedProfileAvatar> createState() => _AnimatedProfileAvatarState();
}

class _AnimatedProfileAvatarState extends State<_AnimatedProfileAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatingAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingAnimation.value),
          child: Container(
            height: 100,
            width: 100,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE89A8D).withValues(alpha: 0.45),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SlideFadeTransition extends StatefulWidget {
  final Widget child;
  const _SlideFadeTransition({required this.child});

  @override
  State<_SlideFadeTransition> createState() => _SlideFadeTransitionState();
}

class _SlideFadeTransitionState extends State<_SlideFadeTransition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0.0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}