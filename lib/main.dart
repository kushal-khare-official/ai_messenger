import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/home_screen.dart';
import 'services/sms_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await NotificationService().initialize();

  runApp(const TextWiseApp());
}

class TextWiseApp extends StatelessWidget {
  const TextWiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TextWise',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Request permissions
    final permissionsGranted = await _requestPermissions();

    if (permissionsGranted) {
      // Request to become default SMS app
      await _requestDefaultSmsApp();
      
      // Initialize SMS service
      await SmsService().initialize();

      // Navigate to home screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      // Show permission error
      if (mounted) {
        _showPermissionError();
      }
    }
  }

  Future<bool> _requestPermissions() async {
    // Request SMS permissions
    final smsStatus = await Permission.sms.request();

    // Request notification permissions
    final notificationStatus = await Permission.notification.request();

    // Request phone permissions (needed for SMS on some devices)
    final phoneStatus = await Permission.phone.request();

    return smsStatus.isGranted &&
        notificationStatus.isGranted &&
        phoneStatus.isGranted;
  }

  Future<void> _requestDefaultSmsApp() async {
    try {
      final smsService = SmsService();
      
      // Check if already default SMS app
      final isDefault = await smsService.isDefaultSmsApp();
      
      if (!isDefault && mounted) {
        // Show dialog explaining why we need to be the default SMS app
        final shouldRequest = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Set as Default SMS App'),
            content: const Text(
              'To provide smart message filtering and AI-powered features, '
              'TextWise needs to be set as your default SMS app. '
              'This allows the app to:\n\n'
              '• Read and organize your messages\n'
              '• Automatically categorize messages\n'
              '• Send notifications for important messages\n\n'
              'You can change this later in your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not Now'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        );

        if (shouldRequest == true) {
          // Request to become default SMS app
          await smsService.requestDefaultSmsApp();
        }
      }
    } catch (e) {
      // If there's an error, continue anyway
      debugPrint('Error requesting default SMS app: $e');
    }
  }

  void _showPermissionError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'TextWise needs SMS and notification permissions to function properly. '
          'Please grant these permissions in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeApp(); // Retry
            },
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.message,
                size: 60,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // App name
            Text(
              'TextWise',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            Text(
              'AI-Powered SMS Classification',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 48),

            // Loading indicator
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Setting up...'),
          ],
        ),
      ),
    );
  }
}
