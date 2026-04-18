# Keep Agora classes
-keep class io.agora.** { *; }
-keep class io.agora.rtc2.** { *; }

# Keep Firebase classes
-keep class com.google.firebase.** { *; }

# Play Store Core (prevent R8 errors for missing classes)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Flutter specific rules (usually handled by Flutter SDK but good to have)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.editing.** { *; }
