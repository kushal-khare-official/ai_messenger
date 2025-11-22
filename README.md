# TextWise 📱🤖

An intelligent AI-powered messaging app that wisely classifies and categorizes SMS messages, helping you stay organized and only get notified about what matters.

## Features

### 🛡️ Smart Filtering
- **On-Device AI Classification**: Lightweight TensorFlow Lite model runs entirely on your device
- **Automatic Spam Detection**: AI-powered spam filtering using pattern recognition
- **Intelligent Classification**: Automatically categorizes messages into:
  - 🔐 OTP (One-Time Passwords)
  - 🏦 Bank Alerts
  - 💰 Finance Alerts
  - 🎁 Offers
  - 🎫 Coupons
  - 👤 Personal Messages
  - 💼 Business Messages
  - 📢 Promotional
  - 🚫 Spam

### 🔔 Smart Notifications
- Get notified only for messages that matter to you
- Customize notification preferences by category
- Separate controls for OTPs, bank alerts, and important messages
- Mute categories you don't want to be notified about

### 📊 Organization
- View all messages in one place
- Filter by category with a single tap
- Separate tabs for All, Important, and Spam messages
- Beautiful, modern UI with Material Design 3

### 🏷️ Offer & Coupon Classification
Automatically categorizes offers and coupons by type:
- 💊 Medicine
- 👕 Clothing
- 👟 Shoes
- 📱 Electronics
- 🍕 Food
- ✈️ Travel
- 🎬 Entertainment

## Getting Started

### Prerequisites
- Flutter SDK (3.10.0 or higher)
- Android device or emulator (Android 6.0+)
- iOS device or simulator (iOS 10.0+)

### Installation

1. Clone or navigate to the project:
```bash
cd textwise
```

2. Install dependencies:
```bash
flutter pub get
```

3. **(Optional)** Enable AI classification:
   - See [AI_MODEL_SETUP.md](AI_MODEL_SETUP.md) for instructions
   - App works with rule-based classification by default
   - Add TensorFlow Lite model for improved accuracy

4. Run the app:
```bash
flutter run
```

### Required Permissions

The app requires the following permissions:

**Android:**
- READ_SMS: To read existing SMS messages
- RECEIVE_SMS: To receive incoming SMS messages
- SEND_SMS: (Future feature) To send messages
- READ_PHONE_STATE: To access phone state
- POST_NOTIFICATIONS: To show notifications (Android 13+)

**iOS:**
Note: iOS has strict limitations on SMS access. The app primarily targets Android.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── sms_message.dart     # SMS message model
│   └── filter_settings.dart # User settings model
├── services/                 # Business logic
│   ├── sms_service.dart              # SMS handling
│   ├── classification_service.dart   # AI classification orchestrator
│   ├── notification_service.dart     # Notifications
│   └── ai/                           # AI components
│       ├── model_manager.dart        # TensorFlow Lite model
│       └── tokenizer.dart            # Text preprocessing
├── database/                 # Local storage
│   └── database_helper.dart # SQLite database
├── screens/                  # UI screens
│   ├── home_screen.dart     # Main screen
│   └── settings_screen.dart # Settings
└── widgets/                  # Reusable widgets
    ├── message_card.dart    # Message display card
    └── category_filter.dart # Category filter chips
```

## Architecture

### Classification Engine

The app uses a **hybrid AI classification system**:

**AI-Powered Mode** (when model is available):
1. Preprocesses text using custom tokenizer
2. Runs inference on TensorFlow Lite model (on-device)
3. Returns probability distribution over categories
4. Falls back to rules if confidence is low

**Rule-Based Mode** (fallback):
1. Analyzes message content for keywords and patterns
2. Checks sender information against known sources
3. Assigns appropriate categories and importance levels
4. Detects spam using multiple indicators

**Privacy**: All processing happens entirely on your device. No data is sent to external servers.

### Database
- Uses SQLite for local storage
- Stores messages with full metadata
- Indexed for fast querying
- Supports filtering and searching

### Notification System
- Respects user preferences
- Shows context-rich notifications
- Grouped by category
- Smart filtering based on importance

## Future Enhancements

- ✅ **Machine Learning Model**: ~~Train custom ML model~~ → Now supports on-device TFLite models!
- 🤖 **Model Training Pipeline**: Automated training and deployment
- 🔍 **Advanced Search**: Full-text search with filters
- 📈 **Analytics Dashboard**: Visualize message patterns
- 🌙 **Dark Mode**: Full dark theme support
- ☁️ **Cloud Sync**: Backup and sync across devices
- 🔒 **Enhanced Security**: End-to-end encryption
- 📤 **Export Data**: Export messages to CSV/PDF
- 🎨 **Themes**: Customizable color schemes

## Technologies Used

- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language
- **TensorFlow Lite**: On-device machine learning
- **SQLite**: Local database (via sqflite)
- **Telephony**: SMS access (Android)
- **Provider**: State management
- **Flutter Local Notifications**: Push notifications

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Privacy

TextWise processes all data locally on your device. No messages are sent to external servers. All classification happens on-device to protect your privacy.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with Flutter
- Uses TensorFlow Lite for on-device AI classification
- Falls back to rule-based classification when needed
- Inspired by the need for intelligent SMS management

## Support

For issues or questions, please open an issue on the project repository.

---

**Made with ❤️ using Flutter**
