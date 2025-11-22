/// Represents an SMS message with AI classification
class SmsMessage {
  final String id;
  final String address; // Phone number
  final String body;
  final DateTime timestamp;
  final SmsCategory category;
  final bool isImportant;
  final bool isSpam;
  final bool isRead;
  final Map<String, dynamic>? metadata; // Additional extracted info

  SmsMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.timestamp,
    required this.category,
    this.isImportant = false,
    this.isSpam = false,
    this.isRead = false,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'body': body,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'category': category.name,
      'isImportant': isImportant ? 1 : 0,
      'isSpam': isSpam ? 1 : 0,
      'isRead': isRead ? 1 : 0,
      'metadata': metadata?.toString(),
    };
  }

  factory SmsMessage.fromMap(Map<String, dynamic> map) {
    return SmsMessage(
      id: map['id'],
      address: map['address'],
      body: map['body'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      category: SmsCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => SmsCategory.other,
      ),
      isImportant: map['isImportant'] == 1,
      isSpam: map['isSpam'] == 1,
      isRead: map['isRead'] == 1,
    );
  }

  SmsMessage copyWith({
    bool? isImportant,
    bool? isSpam,
    bool? isRead,
    SmsCategory? category,
  }) {
    return SmsMessage(
      id: id,
      address: address,
      body: body,
      timestamp: timestamp,
      category: category ?? this.category,
      isImportant: isImportant ?? this.isImportant,
      isSpam: isSpam ?? this.isSpam,
      isRead: isRead ?? this.isRead,
      metadata: metadata,
    );
  }
}

/// Categories for SMS classification
enum SmsCategory {
  otp,
  bankAlert,
  financeAlert,
  offer,
  coupon,
  personal,
  business,
  promotional,
  spam,
  other,
}

/// Sub-categories for offers and coupons
enum OfferCategory {
  medicine,
  clothing,
  shoes,
  electronics,
  food,
  travel,
  entertainment,
  other,
}

extension SmsCategoryExtension on SmsCategory {
  String get displayName {
    switch (this) {
      case SmsCategory.otp:
        return 'OTP';
      case SmsCategory.bankAlert:
        return 'Bank Alert';
      case SmsCategory.financeAlert:
        return 'Finance Alert';
      case SmsCategory.offer:
        return 'Offers';
      case SmsCategory.coupon:
        return 'Coupons';
      case SmsCategory.personal:
        return 'Personal';
      case SmsCategory.business:
        return 'Business';
      case SmsCategory.promotional:
        return 'Promotional';
      case SmsCategory.spam:
        return 'Spam';
      case SmsCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case SmsCategory.otp:
        return '🔐';
      case SmsCategory.bankAlert:
        return '🏦';
      case SmsCategory.financeAlert:
        return '💰';
      case SmsCategory.offer:
        return '🎁';
      case SmsCategory.coupon:
        return '🎫';
      case SmsCategory.personal:
        return '👤';
      case SmsCategory.business:
        return '💼';
      case SmsCategory.promotional:
        return '📢';
      case SmsCategory.spam:
        return '🚫';
      case SmsCategory.other:
        return '📱';
    }
  }
}
