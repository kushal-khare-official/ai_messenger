/// User preferences for message filtering and notifications
class FilterSettings {
  final Set<String> importantCategories;
  final Set<String> mutedCategories;
  final bool autoFilterSpam;
  final bool notifyOnOTP;
  final bool notifyOnBankAlerts;
  final bool notifyOnImportant;
  final Set<String> trustedSenders; // Phone numbers
  final Set<String> blockedSenders;

  FilterSettings({
    Set<String>? importantCategories,
    Set<String>? mutedCategories,
    this.autoFilterSpam = true,
    this.notifyOnOTP = true,
    this.notifyOnBankAlerts = true,
    this.notifyOnImportant = true,
    Set<String>? trustedSenders,
    Set<String>? blockedSenders,
  }) : importantCategories =
           importantCategories ?? {'otp', 'bankAlert', 'financeAlert'},
       mutedCategories = mutedCategories ?? {'promotional', 'spam'},
       trustedSenders = trustedSenders ?? {},
       blockedSenders = blockedSenders ?? {};

  Map<String, dynamic> toMap() {
    return {
      'importantCategories': importantCategories.toList(),
      'mutedCategories': mutedCategories.toList(),
      'autoFilterSpam': autoFilterSpam ? 1 : 0,
      'notifyOnOTP': notifyOnOTP ? 1 : 0,
      'notifyOnBankAlerts': notifyOnBankAlerts ? 1 : 0,
      'notifyOnImportant': notifyOnImportant ? 1 : 0,
      'trustedSenders': trustedSenders.toList(),
      'blockedSenders': blockedSenders.toList(),
    };
  }

  factory FilterSettings.fromMap(Map<String, dynamic> map) {
    return FilterSettings(
      importantCategories: Set<String>.from(map['importantCategories'] ?? []),
      mutedCategories: Set<String>.from(map['mutedCategories'] ?? []),
      autoFilterSpam: map['autoFilterSpam'] == 1,
      notifyOnOTP: map['notifyOnOTP'] == 1,
      notifyOnBankAlerts: map['notifyOnBankAlerts'] == 1,
      notifyOnImportant: map['notifyOnImportant'] == 1,
      trustedSenders: Set<String>.from(map['trustedSenders'] ?? []),
      blockedSenders: Set<String>.from(map['blockedSenders'] ?? []),
    );
  }
}
