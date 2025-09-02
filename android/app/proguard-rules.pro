# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.firebase.** { *; }

# Play Core rules
-keep class com.google.android.play.core.** { *; }

# Keep your model classes
-keep class com.mujjar.mujjar_funds.models.** { *; }

# General Android rules
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# For native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep the R class and its fields
-keep class **.R$* {
    public static <fields>;
}
