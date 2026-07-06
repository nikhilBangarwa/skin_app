import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/colors.dart';
import 'package:sizer/sizer.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/floating_gradients.dart';
import '../../core/widgets/sparkline_painter.dart';
import '../scan/scan_screen.dart';
import '../scan/result_screen.dart';
import '../auth/login_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  int _currentIndex = 0;

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to sign out. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$month ${dt.day}, ${dt.year} • ${hour.toString().padLeft(2, '0')}:$minute $period";
  }

  int _calculateStreak(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return 0;
    
    // Sort and parse dates
    final List<DateTime> dates = docs
        .map((d) {
          final data = d.data() as Map<String, dynamic>;
          final Timestamp? ts = data['createdAt'];
          return ts?.toDate();
        })
        .where((d) => d != null)
        .map((d) => DateTime(d!.year, d.month, d.day))
        .toSet()
        .toList();

    if (dates.isEmpty) return 0;
    
    // Sort descending
    dates.sort((a, b) => b.compareTo(a));

    final DateTime today = DateTime.now();
    final DateTime checkDate = DateTime(today.year, today.month, today.day);
    
    final diffDays = checkDate.difference(dates.first).inDays;
    if (diffDays > 1) return 0;

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final diff = dates[i].difference(dates[i + 1]).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(
        body: Center(
          child: Text('User details not found. Please log in again.'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
      builder: (context, userSnapshot) {
        String name = _currentUser?.displayName ?? 'Companion';
        String? skinType = 'Oily';
        List<String> concerns = ['Acne', 'Dark Circles', 'Redness'];

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final data = userSnapshot.data!.data() as Map<String, dynamic>;
          name = data['name'] ?? name;
          skinType = data['skinType'] ?? skinType;
          final List<dynamic>? rawConcerns = data['skinConcerns'];
          if (rawConcerns != null) {
            concerns = rawConcerns.cast<String>();
          }
        }

        // Subcollection query matching: users/{uid}/scan_history
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_uid)
              .collection('scan_history')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, scansSnapshot) {
            if (scansSnapshot.connectionState == ConnectionState.waiting) {
              return _buildSkeletonLoading();
            }

            final List<QueryDocumentSnapshot> scanDocs =
                scansSnapshot.hasData ? scansSnapshot.data!.docs : [];
            
            final bool hasScans = scanDocs.isNotEmpty;
            final latestScanData = hasScans ? (scanDocs.first.data() as Map<String, dynamic>) : null;
            final int latestScore = latestScanData != null ? (latestScanData['score'] ?? 82) : 82;
            final Timestamp? latestScanTime = latestScanData != null ? latestScanData['createdAt'] : null;

            // Calculations for streak and analytics
            final int totalScans = scanDocs.length;
            final int avgScore = totalScans > 0
                ? (scanDocs.map((doc) => (doc.data() as Map<String, dynamic>)['score'] as int).reduce((a, b) => a + b) / totalScans).round()
                : 0;
            final int bestScore = totalScans > 0
                ? scanDocs.map((doc) => (doc.data() as Map<String, dynamic>)['score'] as int).reduce((a, b) => a > b ? a : b)
                : 0;
            final int baselineScore = totalScans > 0
                ? (scanDocs.last.data() as Map<String, dynamic>)['score'] as int
                : 0;
            final int improvementPercent = totalScans > 1 ? (latestScore - baselineScore) : 0;
            final int streakDays = _calculateStreak(scanDocs);

            return Scaffold(
              backgroundColor: AppColors.background,
              body: AmbientGlowBackground(
                child: Stack(
                  children: [
                    SafeArea(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: [
                          // Tab 0: Dashboard Home Page
                          _buildHomeTab(
                            name,
                            skinType,
                            concerns,
                            hasScans,
                            latestScore,
                            latestScanTime,
                            latestScanData,
                            improvementPercent,
                            streakDays,
                          ),
                          
                          // Tab 1: Database History Tab
                          _buildHistoryTab(scanDocs, totalScans, avgScore, bestScore, improvementPercent),
                          
                          // Tab 2: Wires camera
                          Container(),

                          // Tab 3: Insights
                          _buildPlaceholderTab('AI Insights', Icons.compass_calibration),

                          // Tab 4: Profile Tab
                          _buildProfileTab(name, skinType, concerns, totalScans, bestScore),
                        ],
                      ),
                    ),

                    // Navigation Dock
                    _buildBottomNavigationBar(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHomeTab(
    String name,
    String? skinType,
    List<String> concerns,
    bool hasScans,
    int latestScore,
    Timestamp? latestScanTime,
    Map<String, dynamic>? latestScanData,
    int improvement,
    int streak,
  ) {
    final String photoUrl = _currentUser?.photoURL ??
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80';

    final String lastScanText = latestScanTime != null
        ? _formatDate(latestScanTime.toDate())
        : 'No scans recorded';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SkinAI',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -1.0,
                    ),
                  ),
                  Text(
                    'Your AI-Powered Skin Analyst',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: AppColors.glassBorder,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.notifications_none, color: AppColors.textPrimary, size: 20),
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Container(
                            height: 6,
                            width: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                      image: DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Greeting & Score Widget
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()},',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Let’s keep your skin healthy and glowing.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Today's circular Score widget
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (hasScans && latestScanData != null) {
                    _openReportDetails(latestScanData);
                  } else {
                    _navigateToScan();
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 86,
                      width: 86,
                      child: CircularProgressIndicator(
                        value: hasScans ? (latestScore / 100.0) : 0.0,
                        strokeWidth: 5,
                        backgroundColor: AppColors.borderColor,
                        color: AppColors.primary,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasScans ? '$latestScore' : '--',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Score',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Dashboard stats boxes row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatsBox('Scan Streak', '$streak days', Icons.workspace_premium_outlined),
              _buildStatsBox('Improvement', '${improvement >= 0 ? '+' : ''}$improvement pts', Icons.trending_up),
            ],
          ),
          const SizedBox(height: 20),

          // Hero scan CTA card
          GestureDetector(
            onTap: _navigateToScan,
            child: Container(
              height: 26.h,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: AppColors.glassBorder,
                boxShadow: AppColors.softShadow,
              ),
              child: Stack(
                children: [
                  // Right side: The woman's face aligned to the right and bottom
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: 175,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      child: Image.asset(
                        'assets/images/hero_face.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 13,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Top row: Badge + Text Column
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Circular Scanner Badge
                                    Container(
                                      height: 6.h,
                                      width: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            const Color(0xFFE89A8D).withValues(alpha: 0.25),
                                            const Color(0xFFE89A8D).withValues(alpha: 0.05),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFE89A8D).withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE89A8D).withValues(alpha: 0.15),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.face_retouching_natural,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Title texts column
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.l10n.readyToScan,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFE89A8D),
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            context.l10n.analyzeYourSkin,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'Scan your face to get AI-powered ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Bottom row: Start Scan Button
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFE89A8D), Color(0xFFD67B6C)],
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE89A8D).withValues(alpha: 0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        context.l10n.startScan,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 32),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Spacer for the right-side woman's face
                          const Expanded(
                            flex: 7,
                            child: SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Overview Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overview Metrics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'View All',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 18.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildOverviewCard(
                  iconColor: const Color(0xFF3A2E2B),
                  icon: Icons.calendar_today,
                  title: context.l10n.lastScan,
                  value: hasScans ? context.l10n.completed : context.l10n.noScansYet,
                  sub: lastScanText,
                  child: hasScans
                      ? GestureDetector(
                          onTap: () => _openReportDetails(latestScanData!),
                          child: Row(
                            children: [
                              Text('View Result', style: TextStyle(color: AppColors.textPrimary, fontSize: 8.5.sp, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Icon(Icons.chevron_right, color: AppColors.textPrimary, size: 9.sp),
                            ],
                          ),
                        )
                      : Container(),
                ),
                _buildOverviewCard(
                  iconColor: const Color(0xFF203A30),
                  icon: Icons.trending_up,
                  title: context.l10n.skinProgress,
                  value: hasScans ? 'Improving' : 'N/A',
                  sub: hasScans ? '+12% this month' : 'Needs baseline scan',
                  child: SizedBox(
                    width: 120,
                    height: 26,
                    child: CustomPaint(
                      painter: SparklinePainter(
                        points: [0.3, 0.5, 0.45, 0.6, 0.5, 0.72, 0.8],
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                _buildOverviewCard(
                  iconColor: const Color(0xFF202E3A),
                  icon: Icons.opacity,
                  title: context.l10n.hydration,
                  value: 'Good',
                  sub: '68% water retention',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: const LinearProgressIndicator(
                      value: 0.68,
                      minHeight: 5,
                      backgroundColor: Color(0xFF262A34),
                      color: Color(0xFF8DCEE8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Skin Profile row
          Text(
            context.l10n.yourSkinProfile,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: AppColors.glassBorder,
            ),
            child: Row(
              children: [
                _buildProfileMetaCol(Icons.opacity, context.l10n.step2Title, skinType ?? 'Oily'),
                Container(width: 1, height: 40, color: AppColors.divider),
                _buildProfileMetaCol(Icons.layers, context.l10n.step3Title, '${concerns.length} Active'),
                Container(width: 1, height: 40, color: AppColors.divider),
                _buildProfileMetaCol(Icons.check_circle, 'Goals', 'Even Tone'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Smart insights section
          Text(
            context.l10n.smartInsights,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          Column(
            children: [
              _buildInsightCard(Icons.wb_sunny_outlined, context.l10n.uvAlertTitle, context.l10n.uvAlertDesc, const Color(0xFF3A2925)),
              _buildInsightCard(Icons.opacity, context.l10n.hydrationReminderTitle, context.l10n.hydrationReminderDesc, const Color(0xFF202E3A)),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(
    List<QueryDocumentSnapshot> scanDocs,
    int totalScans,
    int avgScore,
    int bestScore,
    int improvement,
  ) {
    if (scanDocs.isEmpty) {
      // Empty state
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, size: 58, color: AppColors.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 20),
              Text(
                context.l10n.noScansYet,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.noScansYetDesc,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _navigateToScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                ),
                child: Text(
                  context.l10n.startFirstScan,
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Text(
            context.l10n.scanReportsHistory,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Analytics summary card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
              border: AppColors.glassBorder,
            ),
            child: Row(
              children: [
                _buildAnalyticsBox(context.l10n.totalScans, '$totalScans'),
                Container(width: 1, height: 30, color: AppColors.divider),
                _buildAnalyticsBox(context.l10n.avgScore, '$avgScore'),
                Container(width: 1, height: 30, color: AppColors.divider),
                _buildAnalyticsBox(context.l10n.bestScore, '$bestScore'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              itemCount: scanDocs.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final doc = scanDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                
                final int score = data['score'] ?? 80;
                final Timestamp? timestamp = data['createdAt'];
                final String imagePath = data['imageUrl'] ?? '';
                final String summary = data['summary'] ?? '';
                final String formattedDate = timestamp != null
                    ? _formatDate(timestamp.toDate())
                    : 'Report Logged';

                final bool hasLocalFile = imagePath.isNotEmpty && File(imagePath).existsSync();
                final ImageProvider thumbnailProvider = hasLocalFile
                    ? FileImage(File(imagePath))
                    : const NetworkImage(
                        'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=150&q=80',
                      ) as ImageProvider;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () => _openReportDetails(data),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: AppColors.glassBorder,
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 6.h,
                            width: 52,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderColor),
                              image: DecorationImage(
                                image: thumbnailProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  summary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$score',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAnalyticsBox(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildStatsBox(String title, String val, IconData icon) {
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: AppColors.glassBorder,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              const SizedBox(height: 2),
              Text(val, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(
    String name,
    String? skinType,
    List<String> concerns,
    int totalScans,
    int bestScore,
  ) {
    final String? email = _currentUser?.email;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2),
                    image: DecorationImage(
                      image: NetworkImage(
                        _currentUser?.photoURL ??
                            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  email ?? 'user@skinai.com',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Statistics Overview Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: AppColors.glassBorder,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnalyticsBox(context.l10n.scan, '$totalScans'),
                _buildAnalyticsBox(context.l10n.bestScore, '$bestScore'),
                _buildAnalyticsBox(context.l10n.step2Title, skinType ?? 'Oily'),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Settings Options
          _buildSettingsOption(Icons.settings_outlined, context.l10n.appSettings, () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          }),
          _buildSettingsOption(Icons.download, context.l10n.exportData, () => _exportJsonData(totalScans)),
          _buildSettingsOption(Icons.delete_outline, context.l10n.deleteAccount, _confirmDeleteAccount, isDestructive: true),
          const SizedBox(height: 32),

          // Sign Out Action Button
          Container(
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _handleSignOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(
                context.l10n.signOut,
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: AppColors.glassBorder,
          ),
          child: Row(
            children: [
              Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDestructive ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportJsonData(int total) async {
    final l10n = context.l10n;
    final noRecordsText = l10n.exportNoRecords;
    final successText = l10n.exportSuccess;
    final errorText = l10n.exportError;
    
    if (total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(noRecordsText)),
      );
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('scan_history')
          .orderBy('createdAt', descending: true)
          .get();

      final List<Map<String, dynamic>> records = snapshot.docs.map((doc) => doc.data()).toList();
      
      // Convert to JSON String
      final String jsonString = records.toString();
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/skinai_export_data.json");
      await file.writeAsString(jsonString);
      
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: successText);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText)),
      );
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.borderColor),
        ),
        title: Text(context.l10n.deleteAccountConfirmTitle, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text(
          context.l10n.deleteAccountConfirmDesc,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel, style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteUserDataAndAuth();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.l10n.deleteAccountConfirmButton, style: TextStyle(color: Theme.of(context).colorScheme.onError, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUserDataAndAuth() async {
    try {
      final String? uid = _uid;
      if (uid == null) return;

      // Delete history collections in Firestore first
      final scansCollection = FirebaseFirestore.instance.collection('users').doc(uid).collection('scan_history');
      final scans = await scansCollection.get();
      for (var doc in scans.docs) {
        await doc.reference.delete();
      }

      // Delete root user doc
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();

      // Delete Authentication account
      await _currentUser?.delete();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.deleteAccountError),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _navigateToScan() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ScanScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  void _openReportDetails(Map<String, dynamic> data) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ResultScreen(
          imagePath: data['imageUrl'] ?? '',
          score: data['score'] ?? 80,
          confidence: data['confidence'] ?? 95.0,
          indicators: data['detectedIssues'] ?? {},
          aiSummary: data['summary'] ?? '',
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }

  Widget _buildOverviewCard({
    required Color iconColor,
    required IconData icon,
    required String title,
    required String value,
    required String sub,
    required Widget child,
  }) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: AppColors.glassBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: AppColors.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileMetaCol(IconData icon, String label, String val) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(IconData icon, String title, String sub, Color circleBg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: AppColors.glassBorder,
        ),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleBg,
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: AppColors.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Your diagnostic metrics will appear here once scans are processed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final icons = [
      Icons.home_outlined,
      Icons.history,
      Icons.camera_alt_outlined,
      Icons.compass_calibration_outlined,
      Icons.person_outline,
    ];
    final labels = [context.l10n.home, context.l10n.history, context.l10n.scan, context.l10n.insights, context.l10n.profile];

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        height: 9.h,
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: AppColors.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final isScan = index == 2;
              final isSelected = _currentIndex == index;

              if (isScan) {
                return GestureDetector(
                  onTap: _navigateToScan,
                  child: Container(
                    height: 7.h,
                    width: 7.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.onPrimary, size: 24),
                  ),
                );
              }

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _currentIndex = index;
                  });
                },
                child: SizedBox(
                  width: 12.w,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icons[index],
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        size: 16.sp,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 8.sp,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
