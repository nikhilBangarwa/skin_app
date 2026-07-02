import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/colors.dart';
import '../../theme/floating_gradients.dart';
import '../../widgets/skincare_illustrations.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
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
    {'label': 'Dry', 'icon': '💧'},
    {'label': 'Oily', 'icon': '✨'},
    {'label': 'Combination', 'icon': '⚖️'},
    {'label': 'Normal', 'icon': '🌿'},
    {'label': 'Sensitive', 'icon': '🩷'},
  ];

  // Step 3 Data
  final List<String> _selectedConcerns = [];
  final List<String> _skinConcerns = ['Acne', 'Dark Spots', 'Dullness', 'Wrinkles', 'Redness'];

  // Step Labels
  final List<String> _stepLabels = ['Personal Info', 'Skin Type', 'Concerns', 'Summary'];

  // Celebration Animation Controllers
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

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
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack),
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
    });
    
    // Play haptic success impact
    HapticFeedback.heavyImpact();
    _celebrationController.forward();

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

      // Show celebration for a brief moment before navigating
      await Future.delayed(const Duration(milliseconds: 2200));

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
        content: Text(message, style: const TextStyle(color: Colors.white)),
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
                  const SizedBox(height: 20),
                  
                  // Top Branding & Logo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Skin',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'AI',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Progress Bar & Labels
                  _buildProgressIndicator(),
                  const SizedBox(height: 16),
                  
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
                _stepLabels[_currentPage],
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Step ${_currentPage + 1} of 4',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (index) {
              final isPassed = index <= _currentPage;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  margin: EdgeInsets.only(
                    right: index == 3 ? 0 : 8,
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
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
              const Text(
                'Let\'s create your personalized skin profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
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
                    color: _isNameFocused ? const Color(0xFFE89A8D) : Colors.white.withValues(alpha: 0.08),
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
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: 'Preferred Name',
                    labelStyle: TextStyle(
                      color: _isNameFocused ? const Color(0xFFE89A8D) : AppColors.textSecondary,
                      fontSize: 14,
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
                    color: _isAgeFocused ? const Color(0xFFE89A8D) : Colors.white.withValues(alpha: 0.08),
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
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    labelStyle: TextStyle(
                      color: _isAgeFocused ? const Color(0xFFE89A8D) : AppColors.textSecondary,
                      fontSize: 14,
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
              const Text(
                'Gender Identity',
                style: TextStyle(
                  fontSize: 13,
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
                              : Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0),
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
                          gender,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          // Custom Skin Layers Illustration
          const Center(
            child: SkinLayersIllustration(),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'What is your skin type?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the profile that best matches your daily skin texture.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          // Custom Scale & Glow Selection Cards for Skin Type
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _skinTypes.length,
            itemBuilder: (context, index) {
              final type = _skinTypes[index];
              final isSelected = _selectedSkinType == type['label'];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedSkinType = type['label'];
                    });
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.03 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.card : AppColors.card.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? AppColors.activeGlassBorder : AppColors.glassBorder,
                        boxShadow: isSelected ? AppColors.glowShadow : AppColors.softShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : AppColors.accentLight,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              type['icon']!,
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            type['label']!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          AnimatedOpacity(
                            opacity: isSelected ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 24,
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
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          // Hexagon Grid Illustration
          const Center(
            child: AnalysisGridIllustration(),
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Targeted concerns',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select all conditions you wish to analyze & address.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          // Modern Pill Chips with active animations
          Wrap(
            spacing: 12,
            runSpacing: 12,
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.card : AppColors.card.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(24),
                    border: isSelected ? AppColors.activeGlassBorder : AppColors.glassBorder,
                    boxShadow: isSelected ? AppColors.glowShadow : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        concern,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.add_circle,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    final String name = _nameController.text.trim();
    final String age = _ageController.text.trim();
    final String gender = _selectedGender ?? '';
    final String skinType = _selectedSkinType ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Calibrating Profile',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review your skin intelligence parameters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // User Profile Card (Initials Avatar + Metadata)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: AppColors.glassBorder,
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              children: [
                // Avatar representation
                Container(
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$gender • Age $age',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details summary cards
          Row(
            children: [
              // Skin Type Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: AppColors.glassBorder,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Skin Profile',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        skinType,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Analysis Mode card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: AppColors.glassBorder,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Algorithm',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI Scan v1.0',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Selected Concerns Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: AppColors.glassBorder,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Identified Targets',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedConcerns.map((concern) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Text(
                        concern,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
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
                  child: const Text(
                    'Back',
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
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
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
                  child: Text(
                    _currentPage == 3 ? 'Calibrate AI' : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
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
    );
  }

  // Celebratory Overlay Animation Widget (Step 4 Complete)
  Widget _buildCelebrationOverlay() {
    return Positioned.fill(
      child: Container(
        color: AppColors.background.withValues(alpha: 0.95),
        child: AnimatedBuilder(
          animation: _celebrationController,
          builder: (context, child) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Growing checkmark sphere
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      height: 110,
                      width: 110,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: RotationTransition(
                          turns: _checkAnimation,
                          child: Icon(
                            Icons.done_all_rounded,
                            size: 52,
                            color: Colors.white.withValues(alpha: _checkAnimation.value),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Opacity(
                    opacity: _scaleAnimation.value,
                    child: const Text(
                      'Calibration Complete',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: _scaleAnimation.value,
                    child: const Text(
                      'Setting up your personalized diagnostic hub...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// Sub-widgets supporting the premium onboarding screen redesign
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFFFBCAE), // Light rose gold
                  Color(0xFFE89A8D), // Primary accent rose gold
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE89A8D).withValues(alpha: 0.45),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.face_retouching_natural,
              size: 52,
              color: Colors.white,
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
