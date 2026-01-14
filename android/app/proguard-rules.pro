# ONNX Runtime ProGuard Rules
-keep class ai.onnxruntime.** { *; }
-keep interface ai.onnxruntime.** { *; }
-dontwarn ai.onnxruntime.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep JNI methods
-keepclasseswithmembers class * {
    native <methods>;
}

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Bugsnag
-keep class com.bugsnag.android.** { *; }
-dontwarn com.bugsnag.android.**

