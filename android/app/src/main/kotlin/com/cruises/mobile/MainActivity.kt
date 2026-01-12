package com.cruises.mobile

import io.flutter.embedding.android.FlutterActivity
import android.util.Log

class MainActivity: FlutterActivity() {
    companion object {
        private const val TAG = "LlamaLibLoader"

        init {
            // Pre-load llama.cpp libraries in the correct dependency order
            // This must happen BEFORE Dart FFI tries to load libllama.so
            // Otherwise: "dlopen failed: library libggml-cpu.so not found"
            try {
                // Load dependencies first (order matters!)
                tryLoadLibrary("OpenCL")      // GPU acceleration (optional, may not exist on all devices)
                tryLoadLibrary("ggml-base")   // Base ggml library
                tryLoadLibrary("ggml-cpu")    // CPU backend
                tryLoadLibrary("ggml-opencl") // OpenCL backend (optional)
                tryLoadLibrary("ggml")        // Main ggml library
                tryLoadLibrary("llama")       // Main llama library
                Log.i(TAG, "Successfully pre-loaded llama.cpp libraries")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to pre-load llama.cpp libraries: ${e.message}")
            }
        }

        private fun tryLoadLibrary(name: String) {
            try {
                System.loadLibrary(name)
                Log.d(TAG, "Loaded lib$name.so")
            } catch (e: UnsatisfiedLinkError) {
                // Library might not exist (e.g., OpenCL on devices without GPU support)
                Log.w(TAG, "Could not load lib$name.so: ${e.message}")
            }
        }
    }
}

