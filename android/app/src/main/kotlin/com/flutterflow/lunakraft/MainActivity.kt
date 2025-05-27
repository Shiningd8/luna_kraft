package com.flutterflow.lunakraft

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.os.Bundle
import android.util.Log
import com.google.firebase.appcheck.FirebaseAppCheck
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory
import com.google.firebase.FirebaseApp
import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        try {
            // Initialize Firebase
            FirebaseApp.initializeApp(this)
            
            // Initialize Firebase App Check with proper provider
            val firebaseAppCheck = FirebaseAppCheck.getInstance()
            
            // Use Debug provider in debug builds, Play Integrity in release
            val isDebug = BuildConfig.DEBUG
            
            if (isDebug) {
                Log.d("LunaKraft", "Initializing Firebase App Check with Debug provider")
                firebaseAppCheck.installAppCheckProviderFactory(
                    DebugAppCheckProviderFactory.getInstance()
                )
            } else {
                Log.d("LunaKraft", "Initializing Firebase App Check with Play Integrity provider")
                firebaseAppCheck.installAppCheckProviderFactory(
                    PlayIntegrityAppCheckProviderFactory.getInstance()
                )
            }
            
            Log.d("LunaKraft", "Firebase App Check initialized successfully")
        } catch (e: Exception) {
            Log.e("LunaKraft", "Error initializing Firebase App Check: ${e.message}", e)
        }
    }
    
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
    }
} 