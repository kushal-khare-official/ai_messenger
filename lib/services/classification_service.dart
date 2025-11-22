import '../models/sms_message.dart';
import '../utils/app_logger.dart';
import 'ai/model_manager.dart';

/// Service for classifying SMS messages using on-device AI
/// Falls back to rule-based classification when model unavailable
class ClassificationService {
  static final ClassificationService _instance =
      ClassificationService._internal();
  factory ClassificationService() => _instance;
  ClassificationService._internal();

  final ModelManager _modelManager = ModelManager();
  bool _useAI = true;
  bool _isInitialized = false;

  /// Initialize the classification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    AppLogger.info('Initializing Classification Service...');
    
    // Try to initialize AI model
    final modelInitialized = await _modelManager.initialize();
    _useAI = modelInitialized;
    
    if (_useAI) {
      AppLogger.info('✓ AI model loaded successfully - using on-device AI classification');
    } else {
      AppLogger.warning('⚠ AI model not available - using rule-based classification');
    }
    
    _isInitialized = true;
  }

  /// Keywords for different categories (fallback rule-based)
  final Map<SmsCategory, List<String>> _categoryKeywords = {
    SmsCategory.otp: [
      'otp',
      'verification code',
      'verify',
      'authentication',
      'pin',
      'code is',
      'security code',
      'one time password',
      'passcode',
      'confirm',
    ],
    SmsCategory.bankAlert: [
      'bank',
      'account',
      'credited',
      'debited',
      'balance',
      'transaction',
      'atm',
      'withdrawal',
      'deposit',
      'statement',
      'available balance',
    ],
    SmsCategory.financeAlert: [
      'payment',
      'invoice',
      'due',
      'bill',
      'credit card',
      'loan',
      'emi',
      'insurance',
      'stock',
      'investment',
      'mutual fund',
    ],
    SmsCategory.offer: [
      'offer',
      'discount',
      'sale',
      'deal',
      'save',
      'flat',
      '% off',
      'special price',
      'limited time',
      'hurry',
    ],
    SmsCategory.coupon: [
      'coupon',
      'promo code',
      'voucher',
      'redeem',
      'cashback',
      'reward',
      'gift card',
      'points',
    ],
  };

  /// Common spam indicators (fallback rule-based)
  final List<String> _spamKeywords = [
    'congratulations',
    'winner',
    'claim',
    'free prize',
    'urgent action',
    'act now',
    'call now',
    'click here',
    'limited time',
    'risk free',
    'no obligation',
    'guaranteed',
    'once in lifetime',
  ];

  /// Known banking/financial senders
  final List<String> _trustedFinancialSenders = [
    'HDFCBK',
    'ICICIB',
    'SBIINB',
    'AXISBK',
    'KOTAKB',
    'PNBSMS',
    'BOISMS',
    'PAYTM',
    'GOOGLEPAY',
    'PHONEPE',
  ];

  /// Classify SMS message using AI or fallback to rules
  Future<SmsCategory> classifyMessage(String body) async {
    // Ensure initialized
    if (!_isInitialized) {
      await initialize();
    }

    SmsCategory? aiCategory;
    
    // Try AI classification first
    if (_useAI && _modelManager.isInitialized) {
      try {
        aiCategory = await _modelManager.classifyWithModel(body);
        
        if (aiCategory != null) {
          AppLogger.debug('AI classified as: $aiCategory');
          return aiCategory;
        }
      } catch (e) {
        AppLogger.warning('AI classification failed, using fallback', error: e);
      }
    }

    // Fallback to rule-based classification
    return await _classifyWithRules(body);
  }

  /// Get detailed confidence scores for all categories (AI only)
  Future<Map<SmsCategory, double>?> getConfidenceScores(String body) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_useAI && _modelManager.isInitialized) {
      return await _modelManager.getConfidenceScores(body);
    }
    
    return null;
  }

  /// Rule-based classification (fallback)
  Future<SmsCategory> _classifyWithRules(String body) async {
    final lowerBody = body.toLowerCase();

    // Check each category
    for (var entry in _categoryKeywords.entries) {
      int matchCount = 0;
      for (var keyword in entry.value) {
        if (lowerBody.contains(keyword.toLowerCase())) {
          matchCount++;
          // Strong match - return immediately
          if (matchCount >= 2 || keyword.length > 8) {
            return entry.key;
          }
        }
      }
      // Weak match
      if (matchCount > 0) {
        return entry.key;
      }
    }

    // If no specific category found, check if it's promotional
    if (_hasPromotionalIndicators(lowerBody)) {
      return SmsCategory.promotional;
    }

    // Check if it looks like a personal message (short, informal)
    if (_looksLikePersonalMessage(body)) {
      return SmsCategory.personal;
    }

    return SmsCategory.other;
  }

  /// Check if message is spam (hybrid approach)
  Future<bool> isSpam(String body, String sender) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Check for known trusted senders first
    if (_trustedFinancialSenders.any((s) => sender.toUpperCase().contains(s))) {
      return false;
    }

    // Try AI-based spam detection
    if (_useAI && _modelManager.isInitialized) {
      try {
        final spamScore = await _modelManager.getSpamScore(body);
        if (spamScore != null) {
          // High spam score from AI
          if (spamScore > 0.7) return true;
          // Low spam score from AI
          if (spamScore < 0.3) return false;
          // Medium score - use rules as tiebreaker
        }
      } catch (e) {
        AppLogger.warning('AI spam detection failed', error: e);
      }
    }

    // Fallback to rule-based spam detection
    return _isSpamByRules(body);
  }

  /// Rule-based spam detection
  bool _isSpamByRules(String body) {
    final lowerBody = body.toLowerCase();
    
    // Count spam indicators
    int spamScore = 0;
    for (var keyword in _spamKeywords) {
      if (lowerBody.contains(keyword.toLowerCase())) {
        spamScore += 2;
      }
    }

    // Check for excessive capitalization
    final upperCount = body
        .split('')
        .where((c) => c == c.toUpperCase() && c != c.toLowerCase())
        .length;
    if (upperCount > body.length * 0.5 && body.length > 20) {
      spamScore += 2;
    }

    // Check for excessive special characters
    final specialChars = RegExp(r'[!@#$%^&*()]+').allMatches(body).length;
    if (specialChars > 5) {
      spamScore += 1;
    }

    // Check for multiple URLs
    final urlCount = RegExp(r'http[s]?://').allMatches(body).length;
    if (urlCount > 1) {
      spamScore += 2;
    }

    // Spam if score exceeds threshold
    return spamScore >= 4;
  }

  /// Determine if message should be marked as important
  bool isImportant(SmsCategory category) {
    return [
      SmsCategory.otp,
      SmsCategory.bankAlert,
      SmsCategory.financeAlert,
    ].contains(category);
  }

  /// Check for promotional indicators
  bool _hasPromotionalIndicators(String body) {
    final promotionalPatterns = [
      'unsubscribe',
      'opt out',
      'text stop',
      'reply stop',
      'exclusively for you',
      'subscribe now',
      'newsletter',
    ];

    return promotionalPatterns.any((pattern) => body.contains(pattern));
  }

  /// Check if message looks personal
  bool _looksLikePersonalMessage(String body) {
    // Personal messages are typically shorter and don't have URLs
    if (body.length > 200) return false;
    if (body.contains('http')) return false;
    if (body.contains('www.')) return false;

    // Check for conversational patterns
    final personalPatterns = [
      'hi', 'hello', 'hey', 'thanks', 'thank you', '?',
      'how are you', 'love', 'miss you', 'see you',
    ];
    
    int personalScore = 0;
    for (var pattern in personalPatterns) {
      if (body.toLowerCase().contains(pattern)) {
        personalScore++;
      }
    }
    
    return personalScore >= 1;
  }

  /// Classify offer/coupon by subcategory
  OfferCategory classifyOfferCategory(String body) {
    final lowerBody = body.toLowerCase();

    if (_containsAny(lowerBody, [
      'medicine',
      'pharmacy',
      'drug',
      'health',
      'medical',
      'prescription',
    ])) {
      return OfferCategory.medicine;
    }
    if (_containsAny(lowerBody, [
      'clothing',
      'fashion',
      'apparel',
      'wear',
      'shirt',
      'dress',
      'jeans',
    ])) {
      return OfferCategory.clothing;
    }
    if (_containsAny(lowerBody, ['shoes', 'footwear', 'sneakers', 'sandals'])) {
      return OfferCategory.shoes;
    }
    if (_containsAny(lowerBody, [
      'electronics',
      'phone',
      'laptop',
      'computer',
      'gadget',
      'headphones',
    ])) {
      return OfferCategory.electronics;
    }
    if (_containsAny(lowerBody, [
      'food',
      'restaurant',
      'dining',
      'pizza',
      'burger',
      'delivery',
    ])) {
      return OfferCategory.food;
    }
    if (_containsAny(lowerBody, [
      'travel',
      'flight',
      'hotel',
      'vacation',
      'tour',
      'booking',
    ])) {
      return OfferCategory.travel;
    }
    if (_containsAny(lowerBody, [
      'movie',
      'entertainment',
      'show',
      'concert',
      'event',
      'ticket',
    ])) {
      return OfferCategory.entertainment;
    }

    return OfferCategory.other;
  }

  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Get AI status
  bool get isUsingAI => _useAI && _modelManager.isInitialized;

  /// Dispose resources
  void dispose() {
    _modelManager.dispose();
  }
}
