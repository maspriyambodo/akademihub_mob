# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Desugaring
-keep class java.time.** { *; }

# Local notifications & Firebase
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.firebase.** { *; }

# Native Kiosk Mode Activity
-keep class id.akademihub.akademihub_mob.MainActivity { *; }

# Play Core (deferred components / split install not used)
-dontwarn com.google.android.play.core.**

