package com.termino.app

import io.flutter.embedding.android.FlutterFragmentActivity

/**
 * A FragmentActivity, not a plain FlutterActivity.
 *
 * Android's BiometricPrompt — which `local_auth` uses — can only be shown from
 * a FragmentActivity. With the default FlutterActivity the biometric gate
 * throws at the moment it is needed, which is the worst possible time for a
 * security control to fail.
 */
class MainActivity : FlutterFragmentActivity()
