package com.cruises.mobile

import io.flutter.embedding.android.FlutterActivity
import android.util.Log
import android.os.Bundle

class MainActivity: FlutterActivity() {
    companion object {
        private const val TAG = "CruisesMobile"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.i(TAG, "MainActivity onCreate() called")
        Log.i(TAG, "Letting llama_cpp_dart handle library loading via FFI")
        Log.i(TAG, "Native library path: ${applicationInfo.nativeLibraryDir}")
    }

    override fun onStart() {
        super.onStart()
        Log.d(TAG, "MainActivity onStart() called")
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "MainActivity onResume() called")
    }

    override fun onPause() {
        super.onPause()
        Log.d(TAG, "MainActivity onPause() called")
    }

    override fun onStop() {
        super.onStop()
        Log.d(TAG, "MainActivity onStop() called")
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.i(TAG, "MainActivity onDestroy() called")
    }
}

