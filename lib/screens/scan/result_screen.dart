import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/colors.dart';
import '../../theme/floating_gradients.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final int score;
  final double confidence;
  final Map<String, dynamic> indicators;
  final String aiSummary;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.score,
    required this.confidence,
    required this.indicators,
    required this.aiSummary,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  String _activeConcern = 'Acne';
  bool _isSaving = false;
  bool _saveSuccess = false;
  int? _previousScore;
  bool _loadingBaseline = true;

  late AnimationController _successController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
    _fetchBaselineScan();
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  // Compare scan results with the previous baseline report in Firestore
  Future<void> _fetchBaselineScan() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingBaseline = false);
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scan_history')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        setState(() {
          _previousScore = data['score'];
          _loadingBaseline = false;
        });
      } else {
        setState(() => _loadingBaseline = false);
      }
    } catch (e) {
      setState(() => _loadingBaseline = false);
    }
  }

  // Generate premium medical PDF report & invoke share sheet
  Future<void> _exportPdfReport() async {
    try {
      HapticFeedback.lightImpact();
      final pdf = pw.Document();
      final sortedConcerns = widget.indicators.keys.toList()
        ..sort((a, b) => (widget.indicators[b]['severity'] as int).compareTo(widget.indicators[a]['severity'] as int));
      final top3 = sortedConcerns.take(3).toList();
      final dynamicSummary = _generateDynamicSummary();
      final morningR = _generateMorningRoutine(top3);
      final nightR = _generateNightRoutine(top3);
      
      String badgeText = "Healthy";
      if (widget.score >= 88) {
        badgeText = "Healthy";
      } else if (_previousScore != null && widget.score > _previousScore!) {
        badgeText = "Improving";
      } else if (widget.score >= 68) {
        badgeText = "Needs Attention";
      } else {
        badgeText = "High Concern";
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("SkinAI Diagnostic Report",
                      style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text("Medical-Grade Skin Intelligence Analysis",
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  pw.Divider(thickness: 1.5, color: PdfColors.grey400),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Skin Score: ${widget.score} / 100 ($badgeText)",
                              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.Text("Analysis Confidence: ${widget.confidence.toStringAsFixed(1)}%"),
                        ],
                      ),
                      pw.Text(DateTime.now().toLocal().toString().substring(0, 16)),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  pw.Text("AI Diagnostic Summary:",
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Text(dynamicSummary, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.3)),
                  pw.SizedBox(height: 24),
                  pw.Text("Primary Concerns Mapped:",
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  ...top3.map((key) {
                    final data = widget.indicators[key];
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Bullet(
                        text: "$key: ${data['severity']}% Severity - ${data['desc']}",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    );
                  }),
                  pw.SizedBox(height: 24),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 10),
                  pw.Text("Recommended Routine Suggestion (Dynamic):",
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text("Morning Routine:\n$morningR",
                      style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.2)),
                  pw.SizedBox(height: 8),
                  pw.Text("Night Routine:\n$nightR",
                      style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.2)),
                ],
              ),
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File("${output.path}/skinai_medical_report.pdf");
      await file.writeAsBytes(await pdf.save());
      
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: "Check out my SkinAI diagnostic report.");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to generate PDF. Please try again.")),
      );
    }
  }

  // Controlled Firestore saving with custom success animations and error translations
  Future<void> _saveReportToFirestore() async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      HapticFeedback.mediumImpact();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('scan_history')
          .add({
        'imageUrl': widget.imagePath,
        'score': widget.score,
        'confidence': widget.confidence,
        'detectedIssues': widget.indicators,
        'summary': widget.aiSummary,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSaving = false;
        _saveSuccess = true;
      });
      HapticFeedback.heavyImpact();
      _successController.forward();

      // Auto redirect back to HomeScreen after celebration completes
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (!mounted) return;
        Navigator.of(context).pop(); // returns home
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      // Error Translation: friendly errors only. Never expose raw firebase codes
      String errorMessage = "Unable to save your report. Please try again.";
      if (e.toString().contains("permission-denied") || e.toString().contains("PERMISSION_DENIED")) {
        errorMessage = "Unable to save your report. Please try again.";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _getSeverityLabel(int severity) {
    if (severity <= 35) return 'Mild';
    if (severity <= 70) return 'Moderate';
    return 'Severe';
  }

  Color _getBadgeColor(String badge) {
    switch (badge) {
      case 'Healthy':
        return Colors.green;
      case 'Improving':
        return AppColors.primary;
      case 'Needs Attention':
        return Colors.orange;
      case 'High Concern':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  String _generateDynamicSummary() {
    final List<String> summaryPoints = [];
    final acne = widget.indicators['Acne']?['severity'] ?? 0;
    final darkCircles = widget.indicators['Dark Circles']?['severity'] ?? 0;
    final pigmentation = widget.indicators['Pigmentation']?['severity'] ?? 0;
    final redness = widget.indicators['Redness']?['severity'] ?? 0;
    final texture = widget.indicators['Texture']?['severity'] ?? 0;

    if (acne > 60) {
      summaryPoints.add("Severe breakout activity detected. Focus on dermatologist guidance and avoid active ingredient conflicts.");
    } else if (acne > 30) {
      summaryPoints.add("Moderate acne and pore blockage identified. Salicylic Acid and Niacinamide can target excess sebum.");
    }

    if (darkCircles > 50) {
      summaryPoints.add("Prominent dark circles present. Focus on improving sleep quality, hydration, and reducing blue-light exposure.");
    }

    if (pigmentation > 50) {
      summaryPoints.add("Hyperpigmentation is one of the primary concerns requiring consistent daily SPF 50+ sunscreen.");
    }

    if (redness > 50) {
      summaryPoints.add("Elevated redness detected. Focus on calming and barrier repair.");
    }

    if (texture > 50) {
      summaryPoints.add("Uneven micro-texture observed. Focus on gentle chemical exfoliation and deep hydration support.");
    }

    if (summaryPoints.isEmpty) {
      summaryPoints.add("Your skin barrier shows highly balanced overall health. Focus on preventative sunscreen layers and hydration support.");
    }

    return summaryPoints.join(" ");
  }

  String _generateMorningRoutine(List<String> top3Concerns) {
    List<String> morningSteps = ["Cleanse with a mild pH-balanced face wash"];
    for (String concern in top3Concerns) {
      final severity = widget.indicators[concern]?['severity'] ?? 0;
      if (concern == 'Acne') {
        if (severity <= 30) {
          morningSteps.add("Gentle Cleanser (Mild acne care) + Salicylic Acid 2x weekly");
        } else if (severity <= 60) {
          morningSteps.add("Salicylic Acid cleanser (Moderate breakout target) + Niacinamide serum");
        } else {
          morningSteps.add("Gentle non-foaming wash (Severe acne - avoid active conflicts)");
        }
      } else if (concern == 'Dark Circles') {
        morningSteps.add("Apply Caffeine eye serum to reduce puffiness");
        morningSteps.add("Hydration booster reminder (Drink 500ml water)");
      } else if (concern == 'Pigmentation') {
        morningSteps.add("Vitamin C serum (antioxidant shield)");
        morningSteps.add("Daily SPF 50+ broad-spectrum sunscreen");
      } else if (concern == 'Redness') {
        morningSteps.add("Barrier repair moisturizer (avoid harsh exfoliants)");
        morningSteps.add("Centella / Ceramide calming products");
      } else if (concern == 'Texture') {
        morningSteps.add("Gentle exfoliation (mild enzymatic scrub)");
        morningSteps.add("Hydration support serum");
      }
    }
    return morningSteps.asMap().entries.map((e) => "${e.key + 1}. ${e.value}").join("\n");
  }

  String _generateNightRoutine(List<String> top3Concerns) {
    List<String> nightSteps = ["Thorough double cleanse"];
    for (String concern in top3Concerns) {
      final severity = widget.indicators[concern]?['severity'] ?? 0;
      if (concern == 'Acne') {
        if (severity <= 30) {
          nightSteps.add("Salicylic Acid 2x weekly (Spot treatment)");
        } else if (severity <= 60) {
          nightSteps.add("Niacinamide serum (Soothes inflammation)");
        } else {
          nightSteps.add("Dermatologist prescription consultation required (Severe acne)");
        }
      } else if (concern == 'Dark Circles') {
        nightSteps.add("Caffeine eye cream + Reduce blue-light screen exposure");
        nightSteps.add("Increase sleep recommendation (min 8 hours)");
      } else if (concern == 'Pigmentation') {
        nightSteps.add("Niacinamide (reduces hyperpigmentation transfer) + Brightening ingredients");
      } else if (concern == 'Redness') {
        nightSteps.add("Avoid harsh exfoliants (Calm active redness)");
        nightSteps.add("Ceramide cream to rebuild barrier");
      } else if (concern == 'Texture') {
        nightSteps.add("Retinol treatment to accelerate cell turnover");
      }
    }
    return nightSteps.asMap().entries.map((e) => "${e.key + 1}. ${e.value}").join("\n");
  }

  @override
  Widget build(BuildContext context) {
    final sortedConcerns = widget.indicators.keys.toList()
      ..sort((a, b) => (widget.indicators[b]['severity'] as int).compareTo(widget.indicators[a]['severity'] as int));
    final top3Concerns = sortedConcerns.take(3).toList();
    final dynamicSummary = _generateDynamicSummary();
    final morningR = _generateMorningRoutine(top3Concerns);
    final nightR = _generateNightRoutine(top3Concerns);

    String badgeText = "Healthy";
    if (widget.score >= 88) {
      badgeText = "Healthy";
    } else if (_previousScore != null && widget.score > _previousScore!) {
      badgeText = "Improving";
    } else if (widget.score >= 68) {
      badgeText = "Needs Attention";
    } else {
      badgeText = "High Concern";
    }
    final activeDetails = widget.indicators[_activeConcern];
    final bool hasLocalFile = widget.imagePath.isNotEmpty && File(widget.imagePath).existsSync();
    final ImageProvider faceImage = hasLocalFile
        ? FileImage(File(widget.imagePath))
        : const NetworkImage(
            'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=400&q=80',
          ) as ImageProvider;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          AmbientGlowBackground(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.of(context).pop();
                          },
                        ),
                        Column(
                          children: const [
                            Text(
                              'Scan Results',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'AI Analysis Report',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.white, size: 22),
                          onPressed: _exportPdfReport,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Medical Score Card with Confidence Score
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: AppColors.glassBorder,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Skin Score Indicator',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${widget.score}',
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      '/ 100',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getBadgeColor(badgeText).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _getBadgeColor(badgeText).withValues(alpha: 0.25),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: TextStyle(
                                          color: _getBadgeColor(badgeText),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Analysis Confidence: ${widget.confidence.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                height: 80,
                                width: 80,
                                child: CircularProgressIndicator(
                                  value: widget.score / 100.0,
                                  strokeWidth: 6,
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  color: AppColors.primary,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${widget.score}',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _getSeverityLabel(100 - widget.score),
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Before vs After Comparison Card
                    if (!_loadingBaseline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(20),
                            border: AppColors.glassBorder,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _previousScore != null && widget.score >= _previousScore!
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _previousScore != null && widget.score >= _previousScore!
                                      ? Icons.trending_up
                                      : Icons.trending_flat,
                                  color: _previousScore != null && widget.score >= _previousScore!
                                      ? Colors.green
                                      : Colors.orange,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Before vs After Trend',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _previousScore != null
                                          ? 'Skin score changed by ${widget.score - _previousScore! >= 0 ? '+' : ''}${widget.score - _previousScore!} points compared to previous scan score of $_previousScore.'
                                          : 'Initial baseline report. Scans saved in history will calculate comparison score trends.',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Annotated hotspots and list row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Indicator Severity Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${widget.indicators.length} analyzed',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Viewport image showing real face coordinates
                        Container(
                          width: 160,
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image(
                                    image: faceImage,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                // Hotspot markers positioned by actual landmarks
                                ...widget.indicators.keys.expand((key) {
                                  final isSelected = _activeConcern == key;
                                  final data = widget.indicators[key];
                                  final List<dynamic> spots = data['spots'];
                                  final Color markerColor = Color(int.parse(data['color'].replaceAll('#', '0xFF')));

                                  return spots.map((spot) {
                                    final double spotX = spot['x'] ?? 0.5;
                                    final double spotY = spot['y'] ?? 0.5;

                                    return Positioned(
                                      left: spotX * 160 - 12.0,
                                      top: spotY * 220 - 12.0,
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          setState(() {
                                            _activeConcern = key;
                                          });
                                        },
                                        child: Container(
                                          height: 24,
                                          width: 24,
                                          alignment: Alignment.center,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              if (isSelected)
                                                AnimatedContainer(
                                                  duration: const Duration(milliseconds: 300),
                                                  height: 22,
                                                  width: 22,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: markerColor, width: 2.0),
                                                  ),
                                                ),
                                              Container(
                                                height: 10,
                                                width: 10,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: isSelected ? markerColor : Colors.white,
                                                  border: Border.all(
                                                    color: isSelected ? Colors.white : markerColor,
                                                    width: 1.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  });
                                }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Severity Progress list
                        Expanded(
                          child: SizedBox(
                            height: 220,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: widget.indicators.keys.map((key) {
                                final isSelected = _activeConcern == key;
                                final data = widget.indicators[key];
                                final int severity = data['severity'];
                                final Color markerColor = Color(int.parse(data['color'].replaceAll('#', '0xFF')));

                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _activeConcern = key;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.card : AppColors.card.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: isSelected
                                          ? Border.all(color: Colors.white.withValues(alpha: 0.05))
                                          : Border.all(color: Colors.transparent),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              height: 6,
                                              width: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: markerColor,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                key,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '$severity%',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(3),
                                          child: LinearProgressIndicator(
                                            value: severity / 100.0,
                                            minHeight: 4,
                                            backgroundColor: const Color(0xFF262A34),
                                            color: markerColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Context description
                    if (activeDetails != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(int.parse(activeDetails['color'].replaceAll('#', '0xFF'))).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Color(int.parse(activeDetails['color'].replaceAll('#', '0xFF'))),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                activeDetails['desc'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Primary Skin Concerns Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.card.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(22),
                        border: AppColors.glassBorder,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.priority_high, color: AppColors.primary, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Primary Concerns Mapped',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...top3Concerns.map((concern) {
                            final data = widget.indicators[concern];
                            final int severity = data['severity'];
                            final Color markerColor = Color(int.parse(data['color'].replaceAll('#', '0xFF')));

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: markerColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      concern,
                                      style: TextStyle(
                                        color: markerColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Severity: $severity% • ${_getSeverityLabel(severity)}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          data['desc'],
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // AI Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(22),
                        border: AppColors.glassBorder,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'AI Summary',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            dynamicSummary,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Daily Routine Suggestions
                    const Text(
                      'Daily Routine Suggestions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildRoutineCard(
                      Icons.wb_sunny_outlined,
                      'Morning Routine',
                      morningR,
                    ),
                    _buildRoutineCard(
                      Icons.nights_stay_outlined,
                      'Night Routine',
                      nightR,
                    ),
                    const SizedBox(height: 24),

                    // Save actions
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                backgroundColor: Colors.white.withValues(alpha: 0.02),
                              ),
                              child: const Text('Scan Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ElevatedButton(
                              onPressed: _saveReportToFirestore,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              child: const Text('Save Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Blur loading backdrop
          if (_isSaving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),

          // Celebrate overlay success animation
          if (_saveSuccess)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 90,
                          width: 90,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: const Icon(Icons.check, size: 54, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Report Saved!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Added to your scan history log',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
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

  Widget _buildRoutineCard(IconData icon, String title, String instructions) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: AppColors.glassBorder,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    instructions,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
