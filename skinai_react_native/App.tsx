import React, { useState, useEffect, useRef } from 'react';
import {
  StyleSheet,
  Text,
  View,
  ScrollView,
  TouchableOpacity,
  Image,
  Dimensions,
  SafeAreaView,
  StatusBar,
  Animated,
  ActivityIndicator,
  Alert,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { BlurView } from 'expo-blur';
import * as Haptics from 'expo-haptics';
import Svg, { Circle, Path, Defs, LinearGradient as SvgGradient, Stop } from 'react-native-svg';
import {
  Camera,
  Compass,
  History as HistoryIcon,
  Home as HomeIcon,
  User as UserIcon,
  Bell,
  Sparkles,
  ChevronRight,
  TrendingUp,
  Droplet,
  Calendar,
  AlertTriangle,
  Moon,
  Sun,
  Layers,
  CheckCircle,
  Camera as CameraIcon,
  RefreshCw,
  Image as ImageIcon,
  Download,
  Info,
} from 'lucide-react-native';

const { width: SCREEN_WIDTH, height: SCREEN_HEIGHT } = Dimensions.get('window');

// Premium Dark Luxury Color Palette
const COLORS = {
  background: '#0F1115',
  card: '#1A1D24',
  primary: '#E89A8D',
  primaryDark: '#D67B6E',
  textPrimary: '#FFFFFF',
  textSecondary: '#B8B8B8',
  divider: '#262A34',
  error: '#E26A6A',
  success: '#8DE8B1',
};

// Reusable custom haptic helper
const triggerHaptic = (type: Haptics.ImpactFeedbackStyle = Haptics.ImpactFeedbackStyle.Light) => {
  try {
    Haptics.impactAsync(type);
  } catch (e) {
    console.log('Haptics not supported in environment');
  }
};

export default function App() {
  const [currentTab, setCurrentTab] = useState<'home' | 'history' | 'scan' | 'results' | 'insights' | 'profile'>('home');
  const [scanResult, setScanResult] = useState<any>(null);
  
  // Custom fade/slide animations on tab switch
  const fadeAnim = useRef(new Animated.Value(1)).current;

  const navigateTo = (tab: any) => {
    triggerHaptic(Haptics.ImpactFeedbackStyle.Light);
    Animated.timing(fadeAnim, {
      toValue: 0,
      duration: 150,
      useNativeDriver: true,
    }).start(() => {
      setCurrentTab(tab);
      Animated.timing(fadeAnim, {
        toValue: 1,
        duration: 250,
        useNativeDriver: true,
      }).start();
    });
  };

  return (
    <View style={styles.container}>
      <StatusBar barStyle="light-content" />
      
      {/* Background Ambient Glows */}
      <View style={styles.glowTopLeft} />
      <View style={styles.glowBottomRight} />

      <SafeAreaView style={styles.safeArea}>
        <Animated.View style={[styles.mainContent, { opacity: fadeAnim }]}>
          {currentTab === 'home' && <HomeScreen navigateTo={navigateTo} />}
          {currentTab === 'scan' && <ScanScreen navigateTo={navigateTo} setScanResult={setScanResult} />}
          {currentTab === 'results' && <ResultsScreen navigateTo={navigateTo} />}
          {currentTab === 'history' && <PlaceholderScreen title="Diagnostic History" icon={HistoryIcon} />}
          {currentTab === 'insights' && <PlaceholderScreen title="AI Insights Hub" icon={Compass} />}
          {currentTab === 'profile' && <PlaceholderScreen title="User Profile" icon={UserIcon} />}
        </Animated.View>

        {/* Floating Custom Bottom Tab Bar */}
        <BottomTabBar currentTab={currentTab} navigateTo={navigateTo} />
      </SafeAreaView>
    </View>
  );
}

// ==========================================
// HOME SCREEN COMPONENT
// ==========================================
function HomeScreen({ navigateTo }: { navigateTo: (tab: string) => void }) {
  return (
    <ScrollView 
      style={styles.scrollContainer} 
      showsVerticalScrollIndicator={false}
      contentContainerStyle={styles.scrollContent}
    >
      {/* Top Header */}
      <View style={styles.header}>
        <View>
          <View style={styles.brandRow}>
            <Text style={styles.brandText}>Skin</Text>
            <Text style={[styles.brandText, { color: COLORS.primary }]}>AI</Text>
          </View>
          <Text style={styles.subtext}>Your AI-Powered Skin Analyst</Text>
        </View>
        <View style={styles.headerActions}>
          <TouchableOpacity style={styles.iconButton} onPress={() => triggerHaptic()}>
            <Bell size={20} color="#FFFFFF" />
            <View style={styles.badge} />
          </TouchableOpacity>
          <Image
            source={{ uri: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=150&q=80' }}
            style={styles.avatar}
          />
        </View>
      </View>

      {/* Greeting & Score Circle in a Row */}
      <View style={styles.welcomeRow}>
        <View style={styles.welcomeTextContainer}>
          <Text style={styles.welcomeSubtitle}>Good Morning,</Text>
          <Text style={styles.welcomeTitle}>Nikhil Bangarwa 👋</Text>
          <Text style={styles.welcomeQuote}>Let's keep your skin healthy and glowing.</Text>
        </View>
        
        {/* Animated Circular Score Ring */}
        <TouchableOpacity 
          style={styles.scoreContainer}
          onPress={() => navigateTo('results')}
        >
          <Svg width={96} height={96} viewBox="0 0 100 100">
            <Defs>
              <SvgGradient id="scoreGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                <Stop offset="0%" stopColor={COLORS.primary} />
                <Stop offset="100%" stopColor={COLORS.primaryDark} />
              </SvgGradient>
            </Defs>
            {/* Background Ring Track */}
            <Circle
              cx="50"
              cy="50"
              r="40"
              stroke="#222630"
              strokeWidth="6"
              fill="transparent"
            />
            {/* Active Progress Ring */}
            <Circle
              cx="50"
              cy="50"
              r="40"
              stroke="url(#scoreGrad)"
              strokeWidth="6"
              fill="transparent"
              strokeDasharray="251.2"
              strokeDashoffset={251.2 - (251.2 * 82) / 100}
              strokeLinecap="round"
              transform="rotate(-90 50 50)"
            />
          </Svg>
          <View style={styles.scoreInnerContent}>
            <Text style={styles.scoreLabel}>Skin Score</Text>
            <Text style={styles.scoreNumber}>82</Text>
            <Text style={styles.scoreScale}>/ 100</Text>
            <Text style={styles.scoreStatus}>Good</Text>
          </View>
        </TouchableOpacity>
      </View>

      {/* Main Hero Scan Card */}
      <TouchableOpacity 
        style={styles.heroCard} 
        activeOpacity={0.95}
        onPress={() => navigateTo('scan')}
      >
        <LinearGradient
          colors={['#1F222A', '#13151B']}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.heroGradient}
        >
          {/* Card Border glow */}
          <View style={styles.heroBorder} />
          
          <View style={styles.heroContentLeft}>
            <View style={styles.heroLabelContainer}>
              <Sparkles size={12} color={COLORS.primary} />
              <Text style={styles.heroLabelText}>Ready to scan?</Text>
            </View>
            <Text style={styles.heroTitle}>Analyze Your Skin</Text>
            <Text style={styles.heroSubtitle}>
              Scan your face to get AI-powered insights and personalized recommendations.
            </Text>
            
            <View style={styles.heroButton}>
              <LinearGradient
                colors={[COLORS.primary, COLORS.primaryDark]}
                style={styles.heroButtonGradient}
              >
                <Text style={styles.heroButtonText}>Start Scan</Text>
                <ChevronRight size={16} color="#FFFFFF" />
              </LinearGradient>
            </View>
          </View>
          
          <View style={styles.heroContentRight}>
            <Image
              source={{ uri: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=300&q=80' }}
              style={styles.heroFaceImage}
            />
            {/* Simulated overlay scan lines */}
            <View style={styles.scanningDotGrid} />
          </View>
        </LinearGradient>
      </TouchableOpacity>

      {/* Overview Cards Row */}
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>Overview</Text>
        <TouchableOpacity onPress={() => triggerHaptic()}>
          <Text style={styles.viewAllText}>View All</Text>
        </TouchableOpacity>
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.overviewContainer}>
        {/* Card 1: Last Scan */}
        <BlurView intensity={20} tint="dark" style={styles.overviewCard}>
          <View style={styles.overviewHeader}>
            <View style={[styles.overviewIconContainer, { backgroundColor: '#3A2E2B' }]}>
              <Calendar size={16} color={COLORS.primary} />
            </View>
            <Text style={styles.overviewTitleText}>Last Scan</Text>
          </View>
          <Text style={styles.overviewValue}>May 20, 2025</Text>
          <Text style={styles.overviewSubvalue}>2 days ago</Text>
          
          <TouchableOpacity 
            style={styles.overviewButton}
            onPress={() => navigateTo('results')}
          >
            <Text style={styles.overviewButtonText}>View Result</Text>
            <ChevronRight size={12} color="#FFFFFF" />
          </TouchableOpacity>
        </BlurView>

        {/* Card 2: Skin Progress with Sparkline Chart */}
        <BlurView intensity={20} tint="dark" style={styles.overviewCard}>
          <View style={styles.overviewHeader}>
            <View style={[styles.overviewIconContainer, { backgroundColor: '#203A30' }]}>
              <TrendingUp size={16} color={COLORS.success} />
            </View>
            <Text style={styles.overviewTitleText}>Skin Progress</Text>
          </View>
          <View style={styles.progressRow}>
            <Text style={styles.overviewValue}>Improving</Text>
            <Text style={styles.progressPercentage}>+12%</Text>
          </View>
          <Text style={styles.overviewSubvalue}>this month</Text>
          
          {/* SVG Sparkline Sparkle chart */}
          <View style={styles.chartContainer}>
            <Svg width="120" height="30" viewBox="0 0 120 30">
              <Defs>
                <SvgGradient id="chartGrad" x1="0" y1="0" x2="0" y2="1">
                  <Stop offset="0%" stopColor={COLORS.primary} stopOpacity="0.4" />
                  <Stop offset="100%" stopColor={COLORS.primary} stopOpacity="0.0" />
                </SvgGradient>
              </Defs>
              <Path
                d="M0,25 Q20,10 40,20 T80,12 T120,5"
                fill="none"
                stroke={COLORS.primary}
                strokeWidth="2"
              />
              <Path
                d="M0,25 Q20,10 40,20 T80,12 T120,5 L120,30 L0,30 Z"
                fill="url(#chartGrad)"
              />
            </Svg>
          </View>
        </BlurView>

        {/* Card 3: Hydration */}
        <BlurView intensity={20} tint="dark" style={styles.overviewCard}>
          <View style={styles.overviewHeader}>
            <View style={[styles.overviewIconContainer, { backgroundColor: '#202E3A' }]}>
              <Droplet size={16} color="#8DCEE8" />
            </View>
            <Text style={styles.overviewTitleText}>Hydration</Text>
          </View>
          <Text style={styles.overviewValue}>Good</Text>
          <Text style={styles.overviewSubvalue}>68% water retention</Text>
          
          {/* Custom Sleek Progress Bar */}
          <View style={styles.progressBarBg}>
            <LinearGradient
              colors={['#8DCEE8', '#5EACCD']}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
              style={[styles.progressBarFill, { width: '68%' }]}
            />
          </View>
        </BlurView>
      </ScrollView>

      {/* Your Skin Profile */}
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>Your Skin Profile</Text>
        <TouchableOpacity onPress={() => triggerHaptic()}>
          <Text style={styles.viewAllText}>Edit Profile</Text>
        </TouchableOpacity>
      </View>

      <BlurView intensity={15} tint="dark" style={styles.profileSummaryCard}>
        {/* Type */}
        <View style={styles.profileMetaColumn}>
          <Droplet size={20} color={COLORS.primary} />
          <Text style={styles.profileMetaLabel}>Skin Type</Text>
          <Text style={styles.profileMetaValue}>Oily</Text>
        </View>
        <View style={styles.profileCardDivider} />
        
        {/* Concerns */}
        <View style={styles.profileMetaColumn}>
          <Layers size={20} color={COLORS.primary} />
          <Text style={styles.profileMetaLabel}>Concerns</Text>
          <Text style={styles.profileMetaValue}>3 Active</Text>
        </View>
        <View style={styles.profileCardDivider} />
        
        {/* Goals */}
        <View style={styles.profileMetaColumn}>
          <CheckCircle size={20} color={COLORS.primary} />
          <Text style={styles.profileMetaLabel}>Goals</Text>
          <Text style={styles.profileMetaValue}>Even Tone</Text>
        </View>
      </BlurView>

      {/* Quick Insights */}
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>Quick Insights</Text>
      </View>

      <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.insightsContainer}>
        {/* Insight 1 */}
        <TouchableOpacity style={styles.insightCard} activeOpacity={0.9} onPress={() => triggerHaptic()}>
          <View style={[styles.insightIconContainer, { backgroundColor: '#3A2925' }]}>
            <Sun size={20} color={COLORS.primary} />
          </View>
          <View style={styles.insightTextContainer}>
            <Text style={styles.insightTitle}>UV is high today</Text>
            <Text style={styles.insightSub}>Protect your skin with SPF 30+</Text>
          </View>
          <ChevronRight size={16} color={COLORS.textSecondary} />
        </TouchableOpacity>

        {/* Insight 2 */}
        <TouchableOpacity style={styles.insightCard} activeOpacity={0.9} onPress={() => triggerHaptic()}>
          <View style={[styles.insightIconContainer, { backgroundColor: '#202E3A' }]}>
            <Droplet size={20} color="#8DCEE8" />
          </View>
          <View style={styles.insightTextContainer}>
            <Text style={styles.insightTitle}>Hydration tip</Text>
            <Text style={styles.insightSub}>Drink 500ml water now for cell elasticity</Text>
          </View>
          <ChevronRight size={16} color={COLORS.textSecondary} />
        </TouchableOpacity>

        {/* Insight 3 */}
        <TouchableOpacity style={styles.insightCard} activeOpacity={0.9} onPress={() => triggerHaptic()}>
          <View style={[styles.insightIconContainer, { backgroundColor: '#2D203A' }]}>
            <Moon size={20} color="#C98DE8" />
          </View>
          <View style={styles.insightTextContainer}>
            <Text style={styles.insightTitle}>Sleep & Skin</Text>
            <Text style={styles.insightSub}>7-8 hours rest controls acne inflammation</Text>
          </View>
          <ChevronRight size={16} color={COLORS.textSecondary} />
        </TouchableOpacity>
      </ScrollView>

      {/* Extra spacing at the bottom to avoid tabbar overlaps */}
      <View style={{ height: 100 }} />
    </ScrollView>
  );
}

// ==========================================
// SCAN SCREEN COMPONENT (MOCK CAMERA PREVIEW + AI LASER)
// ==========================================
function ScanScreen({ navigateTo, setScanResult }: { navigateTo: (tab: string) => void; setScanResult: (result: any) => void }) {
  const [isScanning, setIsScanning] = useState(false);
  const [scanStatusText, setScanStatusText] = useState('');
  
  // Animation coordinates for scan line
  const laserAnim = useRef(new Animated.Value(-150)).current;
  const guidePulseAnim = useRef(new Animated.Value(1)).current;

  // Pulse animation on the camera guide frame
  useEffect(() => {
    Animated.loop(
      Animated.sequence([
        Animated.timing(guidePulseAnim, {
          toValue: 1.05,
          duration: 1000,
          useNativeDriver: true,
        }),
        Animated.timing(guidePulseAnim, {
          toValue: 1.0,
          duration: 1000,
          useNativeDriver: true,
        }),
      ])
    ).start();
  }, []);

  const handleCapture = () => {
    triggerHaptic(Haptics.ImpactFeedbackStyle.Medium);
    setIsScanning(true);
    
    // Animate scanning laser sweep
    laserAnim.setValue(-150);
    Animated.loop(
      Animated.sequence([
        Animated.timing(laserAnim, {
          toValue: 250,
          duration: 1200,
          useNativeDriver: true,
        }),
        Animated.timing(laserAnim, {
          toValue: -150,
          duration: 1200,
          useNativeDriver: true,
        }),
      ]),
      { iterations: 2 }
    ).start();

    // Stage text updates
    setTimeout(() => {
      setScanStatusText('Mapping face contours...');
      triggerHaptic(Haptics.ImpactFeedbackStyle.Light);
    }, 500);

    setTimeout(() => {
      setScanStatusText('Analyzing sebum levels...');
      triggerHaptic(Haptics.ImpactFeedbackStyle.Light);
    }, 1500);

    setTimeout(() => {
      setScanStatusText('Computing hydration parameters...');
      triggerHaptic(Haptics.ImpactFeedbackStyle.Light);
    }, 2800);

    setTimeout(() => {
      triggerHaptic(Haptics.ImpactFeedbackStyle.Heavy);
      setIsScanning(false);
      navigateTo('results');
    }, 4000);
  };

  return (
    <View style={styles.cameraWrapper}>
      {/* Header controls */}
      <View style={styles.cameraHeader}>
        <TouchableOpacity style={styles.backCircle} onPress={() => navigateTo('home')}>
          <ChevronRight size={22} color="#FFFFFF" style={{ transform: [{ rotate: '180deg' }] }} />
        </TouchableOpacity>
        <Text style={styles.cameraTitle}>Scan Your Face</Text>
        <TouchableOpacity style={styles.backCircle} onPress={() => triggerHaptic()}>
          <Sun size={20} color="#FFFFFF" />
        </TouchableOpacity>
      </View>

      <Text style={styles.cameraSub}>Get a clear analysis of your skin in just a few seconds.</Text>

      {/* Camera preview card layout */}
      <View style={styles.cameraViewportContainer}>
        {/* Placeholder image of user face */}
        <Image
          source={{ uri: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=400&q=80' }}
          style={styles.cameraPreviewImage}
        />
        
        {/* Animated Laser Sweep Line Overlay */}
        {isScanning && (
          <Animated.View style={[styles.laserLine, { transform: [{ translateY: laserAnim }] }]}>
            <LinearGradient
              colors={['transparent', COLORS.primary, 'transparent']}
              start={{ x: 0, y: 0 }}
              end={{ x: 0, y: 1 }}
              style={styles.laserGradient}
            />
          </Animated.View>
        )}

        {/* Pulsing Face Alignment Guide Brackets */}
        <Animated.View style={[styles.faceGuideFrame, { transform: [{ scale: guidePulseAnim }] }]}>
          {/* Top-Left Corner */}
          <View style={[styles.guideCorner, { top: 0, left: 0, borderTopWidth: 3, borderLeftWidth: 3 }]} />
          {/* Top-Right Corner */}
          <View style={[styles.guideCorner, { top: 0, right: 0, borderTopWidth: 3, borderRightWidth: 3 }]} />
          {/* Bottom-Left Corner */}
          <View style={[styles.guideCorner, { bottom: 0, left: 0, borderBottomWidth: 3, borderLeftWidth: 3 }]} />
          {/* Bottom-Right Corner */}
          <View style={[styles.guideCorner, { bottom: 0, right: 0, borderBottomWidth: 3, borderRightWidth: 3 }]} />
          
          <View style={styles.guideDottedFaceRing} />
        </Animated.View>

        {/* Analyzer Loading overlay */}
        {isScanning && (
          <BlurView intensity={70} tint="dark" style={styles.analyzerOverlay}>
            <ActivityIndicator size="large" color={COLORS.primary} />
            <Text style={styles.analyzerText}>{scanStatusText || 'Initializing AI Scan...'}</Text>
          </BlurView>
        )}

        <Text style={styles.guideText}>Position your face in the frame</Text>
      </View>

      {/* Quick instructions checklists */}
      <View style={styles.tipsSection}>
        <Text style={styles.tipsHeader}>Tips for best results</Text>
        <View style={styles.tipsGrid}>
          {/* Tip 1 */}
          <View style={styles.tipItem}>
            <View style={styles.tipIconCircle}>
              <Sun size={16} color={COLORS.primary} />
            </View>
            <Text style={styles.tipText}>Good Lighting</Text>
          </View>
          {/* Tip 2 */}
          <View style={styles.tipItem}>
            <View style={styles.tipIconCircle}>
              <UserIcon size={16} color={COLORS.primary} />
            </View>
            <Text style={styles.tipText}>Face Centered</Text>
          </View>
          {/* Tip 3 */}
          <View style={styles.tipItem}>
            <View style={styles.tipIconCircle}>
              <Sparkles size={16} color={COLORS.primary} />
            </View>
            <Text style={styles.tipText}>No Filters</Text>
          </View>
          {/* Tip 4 */}
          <View style={styles.tipItem}>
            <View style={styles.tipIconCircle}>
              <Layers size={16} color={COLORS.primary} />
            </View>
            <Text style={styles.tipText}>Remove Glasses</Text>
          </View>
        </View>
      </View>

      {/* Capture Actions row */}
      <View style={styles.captureActionsRow}>
        <TouchableOpacity style={styles.subActionButton} onPress={() => triggerHaptic()}>
          <ImageIcon size={22} color="#FFFFFF" />
          <Text style={styles.subActionLabel}>Gallery</Text>
        </TouchableOpacity>
        
        {/* Central Capture Gradient Button */}
        <TouchableOpacity 
          style={styles.mainCaptureOutline}
          activeOpacity={0.8}
          onPress={handleCapture}
        >
          <LinearGradient
            colors={[COLORS.primary, COLORS.primaryDark]}
            style={styles.mainCaptureInner}
          />
        </TouchableOpacity>
        
        <TouchableOpacity style={styles.subActionButton} onPress={() => triggerHaptic()}>
          <RefreshCw size={22} color="#FFFFFF" />
          <Text style={styles.subActionLabel}>Flip</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

// ==========================================
// RESULTS SCREEN COMPONENT (THE MOST IMPORTANT VIEW)
// ==========================================
function ResultsScreen({ navigateTo }: { navigateTo: (tab: string) => void }) {
  const [activeConcern, setActiveConcern] = useState<string>('Acne');
  
  // Concerns coordinates on the image coordinates for indicator positioning
  const annotations = [
    { name: 'Acne', top: '35%', left: '42%' },
    { name: 'Dark Circles', top: '48%', left: '33%' },
    { name: 'Pigmentation', top: '60%', left: '62%' },
    { name: 'Redness', top: '65%', left: '38%' },
    { name: 'Texture', top: '75%', left: '50%' },
  ];

  const concernDetails = {
    'Acne': { score: '35%', desc: 'Mild breakouts observed around forehead & cheeks.', color: '#FF7C7C' },
    'Dark Circles': { score: '60%', desc: 'Moderate dark circles. Consistent with sleep deprivation patterns.', color: '#BA7CFF' },
    'Pigmentation': { score: '40%', desc: 'Mild hyperpigmentation on right upper cheekbone.', color: '#FFAE7C' },
    'Redness': { score: '25%', desc: 'Very light redness on the chin region.', color: '#FF7C93' },
    'Texture': { score: '30%', desc: 'Slight congestion and uneven texture across the nose bridge.', color: '#7CFF93' },
  };

  const handleSave = () => {
    triggerHaptic(Haptics.ImpactFeedbackStyle.Medium);
    Alert.alert('Save Successful', 'Your diagnostic scan has been saved to your local SkinAI History.');
  };

  return (
    <ScrollView 
      style={styles.scrollContainer} 
      showsVerticalScrollIndicator={false}
      contentContainerStyle={styles.scrollContent}
    >
      {/* Header */}
      <View style={styles.resultsHeader}>
        <TouchableOpacity style={styles.backCircle} onPress={() => navigateTo('home')}>
          <ChevronRight size={22} color="#FFFFFF" style={{ transform: [{ rotate: '180deg' }] }} />
        </TouchableOpacity>
        <View style={styles.resultsHeaderTitles}>
          <Text style={styles.resultsTitle}>Scan Results</Text>
          <Text style={styles.resultsSubtitle}>May 27, 2025 • 09:41 AM</Text>
        </View>
        <TouchableOpacity style={styles.backCircle} onPress={() => triggerHaptic()}>
          <Download size={20} color="#FFFFFF" />
        </TouchableOpacity>
      </View>

      {/* Overall Score and Description row */}
      <BlurView intensity={20} tint="dark" style={styles.overallScoreCard}>
        <View style={styles.scoreTextCol}>
          <Text style={styles.scoreCardTitle}>Your Skin Score</Text>
          <View style={styles.scoreRow}>
            <Text style={styles.resultsScoreVal}>82</Text>
            <Text style={styles.resultsScoreScale}>/ 100</Text>
          </View>
          <Text style={styles.scoreCardComment}>Great job! Keep it up 💪</Text>
        </View>

        {/* Circular Progress Indicator matching mockup */}
        <View style={styles.resultsRadialContainer}>
          <Svg width={80} height={80} viewBox="0 0 100 100">
            <Circle
              cx="50"
              cy="50"
              r="40"
              stroke="#262A34"
              strokeWidth="6"
              fill="transparent"
            />
            <Circle
              cx="50"
              cy="50"
              r="40"
              stroke={COLORS.primary}
              strokeWidth="6"
              fill="transparent"
              strokeDasharray="251.2"
              strokeDashoffset={251.2 - (251.2 * 82) / 100}
              strokeLinecap="round"
              transform="rotate(-90 50 50)"
            />
          </Svg>
          <View style={styles.resultsRadialLabelContainer}>
            <Text style={styles.resultsRadialVal}>82</Text>
            <Text style={styles.resultsRadialComment}>Good</Text>
          </View>
        </View>
      </BlurView>

      {/* Interactive Annotated Image Section */}
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>Skin Concerns</Text>
        <Text style={styles.resultsConcernsCount}>5 detected</Text>
      </View>

      <View style={styles.annotatedSection}>
        {/* Face Image Frame */}
        <View style={styles.faceAnnotatedContainer}>
          <Image
            source={{ uri: 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&w=400&q=80' }}
            style={styles.faceAnnotatedImage}
          />
          
          {/* Render Annotation Hotspot Markers */}
          {annotations.map((ann) => {
            const isSelected = activeConcern === ann.name;
            return (
              <TouchableOpacity
                key={ann.name}
                style={[
                  styles.annotationMarker,
                  { top: ann.top, left: ann.left },
                  isSelected && styles.annotationMarkerActive,
                ]}
                onPress={() => {
                  triggerHaptic();
                  setActiveConcern(ann.name);
                }}
              >
                <View style={[styles.markerDot, isSelected && styles.markerDotActive]} />
                {isSelected && (
                  <View style={styles.markerPulseRing} />
                )}
              </TouchableOpacity>
            );
          })}
        </View>

        {/* Severity Bars Column */}
        <View style={styles.severitySection}>
          {Object.keys(concernDetails).map((key) => {
            const isSelected = activeConcern === key;
            const details = (concernDetails as any)[key];
            
            return (
              <TouchableOpacity
                key={key}
                style={[styles.severityItem, isSelected && styles.severityItemActive]}
                onPress={() => {
                  triggerHaptic();
                  setActiveConcern(key);
                }}
              >
                <View style={styles.severityLabelRow}>
                  <View style={styles.severityDotName}>
                    <View style={[styles.smallSeverityDot, { backgroundColor: details.color }]} />
                    <Text style={[styles.severityName, isSelected && { fontWeight: 'bold', color: '#FFFFFF' }]}>
                      {key}
                    </Text>
                  </View>
                  <Text style={styles.severityScoreText}>{details.score}</Text>
                </View>
                {/* Visual Bar Indicator */}
                <View style={styles.severityProgressBg}>
                  <View
                    style={[
                      styles.severityProgressFill,
                      { width: details.score, backgroundColor: details.color },
                    ]}
                  />
                </View>
              </TouchableOpacity>
            );
          })}
        </View>
      </View>

      {/* AI Condition Summary Card */}
      <BlurView intensity={15} tint="dark" style={styles.summaryCard}>
        <View style={styles.summaryHeader}>
          <Sparkles size={16} color={COLORS.primary} />
          <Text style={styles.summaryTitle}>AI Summary</Text>
        </View>
        <Text style={styles.summaryText}>
          Your skin is overall healthy with minor concerns. Dark circles and pigmentation are your primary areas to focus on.
        </Text>
      </BlurView>

      {/* Treatment recommendations */}
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>Recommendations</Text>
        <Text style={styles.viewAllText}>View all</Text>
      </View>

      <View style={styles.recContainer}>
        {/* Recommendation Item 1 */}
        <BlurView intensity={15} tint="dark" style={styles.recCard}>
          <View style={[styles.recIconCircle, { backgroundColor: '#3A2E2B' }]}>
            <Sparkles size={18} color={COLORS.primary} />
          </View>
          <View style={styles.recTextContainer}>
            <Text style={styles.recTitle}>Use Vitamin C Serum</Text>
            <Text style={styles.recSub}>Helps reduce pigmentation and brightens skin.</Text>
          </View>
          <ChevronRight size={18} color={COLORS.textSecondary} />
        </BlurView>

        {/* Recommendation Item 2 */}
        <BlurView intensity={15} tint="dark" style={styles.recCard}>
          <View style={[styles.recIconCircle, { backgroundColor: '#202E3A' }]}>
            <Droplet size={18} color="#8DCEE8" />
          </View>
          <View style={styles.recTextContainer}>
            <Text style={styles.recTitle}>Hydrate & Moisturize</Text>
            <Text style={styles.recSub}>Strengthen skin barrier and reduce redness.</Text>
          </View>
          <ChevronRight size={18} color={COLORS.textSecondary} />
        </BlurView>

        {/* Recommendation Item 3 */}
        <BlurView intensity={15} tint="dark" style={styles.recCard}>
          <View style={[styles.recIconCircle, { backgroundColor: '#2D203A' }]}>
            <Moon size={18} color="#C98DE8" />
          </View>
          <View style={styles.recTextContainer}>
            <Text style={styles.recTitle}>Get Enough Sleep</Text>
            <Text style={styles.recSub}>Helps reduce dark circles and improves skin.</Text>
          </View>
          <ChevronRight size={18} color={COLORS.textSecondary} />
        </BlurView>
      </View>

      {/* Results buttons */}
      <View style={styles.resultsButtonsRow}>
        <TouchableOpacity 
          style={styles.outlinedButton}
          onPress={() => navigateTo('scan')}
        >
          <CameraIcon size={18} color="#FFFFFF" style={{ marginRight: 8 }} />
          <Text style={styles.outlinedButtonText}>Scan Again</Text>
        </TouchableOpacity>

        <TouchableOpacity 
          style={styles.filledButton}
          onPress={handleSave}
        >
          <LinearGradient
            colors={[COLORS.primary, COLORS.primaryDark]}
            style={styles.filledButtonGradient}
          >
            <Download size={18} color="#FFFFFF" style={{ marginRight: 8 }} />
            <Text style={styles.filledButtonText}>Save Result</Text>
          </LinearGradient>
        </TouchableOpacity>
      </View>

      {/* Spacing bottom */}
      <View style={{ height: 100 }} />
    </ScrollView>
  );
}

// ==========================================
// PLACEHOLDER SCREENS
// ==========================================
function PlaceholderScreen({ title, icon: IconComponent }: { title: string; icon: any }) {
  return (
    <View style={styles.placeholderContainer}>
      <IconComponent size={64} color={COLORS.primary} style={{ opacity: 0.8 }} />
      <Text style={styles.placeholderTitle}>{title}</Text>
      <Text style={styles.placeholderSubtitle}>
        This premium section will render your real-time diagnostics dashboard soon.
      </Text>
    </View>
  );
}

// ==========================================
// CUSTOM FLOATING NAVIGATION TABBAR
// ==========================================
function BottomTabBar({ currentTab, navigateTo }: { currentTab: string; navigateTo: (tab: any) => void }) {
  const tabs = [
    { key: 'home', label: 'Home', icon: HomeIcon },
    { key: 'history', label: 'History', icon: HistoryIcon },
    { key: 'scan', label: 'Scan', icon: Camera },
    { key: 'insights', label: 'Insights', icon: Compass },
    { key: 'profile', label: 'Profile', icon: UserIcon },
  ];

  return (
    <View style={styles.tabBarWrapper}>
      <BlurView intensity={25} tint="dark" style={styles.tabBarContainer}>
        {tabs.map((tab) => {
          const isSelected = currentTab === tab.key || (tab.key === 'scan' && currentTab === 'results');
          const isScanCenter = tab.key === 'scan';
          
          if (isScanCenter) {
            // Render large circular floating button for scanning
            return (
              <TouchableOpacity
                key={tab.key}
                style={styles.floatingScanContainer}
                activeOpacity={0.9}
                onPress={() => navigateTo('scan')}
              >
                <LinearGradient
                  colors={[COLORS.primary, COLORS.primaryDark]}
                  style={styles.floatingScanInner}
                >
                  <CameraIcon size={24} color="#FFFFFF" />
                </LinearGradient>
              </TouchableOpacity>
            );
          }

          return (
            <TouchableOpacity
              key={tab.key}
              style={styles.tabItem}
              activeOpacity={0.8}
              onPress={() => navigateTo(tab.key)}
            >
              <tab.icon
                size={22}
                color={isSelected ? COLORS.primary : COLORS.textSecondary}
              />
              <Text
                style={[
                  styles.tabLabel,
                  isSelected && { color: COLORS.primary, fontWeight: 'bold' },
                ]}
              >
                {tab.label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </BlurView>
    </View>
  );
}

// ==========================================
// LUXURY STYLINGS DESIGN SYSTEM
// ==========================================
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  safeArea: {
    flex: 1,
  },
  mainContent: {
    flex: 1,
  },
  scrollContainer: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: 20,
    paddingTop: 10,
  },
  
  // Ambient glow vectors
  glowTopLeft: {
    position: 'absolute',
    top: -150,
    left: -150,
    width: 350,
    height: 350,
    borderRadius: 175,
    backgroundColor: COLORS.primary,
    opacity: 0.12,
    transform: [{ scale: 1.2 }],
  },
  glowBottomRight: {
    position: 'absolute',
    bottom: -150,
    right: -150,
    width: 400,
    height: 400,
    borderRadius: 200,
    backgroundColor: COLORS.primaryDark,
    opacity: 0.08,
    transform: [{ scale: 1.1 }],
  },

  // Home Header
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 10,
    marginBottom: 24,
  },
  brandRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  brandText: {
    fontSize: 26,
    fontWeight: '900',
    color: '#FFFFFF',
    letterSpacing: -1.0,
  },
  subtext: {
    fontSize: 12,
    color: COLORS.textSecondary,
    fontWeight: '500',
    marginTop: 2,
  },
  headerActions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconButton: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: '#1E222B',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.06)',
  },
  badge: {
    position: 'absolute',
    top: 10,
    right: 12,
    width: 7,
    height: 7,
    borderRadius: 3.5,
    backgroundColor: COLORS.primary,
  },
  avatar: {
    width: 42,
    height: 42,
    borderRadius: 21,
    borderWidth: 1.5,
    borderColor: COLORS.primary,
  },

  // Welcome Greeting Row
  welcomeRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 28,
  },
  welcomeTextContainer: {
    flex: 1,
    marginRight: 12,
  },
  welcomeSubtitle: {
    fontSize: 14,
    color: COLORS.textSecondary,
    fontWeight: '500',
  },
  welcomeTitle: {
    fontSize: 26,
    fontWeight: '800',
    color: '#FFFFFF',
    letterSpacing: -0.5,
    marginVertical: 4,
  },
  welcomeQuote: {
    fontSize: 13,
    color: COLORS.textSecondary,
    lineHeight: 18,
  },
  
  // Circular Score ring on home
  scoreContainer: {
    justifyContent: 'center',
    alignItems: 'center',
    width: 96,
    height: 96,
  },
  scoreInnerContent: {
    position: 'absolute',
    justifyContent: 'center',
    alignItems: 'center',
  },
  scoreLabel: {
    fontSize: 8,
    color: COLORS.textSecondary,
    fontWeight: '700',
    textTransform: 'uppercase',
  },
  scoreNumber: {
    fontSize: 22,
    fontWeight: '900',
    color: '#FFFFFF',
    lineHeight: 24,
    marginTop: 2,
  },
  scoreScale: {
    fontSize: 8,
    color: COLORS.textSecondary,
    marginTop: -2,
  },
  scoreStatus: {
    fontSize: 9,
    color: COLORS.primary,
    fontWeight: 'bold',
    marginTop: 1,
  },

  // Main Hero Scan Card
  heroCard: {
    borderRadius: 24,
    overflow: 'hidden',
    marginBottom: 28,
  },
  heroGradient: {
    flexDirection: 'row',
    paddingHorizontal: 22,
    paddingVertical: 24,
  },
  heroBorder: {
    ...StyleSheet.absoluteFillObject,
    borderRadius: 24,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
  },
  heroContentLeft: {
    flex: 1.3,
    justifyContent: 'center',
  },
  heroLabelContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(232, 154, 141, 0.12)',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
    alignSelf: 'flex-start',
    marginBottom: 12,
  },
  heroLabelText: {
    fontSize: 11,
    fontWeight: '700',
    color: COLORS.primary,
    marginLeft: 6,
  },
  heroTitle: {
    fontSize: 22,
    fontWeight: '800',
    color: '#FFFFFF',
    marginBottom: 8,
  },
  heroSubtitle: {
    fontSize: 13,
    color: COLORS.textSecondary,
    lineHeight: 18,
    marginBottom: 20,
  },
  heroButton: {
    borderRadius: 16,
    overflow: 'hidden',
    alignSelf: 'flex-start',
  },
  heroButtonGradient: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 18,
    paddingVertical: 12,
  },
  heroButtonText: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginRight: 6,
  },
  heroContentRight: {
    flex: 0.9,
    justifyContent: 'center',
    alignItems: 'flex-end',
    position: 'relative',
  },
  heroFaceImage: {
    width: 120,
    height: 120,
    borderRadius: 60,
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  scanningDotGrid: {
    position: 'absolute',
    width: 120,
    height: 120,
    borderRadius: 60,
    borderWidth: 1.5,
    borderColor: COLORS.primary,
    borderStyle: 'dashed',
    opacity: 0.4,
  },

  // Sections
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  viewAllText: {
    fontSize: 13,
    color: COLORS.primary,
    fontWeight: '600',
  },

  // Overview Sparkline row
  overviewContainer: {
    flexDirection: 'row',
    marginBottom: 28,
  },
  overviewCard: {
    width: 160,
    padding: 16,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.06)',
    marginRight: 14,
    backgroundColor: 'rgba(26, 29, 36, 0.3)',
  },
  overviewHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 12,
  },
  overviewIconContainer: {
    width: 28,
    height: 28,
    borderRadius: 14,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 8,
  },
  overviewTitleText: {
    fontSize: 12,
    color: COLORS.textSecondary,
    fontWeight: '600',
  },
  overviewValue: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  overviewSubvalue: {
    fontSize: 11,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  overviewButton: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 12,
  },
  overviewButtonText: {
    fontSize: 11,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginRight: 4,
  },
  progressRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  progressPercentage: {
    fontSize: 11,
    fontWeight: 'bold',
    color: COLORS.success,
  },
  chartContainer: {
    marginTop: 12,
    alignItems: 'center',
  },
  progressBarBg: {
    height: 6,
    backgroundColor: '#262A34',
    borderRadius: 3,
    marginTop: 14,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    borderRadius: 3,
  },

  // Profile summary card
  profileSummaryCard: {
    flexDirection: 'row',
    paddingVertical: 20,
    borderRadius: 22,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.06)',
    backgroundColor: 'rgba(26, 29, 36, 0.2)',
    marginBottom: 28,
  },
  profileMetaColumn: {
    flex: 1,
    alignItems: 'center',
  },
  profileMetaLabel: {
    fontSize: 11,
    color: COLORS.textSecondary,
    fontWeight: '500',
    marginVertical: 4,
  },
  profileMetaValue: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  profileCardDivider: {
    width: 1,
    backgroundColor: COLORS.divider,
    height: '70%',
    alignSelf: 'center',
  },

  // Quick Insights
  insightsContainer: {
    flexDirection: 'row',
    marginBottom: 20,
  },
  insightCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.card,
    padding: 16,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)',
    marginRight: 14,
    width: 280,
  },
  insightIconContainer: {
    width: 38,
    height: 38,
    borderRadius: 19,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
  },
  insightTextContainer: {
    flex: 1,
  },
  insightTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  insightSub: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginTop: 2,
  },

  // Navigation tab bar styles
  tabBarWrapper: {
    position: 'absolute',
    bottom: 20,
    left: 20,
    right: 20,
  },
  tabBarContainer: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    height: 72,
    borderRadius: 36,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
    overflow: 'hidden',
    backgroundColor: 'rgba(15, 17, 21, 0.85)',
    paddingHorizontal: 10,
  },
  tabItem: {
    alignItems: 'center',
    justifyContent: 'center',
    flex: 1,
  },
  tabLabel: {
    fontSize: 10,
    color: COLORS.textSecondary,
    marginTop: 4,
    fontWeight: '500',
  },
  floatingScanContainer: {
    top: -24,
    width: 68,
    height: 68,
    borderRadius: 34,
    backgroundColor: COLORS.background,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: COLORS.primary,
    shadowOffset: { width: 0, height: 10 },
    shadowOpacity: 0.3,
    shadowRadius: 15,
    elevation: 8,
  },
  floatingScanInner: {
    width: 58,
    height: 58,
    borderRadius: 29,
    justifyContent: 'center',
    alignItems: 'center',
  },

  // ==========================================
  // SCAN SCREEN STYLINGS
  // ==========================================
  cameraWrapper: {
    flex: 1,
    paddingHorizontal: 20,
  },
  cameraHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 15,
  },
  backCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(255, 255, 255, 0.08)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.05)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  cameraTitle: {
    fontSize: 20,
    fontWeight: '900',
    color: '#FFFFFF',
  },
  cameraSub: {
    fontSize: 14,
    color: COLORS.textSecondary,
    textAlign: 'center',
    marginTop: 8,
    marginBottom: 20,
  },
  cameraViewportContainer: {
    height: SCREEN_HEIGHT * 0.44,
    borderRadius: 28,
    overflow: 'hidden',
    position: 'relative',
    borderWidth: 1.5,
    borderColor: 'rgba(255,255,255,0.08)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  cameraPreviewImage: {
    width: '100%',
    height: '100%',
    resizeMode: 'cover',
  },
  laserLine: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: 25,
    zIndex: 10,
  },
  laserGradient: {
    width: '100%',
    height: '100%',
  },
  faceGuideFrame: {
    position: 'absolute',
    width: '78%',
    height: '78%',
    justifyContent: 'center',
    alignItems: 'center',
  },
  guideCorner: {
    position: 'absolute',
    width: 24,
    height: 24,
    borderColor: COLORS.primary,
  },
  guideDottedFaceRing: {
    width: '90%',
    height: '92%',
    borderRadius: 120,
    borderWidth: 1.5,
    borderColor: COLORS.primary,
    borderStyle: 'dashed',
    opacity: 0.6,
  },
  analyzerOverlay: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 20,
  },
  analyzerText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: 'bold',
    marginTop: 16,
  },
  guideText: {
    position: 'absolute',
    bottom: 20,
    backgroundColor: 'rgba(15, 17, 21, 0.75)',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 12,
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '600',
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.06)',
  },
  tipsSection: {
    marginTop: 24,
  },
  tipsHeader: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 12,
    textAlign: 'center',
  },
  tipsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  tipItem: {
    width: '48%',
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.card,
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderRadius: 16,
    marginBottom: 10,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.05)',
  },
  tipIconCircle: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: 'rgba(232, 154, 141, 0.1)',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 10,
  },
  tipText: {
    fontSize: 12,
    color: COLORS.textPrimary,
    fontWeight: '600',
  },
  captureActionsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 24,
    paddingHorizontal: 20,
  },
  subActionButton: {
    alignItems: 'center',
    justifyContent: 'center',
    width: 60,
  },
  subActionLabel: {
    fontSize: 11,
    color: COLORS.textSecondary,
    marginTop: 6,
    fontWeight: '500',
  },
  mainCaptureOutline: {
    width: 80,
    height: 80,
    borderRadius: 40,
    borderWidth: 4,
    borderColor: '#FFFFFF',
    justifyContent: 'center',
    alignItems: 'center',
  },
  mainCaptureInner: {
    width: 64,
    height: 64,
    borderRadius: 32,
  },

  // ==========================================
  // RESULTS SCREEN STYLINGS
  // ==========================================
  resultsHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 10,
    marginBottom: 20,
  },
  resultsHeaderTitles: {
    alignItems: 'center',
  },
  resultsTitle: {
    fontSize: 18,
    fontWeight: '900',
    color: '#FFFFFF',
  },
  resultsSubtitle: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginTop: 2,
  },
  overallScoreCard: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 22,
    borderRadius: 24,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.06)',
    backgroundColor: 'rgba(26, 29, 36, 0.3)',
    marginBottom: 28,
  },
  scoreTextCol: {
    flex: 1,
  },
  scoreCardTitle: {
    fontSize: 13,
    color: COLORS.textSecondary,
    fontWeight: '600',
  },
  scoreRow: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    marginVertical: 4,
  },
  resultsScoreVal: {
    fontSize: 32,
    fontWeight: '900',
    color: '#FFFFFF',
    lineHeight: 34,
  },
  resultsScoreScale: {
    fontSize: 14,
    color: COLORS.textSecondary,
    marginLeft: 4,
    marginBottom: 2,
  },
  scoreCardComment: {
    fontSize: 12,
    color: COLORS.primary,
    fontWeight: 'bold',
  },
  resultsRadialContainer: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  resultsRadialLabelContainer: {
    position: 'absolute',
    justifyContent: 'center',
    alignItems: 'center',
  },
  resultsRadialVal: {
    fontSize: 20,
    fontWeight: '900',
    color: '#FFFFFF',
  },
  resultsRadialComment: {
    fontSize: 9,
    color: COLORS.textSecondary,
    fontWeight: '600',
    textTransform: 'uppercase',
  },
  resultsConcernsCount: {
    fontSize: 13,
    color: COLORS.primary,
    fontWeight: '600',
  },

  // Interactive face analysis view in results
  annotatedSection: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 28,
  },
  faceAnnotatedContainer: {
    width: SCREEN_WIDTH * 0.44,
    height: SCREEN_WIDTH * 0.58,
    borderRadius: 22,
    overflow: 'hidden',
    position: 'relative',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.08)',
  },
  faceAnnotatedImage: {
    width: '100%',
    height: '100%',
    resizeMode: 'cover',
  },
  annotationMarker: {
    position: 'absolute',
    width: 24,
    height: 24,
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 10,
  },
  annotationMarkerActive: {
    zIndex: 12,
  },
  markerDot: {
    width: 10,
    height: 10,
    borderRadius: 5,
    backgroundColor: '#FFFFFF',
    borderWidth: 1.5,
    borderColor: COLORS.primary,
  },
  markerDotActive: {
    backgroundColor: COLORS.primary,
    borderColor: '#FFFFFF',
  },
  markerPulseRing: {
    position: 'absolute',
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 1.5,
    borderColor: COLORS.primary,
    opacity: 0.6,
  },

  // Severity Analysis
  severitySection: {
    flex: 1,
    marginLeft: 16,
    justifyContent: 'space-between',
    height: SCREEN_WIDTH * 0.58,
  },
  severityItem: {
    backgroundColor: 'rgba(26, 29, 36, 0.3)',
    borderRadius: 12,
    padding: 8,
    borderWidth: 1,
    borderColor: 'transparent',
  },
  severityItemActive: {
    backgroundColor: COLORS.card,
    borderColor: 'rgba(255, 255, 255, 0.05)',
  },
  severityLabelRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 6,
  },
  severityDotName: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  smallSeverityDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    marginRight: 6,
  },
  severityName: {
    fontSize: 12,
    color: COLORS.textSecondary,
    fontWeight: '500',
  },
  severityScoreText: {
    fontSize: 12,
    color: '#FFFFFF',
    fontWeight: 'bold',
  },
  severityProgressBg: {
    height: 5,
    backgroundColor: '#262A34',
    borderRadius: 2.5,
    overflow: 'hidden',
  },
  severityProgressFill: {
    height: '100%',
    borderRadius: 2.5,
  },

  // AI Summary Card
  summaryCard: {
    padding: 20,
    borderRadius: 22,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.06)',
    backgroundColor: 'rgba(26, 29, 36, 0.2)',
    marginBottom: 28,
  },
  summaryHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 10,
  },
  summaryTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: COLORS.primary,
    marginLeft: 8,
  },
  summaryText: {
    fontSize: 13,
    color: COLORS.textSecondary,
    lineHeight: 18,
  },

  // Recommendations
  recContainer: {
    marginBottom: 28,
  },
  recCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.06)',
    backgroundColor: 'rgba(26, 29, 36, 0.2)',
    marginBottom: 12,
  },
  recIconCircle: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 14,
  },
  recTextContainer: {
    flex: 1,
  },
  recTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  recSub: {
    fontSize: 12,
    color: COLORS.textSecondary,
    marginTop: 2,
  },

  // Result Buttons
  resultsButtonsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  outlinedButton: {
    flex: 1,
    height: 52,
    borderRadius: 24,
    borderWidth: 1.5,
    borderColor: 'rgba(255,255,255,0.15)',
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 12,
    backgroundColor: 'rgba(255,255,255,0.02)',
  },
  outlinedButtonText: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },
  filledButton: {
    flex: 1.2,
    height: 52,
    borderRadius: 24,
    overflow: 'hidden',
  },
  filledButtonGradient: {
    width: '100%',
    height: '100%',
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
  filledButtonText: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#FFFFFF',
  },

  // Placeholders
  placeholderContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 40,
    marginTop: SCREEN_HEIGHT * 0.15,
  },
  placeholderTitle: {
    fontSize: 22,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginTop: 20,
    marginBottom: 8,
  },
  placeholderSubtitle: {
    fontSize: 14,
    color: COLORS.textSecondary,
    textAlign: 'center',
    lineHeight: 20,
  },
});
