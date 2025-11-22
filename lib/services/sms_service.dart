import 'dart:async';
import 'package:flutter/services.dart';
import 'package:telephony/telephony.dart' as tel;
import '../models/sms_message.dart';
import '../database/database_helper.dart';
import '../utils/app_logger.dart';
import 'classification_service.dart';
import 'notification_service.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final tel.Telephony telephony = tel.Telephony.instance;
  final DatabaseHelper _db = DatabaseHelper();
  final ClassificationService _classifier = ClassificationService();
  final NotificationService _notificationService = NotificationService();
  
  // Platform channel for default SMS app functionality
  static const platform = MethodChannel('com.example.messenger_ai/sms');

  StreamController<SmsMessage>? _messageStreamController;
  Stream<SmsMessage>? get messageStream => _messageStreamController?.stream;

  /// Initialize SMS service and set up listeners
  Future<void> initialize() async {
    _messageStreamController = StreamController<SmsMessage>.broadcast();

    // Request SMS permissions
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;

    if (permissionsGranted != null && permissionsGranted) {
      // Listen for incoming SMS
      telephony.listenIncomingSms(
        onNewMessage: _onNewMessage,
        onBackgroundMessage: onBackgroundMessage,
      );

      // Load existing messages
      await _loadExistingMessages();
    }
  }

  /// Handle new incoming SMS
  Future<void> _onNewMessage(tel.SmsMessage message) async {
    // Convert telephony SMS to our model
    final smsMessage = await _processNewSms(message);

    // Save to database
    await _db.insertMessage(smsMessage);

    // Add to stream
    _messageStreamController?.add(smsMessage);

    // Show notification if needed
    await _notificationService.showNotificationForMessage(smsMessage);
  }

  /// Process and classify new SMS
  Future<SmsMessage> _processNewSms(tel.SmsMessage telephonySms) async {
    // Classify the message
    final body = telephonySms.body ?? '';
    final address = telephonySms.address ?? '';

    final category = await _classifier.classifyMessage(body);
    final isSpam = await _classifier.isSpam(body, address);

    // Parse timestamp from telephony SMS
    DateTime timestamp;
    if (telephonySms.date != null) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(
        int.parse(telephonySms.date.toString()),
      );
    } else {
      timestamp = DateTime.now();
    }

    return SmsMessage(
      id: telephonySms.id.toString(),
      address: address,
      body: body,
      timestamp: timestamp,
      category: category,
      isSpam: isSpam,
      isImportant: _classifier.isImportant(category),
    );
  }

  /// Load existing SMS messages from device
  Future<void> _loadExistingMessages() async {
    try {
      AppLogger.info('📱 Loading existing messages from device...');
      List<tel.SmsMessage> messages = await telephony.getInboxSms(
        columns: [
          tel.SmsColumn.ID,
          tel.SmsColumn.ADDRESS,
          tel.SmsColumn.BODY,
          tel.SmsColumn.DATE,
        ],
      );

      AppLogger.info('📬 Found ${messages.length} messages in inbox');
      
      // Process and save messages (limit to recent ones to avoid overload)
      final recentMessages = messages.take(100).toList();

      for (var message in recentMessages) {
        AppLogger.debug('Processing message from ${message.address}: ${message.body?.substring(0, message.body!.length < 50 ? message.body!.length : 50)}...');
        final processedMessage = await _processNewSms(message);
        await _db.insertMessage(processedMessage);
        AppLogger.debug('✓ Saved message with category: ${processedMessage.category.displayName}');
      }
      
      AppLogger.info('✓ Successfully loaded ${recentMessages.length} messages');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error loading existing messages', error: e, stackTrace: stackTrace);
    }
  }

  /// Get all messages from database
  Future<List<SmsMessage>> getAllMessages() async {
    return await _db.getAllMessages();
  }

  /// Get messages by category
  Future<List<SmsMessage>> getMessagesByCategory(SmsCategory category) async {
    return await _db.getMessagesByCategory(category);
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    final messages = await _db.getAllMessages();
    final message = messages.firstWhere((m) => m.id == messageId);
    await _db.updateMessage(message.copyWith(isRead: true));
  }

  /// Mark message as spam
  Future<void> markAsSpam(String messageId, bool isSpam) async {
    final messages = await _db.getAllMessages();
    final message = messages.firstWhere((m) => m.id == messageId);
    await _db.updateMessage(message.copyWith(isSpam: isSpam));
  }

  /// Delete message
  Future<void> deleteMessage(String messageId) async {
    await _db.deleteMessage(messageId);
  }

  /// Check if this app is the default SMS app
  Future<bool> isDefaultSmsApp() async {
    try {
      // Use platform channel to check if this app is the default SMS app
      final bool isDefault = await platform.invokeMethod('isDefaultSmsApp');
      AppLogger.info('Default SMS app status: $isDefault');
      return isDefault;
    } catch (e) {
      AppLogger.error('Error checking default SMS app status', error: e);
      return false;
    }
  }

  /// Request to become the default SMS app
  /// This will show a system dialog asking the user to set this app as default
  Future<void> requestDefaultSmsApp() async {
    try {
      AppLogger.info('📱 Requesting to become default SMS app...');
      
      // Use platform channel to open the default SMS app chooser
      await platform.invokeMethod('requestDefaultSmsApp');
      
      AppLogger.info('✓ Default SMS app request dialog opened');
    } catch (e) {
      AppLogger.error('❌ Error requesting default SMS app', error: e);
    }
  }

  void dispose() {
    _messageStreamController?.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
void onBackgroundMessage(tel.SmsMessage message) {
  // Handle background SMS (Android background execution)
  AppLogger.info('Background SMS received: ${message.body}');
}
