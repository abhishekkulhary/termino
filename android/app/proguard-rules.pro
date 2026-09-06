# Termino keeps R8 largely at its defaults; Flutter's own rules cover the
# engine. These are the cases where reflection or JNI defeats shrinking.

# flutter_secure_storage reaches the Android Keystore through reflection in
# places, and a stripped class there fails at runtime rather than at build.
-keep class androidx.security.crypto.** { *; }

# The PTY plugin is loaded over FFI, so nothing in Dart references its JNI
# entry points in a way R8 can see.
-keep class com.termino.flutter_pty.** { *; }

# Keep annotations that runtime code inspects rather than the compiler.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
