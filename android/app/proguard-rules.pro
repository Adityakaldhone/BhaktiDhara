# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# WorkManager and Room (fixes WorkDatabase reflection crash in release builds)
-keep class androidx.work.** { *; }
-keep interface androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-dontwarn androidx.work.impl.**
-keep class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
    <init>();
}
-keep class * extends androidx.room.RoomDatabase {
    public <init>();
    <init>();
}
-keepclassmembers class * extends androidx.room.RoomDatabase {
    public <init>();
    <init>();
}
-keep class * extends androidx.work.Worker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keep class * extends androidx.work.InputMerger {
    public <init>();
    <init>();
}

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keepclassmembers class com.google.gson.** { *; }

# Google Mobile Ads (AdMob)
-keep class com.google.android.gms.ads.** { *; }
-keep interface com.google.android.gms.ads.** { *; }
-keep public class com.google.android.gms.ads.initialization.OnInitializationCompleteListener

# Google Play Billing / In-App Purchase
-keep class com.android.billingclient.** { *; }
-keep interface com.android.billingclient.** { *; }
-keep class io.flutter.plugins.inapppurchase.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Audio & Speech
-keep class com.ryanheise.audioservice.** { *; }

# Standard reflection attributes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Google Play Core (Flutter deferred components)
-dontwarn com.google.android.play.core.**

