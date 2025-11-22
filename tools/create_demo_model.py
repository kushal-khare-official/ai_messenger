#!/usr/bin/env python3
"""
Create a demo TensorFlow Lite model for SMS classification.

This script creates a simple neural network model for testing purposes.
For production use, train a proper model on your SMS dataset.

Usage:
    python3 create_demo_model.py

Output:
    - sms_classifier.tflite (model file)
    - vocab.txt (vocabulary file)

Requirements:
    pip install tensorflow numpy
"""

import tensorflow as tf
import numpy as np
import os

def create_demo_model():
    """Create a simple text classification model using only standard TFLite ops."""
    
    print("Creating demo SMS classification model...")
    print("Note: Using simple architecture with standard TFLite ops for maximum compatibility")
    
    # Model parameters
    vocab_size = 5000
    embedding_dim = 32
    max_length = 128
    num_categories = 8
    
    # Build model using ONLY standard TFLite operations
    # No LSTM, no RNN - these require Flex ops
    model = tf.keras.Sequential([
        tf.keras.layers.Embedding(
            vocab_size, 
            embedding_dim, 
            input_length=max_length,
            name='embedding'
        ),
        # Use GlobalAveragePooling instead of LSTM (fully TFLite compatible)
        tf.keras.layers.GlobalAveragePooling1D(name='pooling'),
        tf.keras.layers.Dense(64, activation='relu', name='dense1'),
        tf.keras.layers.Dropout(0.3, name='dropout1'),
        tf.keras.layers.Dense(32, activation='relu', name='dense2'),
        tf.keras.layers.Dropout(0.3, name='dropout2'),
        tf.keras.layers.Dense(num_categories, activation='softmax', name='output')
    ])
    
    # Compile the model (required for proper conversion)
    model.compile(
        optimizer='adam',
        loss='sparse_categorical_crossentropy',
        metrics=['accuracy']
    )
    
    # Initialize model
    model.build((None, max_length))
    
    # Print model summary
    print("\nModel Architecture:")
    model.summary()
    
    # Convert to TensorFlow Lite
    print("\nConverting to TensorFlow Lite...")
    print("Using standard TFLite ops only (no Flex ops needed)...")
    
    # Use concrete function for conversion (more reliable)
    @tf.function(input_signature=[tf.TensorSpec(shape=[1, max_length], dtype=tf.float32)])
    def model_fn(x):
        return model(x, training=False)
    
    concrete_func = model_fn.get_concrete_function()
    converter = tf.lite.TFLiteConverter.from_concrete_functions([concrete_func])
    
    # Use ONLY standard TFLite operations for maximum compatibility
    # No SELECT_TF_OPS needed since we removed LSTM
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS  # Only built-in TFLite ops
    ]
    
    # Disable tensor list lowering (required for LSTM)
    converter._experimental_lower_tensor_list_ops = False
    
    # Apply optimizations
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    
    tflite_model = converter.convert()
    
    # Save model
    model_path = 'sms_classifier.tflite'
    with open(model_path, 'wb') as f:
        f.write(tflite_model)
    
    model_size = os.path.getsize(model_path) / (1024 * 1024)  # MB
    print(f"\n✓ Model saved to: {model_path}")
    print(f"  Size: {model_size:.2f} MB")
    
    return model_path

def create_vocabulary():
    """Create a demo vocabulary file."""
    
    print("\nCreating vocabulary file...")
    
    # Common SMS keywords organized by category
    keywords = {
        'special_tokens': ['[PAD]', '[UNK]'],
        'otp': ['otp', 'code', 'verify', 'verification', 'authentication', 'pin', 
                'passcode', 'confirm', 'security', 'temporary'],
        'banking': ['bank', 'account', 'balance', 'credited', 'debited', 
                   'transaction', 'atm', 'withdrawal', 'deposit', 'statement'],
        'finance': ['payment', 'invoice', 'due', 'bill', 'loan', 'emi', 
                   'insurance', 'credit', 'card', 'stock', 'investment'],
        'offers': ['offer', 'discount', 'sale', 'deal', 'save', 'flat', 
                  'off', 'special', 'price', 'limited', 'hurry'],
        'coupons': ['coupon', 'promo', 'voucher', 'redeem', 'cashback', 
                   'reward', 'points', 'gift'],
        'common': ['dear', 'customer', 'your', 'the', 'is', 'for', 'and', 
                  'to', 'from', 'on', 'at', 'in', 'with', 'by', 'as', 
                  'this', 'that', 'have', 'has', 'will', 'can', 'get',
                  'now', 'today', 'call', 'visit', 'click', 'reply',
                  'message', 'sms', 'alert', 'notification', 'update'],
        'numbers': [str(i) for i in range(100)],
    }
    
    # Flatten keywords into vocabulary list
    vocab = []
    for category, words in keywords.items():
        vocab.extend(words)
    
    # Add some generic tokens to reach ~5000 tokens
    for i in range(len(vocab), 5000):
        vocab.append(f'token_{i}')
    
    # Save vocabulary
    vocab_path = 'vocab.txt'
    with open(vocab_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(vocab))
    
    print(f"✓ Vocabulary saved to: {vocab_path}")
    print(f"  Size: {len(vocab)} tokens")
    
    return vocab_path

def test_model(model_path):
    """Test the created model with sample input."""
    
    print("\nTesting model...")
    
    try:
        # Load the model
        interpreter = tf.lite.Interpreter(model_path=model_path)
        interpreter.allocate_tensors()
        
        # Get input and output details
        input_details = interpreter.get_input_details()
        output_details = interpreter.get_output_details()
        
        print("\nModel Details:")
        print(f"  Input shape: {input_details[0]['shape']}")
        print(f"  Output shape: {output_details[0]['shape']}")
        
        # Create sample input
        sample_input = np.array([[1, 2, 3, 4, 5] + [0] * 123], dtype=np.float32)
        
        # Run inference
        interpreter.set_tensor(input_details[0]['index'], sample_input)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]['index'])
        
        print(f"\nSample inference successful!")
        print(f"  Output shape: {output.shape}")
        print(f"  Sample output: {output[0][:3]}... (showing first 3 values)")
        
    except Exception as e:
        print(f"⚠ Error testing model: {e}")

def main():
    """Main function."""
    
    print("=" * 60)
    print("SMS Classifier Demo Model Creator")
    print("=" * 60)
    print()
    print("⚠ WARNING: This creates a demo model with random weights!")
    print("For production use, train a proper model on labeled SMS data.")
    print()
    
    # Create model and vocabulary
    model_path = create_demo_model()
    vocab_path = create_vocabulary()
    
    # Test the model
    test_model(model_path)
    
    print("\n" + "=" * 60)
    print("Setup Instructions:")
    print("=" * 60)
    print(f"1. Copy {model_path} to assets/ml_models/")
    print(f"2. Copy {vocab_path} to assets/ml_models/")
    print("3. Run: flutter pub get")
    print("4. Run: flutter run")
    print()
    print("The app will now use on-device AI classification!")
    print()
    print("For better accuracy, train a proper model using:")
    print("  See AI_MODEL_SETUP.md for training instructions")
    print("=" * 60)

if __name__ == '__main__':
    main()

