import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/colors.dart';
import 'package:sizer/sizer.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/floating_gradients.dart';

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

  String _getConcernLabel(BuildContext context, String key) {
    final l10n = context.l10n;
    switch (key) {
      case 'Acne': return l10n.concernAcne;
      case 'Dullness': return l10n.concernDullness;
      case 'Wrinkles': return l10n.concernWrinkles;
      case 'Redness': return l10n.concernRedness;
      case 'Pores': return l10n.concernPores;
      case 'Uneven Tone': return l10n.concernUnevenTone;
      case 'Fine Lines': return l10n.concernWrinkles;
      case 'Dark Spots': return l10n.concernDarkCircles;
      case 'Dark Circles': return l10n.concernDarkCircles;
      case 'Pigmentation': return l10n.concernDarkCircles;
      default: return key;
    }
  }

  String _getSeverityLabel(BuildContext context, int severity) {
    final l10n = context.l10n;
    if (severity <= 35) return l10n.severityMild;
    if (severity <= 70) return l10n.severityModerate;
    return l10n.severitySevere;
  }

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
    final l10n = context.l10n;
    try {
      HapticFeedback.lightImpact();
      final pdf = pw.Document();
      final sortedConcerns = widget.indicators.keys.toList()
        ..sort((a, b) => (widget.indicators[b]['severity'] as int).compareTo(widget.indicators[a]['severity'] as int));
      final top3 = sortedConcerns.take(3).toList();
      final dynamicSummary = _generateDynamicSummary(context);
      final morningR = _generateMorningRoutine(context, top3);
      final nightR = _generateNightRoutine(context, top3);
      
      String badgeText = l10n.healthy;
      if (widget.score >= 88) {
        badgeText = l10n.healthy;
      } else if (_previousScore != null && widget.score > _previousScore!) {
        badgeText = l10n.improving;
      } else if (widget.score >= 68) {
        badgeText = l10n.needsAttention;
      } else {
        badgeText = l10n.highConcern;
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context pdfContext) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(32),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(l10n.pdfReportTitle,
                      style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(l10n.pdfReportSub,
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  pw.Divider(thickness: 1.5, color: PdfColors.grey400),
                  pw.SizedBox(height: 20),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(l10n.pdfScoreText.replaceAll('{value}', '${widget.score}').replaceAll('{badge}', badgeText),
                              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                          pw.Text(l10n.pdfConfidenceText.replaceAll('{value}', widget.confidence.toStringAsFixed(1))),
                        ],
                      ),
                      pw.Text(DateTime.now().toLocal().toString().substring(0, 16)),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  pw.Text(l10n.pdfSummaryHeader,
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 6),
                  pw.Text(dynamicSummary, style: const pw.TextStyle(fontSize: 11, lineSpacing: 1.3)),
                  pw.SizedBox(height: 24),
                  pw.Text(l10n.pdfConcernsHeader,
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  ...top3.map((key) {
                    final data = widget.indicators[key];
                    return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Bullet(
                        text: "${_getConcernLabel(context, key)}: ${data['severity']}% Severity - ${data['desc']}",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    );
                  }),
                  pw.SizedBox(height: 24),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 10),
                  pw.Text(l10n.pdfRoutineHeader,
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text("${l10n.morningRoutine}:\n$morningR",
                      style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.2)),
                  pw.SizedBox(height: 8),
                  pw.Text("${l10n.nightRoutine}:\n$nightR",
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
      await Share.shareXFiles([XFile(file.path)], text: l10n.pdfShareText);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.unableToGeneratePdf)),
      );
    }
  }

  // Controlled Firestore saving with custom success animations and error translations
  Future<void> _saveReportToFirestore() async {
    final l10n = context.l10n;
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
      String errorMessage = l10n.unableToSaveReport;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
        ),
      );
    }
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

  String _generateDynamicSummary(BuildContext context) {
    final l10n = context.l10n;
    final List<String> summaryPoints = [];
    final acne = widget.indicators['Acne']?['severity'] ?? 0;
    final darkCircles = widget.indicators['Dark Circles']?['severity'] ?? 0;
    final pigmentation = widget.indicators['Pigmentation']?['severity'] ?? 0;
    final redness = widget.indicators['Redness']?['severity'] ?? 0;
    final texture = widget.indicators['Texture']?['severity'] ?? 0;

    if (acne > 60) {
      summaryPoints.add(l10n.summaryBreakoutSevere);
    } else if (acne > 30) {
      summaryPoints.add(l10n.summaryAcneModerate);
    }

    if (darkCircles > 50) {
      summaryPoints.add(l10n.summaryDarkCirclesProminent);
    }

    if (pigmentation > 50) {
      summaryPoints.add(l10n.summaryPigmentationSPF);
    }

    if (redness > 50) {
      summaryPoints.add(l10n.summaryRednessCalming);
    }

    if (texture > 50) {
      summaryPoints.add(l10n.summaryTextureExfoliation);
    }

    if (summaryPoints.isEmpty) {
      summaryPoints.add(l10n.summaryHealthyBalanced);
    }

    return summaryPoints.join(" ");
  }

  String _generateMorningRoutine(BuildContext context, List<String> top3Concerns) {
    final l10n = context.l10n;
    List<String> morningSteps = [l10n.cleanseMildFaceWash];
    for (String concern in top3Concerns) {
      final severity = widget.indicators[concern]?['severity'] ?? 0;
      if (concern == 'Acne') {
        if (severity <= 30) {
          morningSteps.add(l10n.acneMildMorning);
        } else if (severity <= 60) {
          morningSteps.add(l10n.acneModerateMorning);
        } else {
          morningSteps.add(l10n.acneSevereMorning);
        }
      } else if (concern == 'Dark Circles' || concern == 'Pigmentation' && !top3Concerns.contains('Dark Circles')) {
        // map based on key
        if (concern == 'Dark Circles') {
          morningSteps.add(l10n.darkCirclesMorning1);
          morningSteps.add(l10n.darkCirclesMorning2);
        } else {
          morningSteps.add(l10n.pigmentationMorning1);
          morningSteps.add(l10n.pigmentationMorning2);
        }
      } else if (concern == 'Pigmentation') {
        morningSteps.add(l10n.pigmentationMorning1);
        morningSteps.add(l10n.pigmentationMorning2);
      } else if (concern == 'Redness') {
        morningSteps.add(l10n.rednessMorning1);
        morningSteps.add(l10n.rednessMorning2);
      } else if (concern == 'Texture') {
        morningSteps.add(l10n.textureMorning1);
        morningSteps.add(l10n.textureMorning2);
      }
    }
    return morningSteps.asMap().entries.map((e) => "${e.key + 1}. ${e.value}").join("\n");
  }

  String _generateNightRoutine(BuildContext context, List<String> top3Concerns) {
    final l10n = context.l10n;
    List<String> nightSteps = [l10n.doubleCleanse];
    for (String concern in top3Concerns) {
      final severity = widget.indicators[concern]?['severity'] ?? 0;
      if (concern == 'Acne') {
        if (severity <= 30) {
          nightSteps.add(l10n.acneMildNight);
        } else if (severity <= 60) {
          nightSteps.add(l10n.acneModerateNight);
        } else {
          nightSteps.add(l10n.acneSevereNight);
        }
      } else if (concern == 'Dark Circles') {
        nightSteps.add(l10n.darkCirclesNight1);
        nightSteps.add(l10n.darkCirclesNight2);
      } else if (concern == 'Pigmentation') {
        nightSteps.add(l10n.pigmentationNight);
      } else if (concern == 'Redness') {
        nightSteps.add(l10n.rednessNight1);
        nightSteps.add(l10n.rednessNight2);
      } else if (concern == 'Texture') {
        nightSteps.add(l10n.textureNight);
      }
    }
    return nightSteps.asMap().entries.map((e) => "${e.key + 1}. ${e.value}").join("\n");
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sortedConcerns = widget.indicators.keys.toList()
      ..sort((a, b) => (widget.indicators[b]['severity'] as int).compareTo(widget.indicators[a]['severity'] as int));
    final top3Concerns = sortedConcerns.take(3).toList();
    final dynamicSummary = _generateDynamicSummary(context);
    final morningR = _generateMorningRoutine(context, top3Concerns);
    final nightR = _generateNightRoutine(context, top3Concerns);

    String badgeText = l10n.healthy;
    if (widget.score >= 88) {
      badgeText = l10n.healthy;
    } else if (_previousScore != null && widget.score > _previousScore!) {
      badgeText = l10n.improving;
    } else if (widget.score >= 68) {
      badgeText = l10n.needsAttention;
    } else {
      badgeText = l10n.highConcern;
    }
    final activeDetails = widget.indicators[_activeConcern];
    final bool hasLocalFile = widget.imagePath.isNotEmpty && File(widget.imagePath).existsSync();
    final ImageProvider faceImage = hasLocalFile
        ? FileImage(File(widget.imagePath))
        : const NetworkImage(
            'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=400&q=80',
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
                          children: [
                            Text(
                              l10n.scanResults,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              l10n.aiAnalysisReport,
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
                                Text(
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
                                    Text(
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
                                height: 10.h,
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
                                    _getSeverityLabel(context, 100 - widget.score),
                                    style: TextStyle(
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
                                    Text(
                                      l10n.beforeVsAfterTrend,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _previousScore != null
                                          ? l10n.trendComparison.replaceAll('{value}', '${widget.score - _previousScore! >= 0 ? "+" : ""}${widget.score - _previousScore!}').replaceAll('{prev}', '$_previousScore')
                                          : l10n.initialBaselineReport,
                                      style: TextStyle(
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
                        Text(
                          l10n.indicatorSeverityDetails,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          l10n.analyzedCount.replaceAll('{count}', '${widget.indicators.length}'),
                          style: TextStyle(
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
                          height: 25.h,
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
                                          height: 3.h,
                                          width: 24,
                                          alignment: Alignment.center,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              if (isSelected)
                                                AnimatedContainer(
                                                  duration: const Duration(milliseconds: 300),
                                                  height: 2.7.h,
                                                  width: 22,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: markerColor, width: 2.0),
                                                  ),
                                                ),
                                              Container(
                                                height: 1.2.h,
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
                            height: 25.h,
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
                                              height: 0.8.h,
                                              width: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: markerColor,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                _getConcernLabel(context, key),
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
                            children: [
                              Icon(Icons.priority_high, color: AppColors.primary, size: 16),
                              SizedBox(width: 8),
                              Text(
                                l10n.primaryConcernsMapped,
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
                                      _getConcernLabel(context, concern),
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
                                          l10n.severityDetailPrefix.replaceAll('{value}', '$severity').replaceAll('{label}', _getSeverityLabel(context, severity)),
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          data['desc'],
                                          style: TextStyle(
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
                            children: [
                              Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
                              SizedBox(width: 8),
                              Text(
                                l10n.aiSummaryTitle,
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
                            style: TextStyle(
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
                    Text(
                      l10n.dailyRoutineSuggestions,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildRoutineCard(
                      Icons.wb_sunny_outlined,
                      l10n.morningRoutine,
                      morningR,
                    ),
                    _buildRoutineCard(
                      Icons.nights_stay_outlined,
                      l10n.nightRoutine,
                      nightR,
                    ),
                    const SizedBox(height: 24),

                    // Save actions
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 6.h,
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
                              child: Text(l10n.scanAgain, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            height: 6.h,
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
                              child: Text(l10n.saveReport, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                child: Center(
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
                          height: 11.h,
                          width: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: const Icon(Icons.check, size: 54, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.reportSaved,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.addedToHistory,
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
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
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
