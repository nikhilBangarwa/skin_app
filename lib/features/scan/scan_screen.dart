import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../../core/localization/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/colors.dart';
import 'package:sizer/sizer.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/floating_gradients.dart';
import 'processing_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCameraSwitching = false;
  bool _isFlashOn = false;
  bool _hasCameraHardware = true;
  CameraLensDirection _currentLensDirection = CameraLensDirection.front;

  // Selected image from gallery preview path
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Find front camera or default to first camera
        CameraDescription selectedCam = _cameras!.firstWhere(
          (cam) => cam.lensDirection == _currentLensDirection,
          orElse: () => _cameras!.first,
        );
        _currentLensDirection = selectedCam.lensDirection;

        _cameraController = CameraController(
          selectedCam,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      } else {
        setState(() {
          _hasCameraHardware = false;
        });
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
      setState(() {
        _hasCameraHardware = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // Proper front/rear lens switching
  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isCameraSwitching = true;
      _isCameraInitialized = false;
    });

    await _cameraController?.dispose();

    // Toggle lens direction
    _currentLensDirection = _currentLensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    CameraDescription selectedCam = _cameras!.firstWhere(
      (cam) => cam.lensDirection == _currentLensDirection,
      orElse: () => _cameras!.first,
    );

    _cameraController = CameraController(
      selectedCam,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraSwitching = false;
        });
      }
    } catch (e) {
      debugPrint("Camera switch error: $e");
      if (mounted) {
        setState(() {
          _isCameraSwitching = false;
          _hasCameraHardware = false;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    // If the user selected a gallery image, trigger analysis directly on it
    if (_selectedImagePath != null) {
      _triggerAnalysis(_selectedImagePath!);
      return;
    }

    if (!_isCameraInitialized || _cameraController == null) {
      _selectFromGallery();
      return;
    }

    try {
      HapticFeedback.mediumImpact();
      final XFile file = await _cameraController!.takePicture();
      _triggerAnalysis(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error capturing photo: $e")),
      );
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      HapticFeedback.lightImpact();
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      String friendlyError = "Error selecting image: ${e.message}";
      if (e.code == 'photo_access_denied') {
        friendlyError = "Gallery access denied. Please enable photos permission in settings.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  void _triggerAnalysis(String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(imagePath: path),
      ),
    );
  }

  Future<void> _toggleFlash() async {
    if (!_isCameraInitialized || _cameraController == null) return;
    try {
      HapticFeedback.lightImpact();
      _isFlashOn = !_isFlashOn;
      await _cameraController!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      debugPrint("Flash error: $e");
    }
  }

  void _clearSelectedImage() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedImagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double viewportHeight = MediaQuery.of(context).size.height * 0.44;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientGlowBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                
                // Top Header Row
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
                    Text(
                      context.l10n.scanYourFace,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: _isFlashOn ? AppColors.primary : Colors.white,
                        size: 22,
                      ),
                      onPressed: _hasCameraHardware && _selectedImagePath == null ? _toggleFlash : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.scanSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Viewport Container
                Container(
                  height: viewportHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.5),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      children: [
                        // Viewport image preview hierarchy:
                        // 1. Selected Image File if chosen
                        // 2. Switching Camera Loader
                        // 3. Camera Live Feed if initialized
                        // 4. Default Placeholder
                        Positioned.fill(
                          child: _selectedImagePath != null
                              ? Image.file(
                                  File(_selectedImagePath!),
                                  fit: BoxFit.cover,
                                )
                              : (_isCameraSwitching
                                  ? Container(
                                      color: Colors.black54,
                                      child: Center(
                                        child: CircularProgressIndicator(color: AppColors.primary),
                                      ),
                                    )
                                  : (_isCameraInitialized && _cameraController != null
                                      ? CameraPreview(_cameraController!)
                                      : Image.network(
                                          'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=400&q=80',
                                          fit: BoxFit.cover,
                                        ))),
                        ),

                        // Cancel preview overlay button
                        if (_selectedImagePath != null)
                          Positioned(
                            top: 14,
                            right: 14,
                            child: GestureDetector(
                              onTap: _clearSelectedImage,
                              child: Container(
                                height: 32,
                                width: 32,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),

                        // Alignment Brackets Guide (Only show if not previewing static file)
                        if (_selectedImagePath == null)
                          Center(
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: SizedBox(
                                width: 250,
                                height: 250,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(color: AppColors.primary, width: 3.5),
                                            left: BorderSide(color: AppColors.primary, width: 3.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(color: AppColors.primary, width: 3.5),
                                            right: BorderSide(color: AppColors.primary, width: 3.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(color: AppColors.primary, width: 3.5),
                                            left: BorderSide(color: AppColors.primary, width: 3.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(color: AppColors.primary, width: 3.5),
                                            right: BorderSide(color: AppColors.primary, width: 3.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: CustomPaint(
                                        painter: _DashedOvalPainter(
                                          color: AppColors.primary.withValues(alpha: 0.5),
                                        ),
                                        child: const SizedBox(
                                          width: 210,
                                          height: 220,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Guidance Text
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: Text(
                                _selectedImagePath != null
                                    ? context.l10n.imageSelected
                                    : (_isCameraInitialized
                                        ? context.l10n.positionFace
                                        : context.l10n.cameraOffline),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tips Section
                Text(
                  context.l10n.tipsTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTipCard(Icons.wb_sunny_outlined, context.l10n.tipLighting),
                    _buildTipCard(Icons.face_retouching_natural, context.l10n.tipCentered),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTipCard(Icons.auto_awesome_outlined, context.l10n.tipNoFilters),
                    _buildTipCard(Icons.remove_red_eye_outlined, context.l10n.tipNoGlasses),
                  ],
                ),
                const Spacer(),

                // Capture Controls row
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBottomAction(Icons.image_outlined, context.l10n.gallery, _selectFromGallery),

                      // Central Capture / Analyze Action Button
                      GestureDetector(
                        onTap: _capturePhoto,
                        child: Container(
                          width: 10.h,
                          height: 10.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.primaryGradient,
                              ),
                              child: Icon(
                                _selectedImagePath != null ? Icons.done : Icons.camera_alt,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Switching lens directions
                      _buildBottomAction(
                        Icons.cached,
                        context.l10n.flip,
                        _selectedImagePath == null ? _switchCamera : () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipCard(IconData icon, String text) {
    return Container(
      width: (MediaQuery.of(context).size.width - 50) / 2,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: AppColors.glassBorder,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 9.sp,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 15.w,
        child: Column(
          children: [
            Container(
              height: 6.h,
              width: 6.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Icon(icon, color: Colors.white, size: 16.sp),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.sp,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedOvalPainter extends CustomPainter {
  final Color color;

  _DashedOvalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = Rect.fromLTRB(0, 0, size.width, size.height);
    final path = Path()..addOval(rect);

    double dashWidth = 8.0;
    double dashSpace = 6.0;
    double distance = 0.0;
    
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        canvas.drawPath(
          measurePath.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
