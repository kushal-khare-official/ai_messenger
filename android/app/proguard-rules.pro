# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt

# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep interface org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.**
-dontwarn org.tensorflow.lite.gpu.**

# Telephony Plugin
-keep class com.shounakmulay.telephony.** { *; }
-keep interface com.shounakmulay.telephony.** { *; }
-dontwarn com.shounakmulay.telephony.**

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep custom model classes if any
-keep class com.example.messenger_ai.** { *; }

