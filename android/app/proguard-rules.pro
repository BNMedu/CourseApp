# Защита BackEvent
-keep class android.window.BackEvent { *; }

# flutter_inappwebview требует это:
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview.**

# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
