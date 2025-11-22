import 'package:flutter/services.dart';
import '../../utils/app_logger.dart';

/// Tokenizer for converting text to token IDs for model input
class SMSTokenizer {
  Map<String, int> _vocab = {};
  final int _maxLength = 128;
  static const String _padToken = '[PAD]';
  static const String _unkToken = '[UNK]';
  
  bool _isInitialized = false;

  /// Initialize the tokenizer with vocabulary
  Future<void> initialize({String vocabPath = 'assets/ml_models/vocab.txt'}) async {
    try {
      final vocabContent = await rootBundle.loadString(vocabPath);
      final lines = vocabContent.split('\n');
      
      for (int i = 0; i < lines.length; i++) {
        final token = lines[i].trim();
        if (token.isNotEmpty) {
          _vocab[token] = i;
        }
      }
      
      _isInitialized = true;
    } catch (e) {
      AppLogger.warning('Error loading vocabulary', error: e);
      // Initialize with basic vocabulary if file not found
      _initializeBasicVocab();
    }
  }

  /// Initialize basic vocabulary for fallback
  void _initializeBasicVocab() {
    _vocab = {
      _padToken: 0,
      _unkToken: 1,
    };
    
    // Add common words
    final commonWords = [
      'otp', 'code', 'verify', 'bank', 'account', 'transaction', 
      'payment', 'offer', 'discount', 'sale', 'coupon', 'free',
      'your', 'the', 'is', 'for', 'and', 'to', 'from', 'dear',
      'customer', 'amount', 'balance', 'credited', 'debited',
    ];
    
    for (int i = 0; i < commonWords.length; i++) {
      _vocab[commonWords[i]] = i + 2;
    }
    
    _isInitialized = true;
  }

  /// Tokenize text and convert to input tensor
  List<List<double>> tokenize(String text, {int? maxLength}) {
    if (!_isInitialized) {
      throw Exception('Tokenizer not initialized. Call initialize() first.');
    }
    
    final length = maxLength ?? _maxLength;
    
    // Preprocess text
    final cleanText = _preprocessText(text);
    
    // Split into tokens (simple whitespace tokenization)
    final tokens = cleanText.split(RegExp(r'\s+'));
    
    // Convert tokens to IDs
    final tokenIds = <double>[];
    for (final token in tokens) {
      if (tokenIds.length >= length) break;
      
      final id = _vocab[token.toLowerCase()] ?? _vocab[_unkToken] ?? 1;
      tokenIds.add(id.toDouble());
    }
    
    // Pad or truncate to max length
    while (tokenIds.length < length) {
      tokenIds.add((_vocab[_padToken] ?? 0).toDouble());
    }
    
    return [tokenIds.sublist(0, length)];
  }

  /// Preprocess text before tokenization
  String _preprocessText(String text) {
    // Lowercase
    String processed = text.toLowerCase();
    
    // Remove URLs
    processed = processed.replaceAll(
      RegExp(r'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+'),
      ' url ',
    );
    
    // Remove email addresses
    processed = processed.replaceAll(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      ' email ',
    );
    
    // Remove phone numbers
    processed = processed.replaceAll(
      RegExp(r'\b\d{10,}\b'),
      ' phone ',
    );
    
    // Remove special characters but keep spaces
    processed = processed.replaceAll(RegExp(r'[^\w\s]'), ' ');
    
    // Remove multiple spaces
    processed = processed.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return processed;
  }

  /// Get vocabulary size
  int get vocabularySize => _vocab.length;

  /// Check if tokenizer is initialized
  bool get isInitialized => _isInitialized;
}

