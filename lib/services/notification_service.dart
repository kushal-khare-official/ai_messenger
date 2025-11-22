import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/sms_message.dart';
import '../models/filter_settings.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  FilterSettings? _settings;

  /// Initialize notification service
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    await _loadSettings();
  }

  /// Load user settings
  Future<void> _loadSettings() async {
    // Load settings from shared preferences
    // For now, use default settings
    _settings = FilterSettings();
  }

  /// Show notification for a message based on user settings
  Future<void> showNotificationForMessage(SmsMessage message) async {
    if (_settings == null) await _loadSettings();

    // Check if we should notify for this message
    if (!_shouldNotify(message)) return;

    final categoryIcon = message.category.icon;
    final title = '$categoryIcon ${message.category.displayName}';
    final body = message.body.length > 100
        ? '${message.body.substring(0, 100)}...'
        : message.body;

    final androidDetails = AndroidNotificationDetails(
      'sms_channel',
      'SMS Messages',
      channelDescription: 'Notifications for SMS messages',
      importance: message.isImportant
          ? Importance.high
          : Importance.defaultImportance,
      priority: message.isImportant ? Priority.high : Priority.defaultPriority,
      ticker: 'New SMS',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(message.id.hashCode, title, body, details);
  }

  /// Determine if notification should be shown
  bool _shouldNotify(SmsMessage message) {
    if (_settings == null) return true;

    // Don't notify for spam
    if (message.isSpam) return false;

    // Don't notify for muted categories
    if (_settings!.mutedCategories.contains(message.category.name)) {
      return false;
    }

    // Check specific notification preferences
    if (message.category == SmsCategory.otp && !_settings!.notifyOnOTP) {
      return false;
    }

    if (message.category == SmsCategory.bankAlert &&
        !_settings!.notifyOnBankAlerts) {
      return false;
    }

    if (message.isImportant && !_settings!.notifyOnImportant) {
      return false;
    }

    // Check blocked senders
    if (_settings!.blockedSenders.contains(message.address)) {
      return false;
    }

    return true;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      return await androidImplementation.requestNotificationsPermission() ??
          false;
    }

    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImplementation != null) {
      return await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
