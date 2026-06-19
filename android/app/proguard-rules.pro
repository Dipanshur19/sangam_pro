# ── Flutter ──────────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# ── Firebase (optional — only used if configured) ────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── flutter_local_notifications ──────────────────────────
# Uses Gson + reflection to (de)serialize scheduled notifications.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ── image_picker / permission_handler / sensors_plus ─────
-keep class androidx.lifecycle.** { *; }

# ── Keep annotations & generic signatures for plugins ────
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# ── Play Core (referenced by Flutter deferred components) ─
-dontwarn com.google.android.play.core.**


# ── androidx.window (optional OEM window extensions) ─────
# These extension/sidecar classes are provided by some device vendors at
# runtime and are absent at compile time. They are referenced reflectively,
# so we tell R8 not to fail on them.
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**
-keep class androidx.window.** { *; }
