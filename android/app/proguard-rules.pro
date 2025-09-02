# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep your main application class
-keep class com.yourcompany.ubx_practical_mobile.MainActivity { *; }

# Fix for Play Store Split Install classes (the missing classes causing the error)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Flutter Play Store specific classes
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }

# Device Info Plus plugin (mentioned in stack trace)
-keep class io.flutter.plugins.deviceinfoplus.** { *; }

# General rules to prevent issues
-dontwarn java.lang.invoke.StringConcatFactory
