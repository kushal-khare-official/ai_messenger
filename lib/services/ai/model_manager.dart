import 'package:tflite_flutter/tflite_flutter.dart';
import '../../models/sms_message.dart';
import '../../utils/app_logger.dart';
import 'tokenizer.dart';

/// Manages the TensorFlow Lite model for SMS classification
class ModelManager {
  Interpreter? _interpreter;
  SMSTokenizer? _tokenizer;
  bool _isInitialized = false;
  
  // Model configuration
  static const String _modelPath = 'assets/ml_models/sms_classifier.tflite';
  static const int _maxSequenceLength = 128;
  
  // Category mapping (output indices to categories)
  final List<SmsCategory> _categoryMapping = [
    SmsCategory.otp,
    SmsCategory.bankAlert,
    SmsCategory.financeAlert,
    SmsCategory.offer,
    SmsCategory.coupon,
    SmsCategory.promotional,
    SmsCategory.personal,
    SmsCategory.other,
  ];

  /// Initialize the model and tokenizer
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Initialize tokenizer
      _tokenizer = SMSTokenizer();
      await _tokenizer!.initialize();
      
      // Load TFLite model
      try {
        _interpreter = await Interpreter.fromAsset(_modelPath);
        AppLogger.info('Model loaded successfully');
        AppLogger.debug('Input shape: ${_interpreter!.getInputTensor(0).shape}');
        AppLogger.debug('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
      } catch (e) {
        AppLogger.warning('Model file not found, using rule-based classification', error: e);
        // Don't fail if model not available, will use fallback
        return false;
      }
      
      _isInitialized = true;
      return true;
    } catch (e) {
      AppLogger.error('Error initializing model', error: e);
      return false;
    }
  }

  /// Classify text using the ML model
  Future<SmsCategory?> classifyWithModel(String text) async {
    if (!_isInitialized || _interpreter == null || _tokenizer == null) {
      return null; // Fall back to rule-based
    }
    
    try {
      // Tokenize input
      final input = _tokenizer!.tokenize(text, maxLength: _maxSequenceLength);
      
      // Prepare output buffer
      final output = List.filled(1, List.filled(_categoryMapping.length, 0.0)).map((e) => List<double>.from(e)).toList();
      
      // Run inference
      _interpreter!.run(input, output);
      
      // Get prediction
      final probabilities = output[0];
      final maxIndex = _argMax(probabilities);
      final confidence = probabilities[maxIndex];
      
      AppLogger.debug('Classification probabilities: $probabilities');
      AppLogger.debug('Predicted category: ${_categoryMapping[maxIndex]}, confidence: $confidence');
      
      // Return result if confidence is high enough
      if (confidence > 0.5) {
        return _categoryMapping[maxIndex];
      }
      
      return null; // Low confidence, use fallback
    } catch (e) {
      AppLogger.error('Error during inference', error: e);
      return null;
    }
  }

  /// Get confidence scores for all categories
  Future<Map<SmsCategory, double>?> getConfidenceScores(String text) async {
    if (!_isInitialized || _interpreter == null || _tokenizer == null) {
      return null;
    }
    
    try {
      final input = _tokenizer!.tokenize(text, maxLength: _maxSequenceLength);
      final output = List.filled(1, List.filled(_categoryMapping.length, 0.0)).map((e) => List<double>.from(e)).toList();
      
      _interpreter!.run(input, output);
      
      final probabilities = output[0];
      final scores = <SmsCategory, double>{};
      
      for (int i = 0; i < _categoryMapping.length; i++) {
        scores[_categoryMapping[i]] = probabilities[i];
      }
      
      return scores;
    } catch (e) {
      AppLogger.error('Error getting confidence scores', error: e);
      return null;
    }
  }

  /// Check if spam using model (if available)
  Future<double?> getSpamScore(String text) async {
    if (!_isInitialized || _interpreter == null) {
      return null;
    }
    
    try {
      // For now, use promotional/offer categories as spam indicators
      final scores = await getConfidenceScores(text);
      if (scores == null) return null;
      
      // Calculate spam score based on promotional categories
      final spamScore = (scores[SmsCategory.promotional] ?? 0.0) +
                       (scores[SmsCategory.offer] ?? 0.0) * 0.5 +
                       (scores[SmsCategory.coupon] ?? 0.0) * 0.3;
      
      return spamScore;
    } catch (e) {
      AppLogger.error('Error calculating spam score', error: e);
      return null;
    }
  }

  /// Find index of maximum value in list
  int _argMax(List<double> list) {
    double max = list[0];
    int maxIndex = 0;
    
    for (int i = 1; i < list.length; i++) {
      if (list[i] > max) {
        max = list[i];
        maxIndex = i;
      }
    }
    
    return maxIndex;
  }

  /// Check if model is initialized
  bool get isInitialized => _isInitialized && _interpreter != null;

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}

