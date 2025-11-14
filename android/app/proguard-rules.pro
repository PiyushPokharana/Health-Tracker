# Keep Flutter classes used for reflection and plugin registration
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep generated registrant
-keep class **.GeneratedPluginRegistrant { *; }

# Keep database and model classes
-keep class ** extends com.path.sqflite.** { *; }
-keep class ** extends androidx.room.** { *; }

# Keep model classes used by your app
-keep class com.example.daily_success_tracker_1.** { *; }

# Don't obfuscate
-dontobfuscate

# Optimization rules
-optimizationpasses 5
-allowaccessmodification
