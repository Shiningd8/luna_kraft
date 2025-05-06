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
import com.google.android.gms.ads.MobileAds
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import com.google.android.gms.ads.nativead.MediaView

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Register plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Initialize AdMob
        MobileAds.initialize(this) {}
        
        // Register the native ad factory
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "adFactoryExample",
            NativeAdFactory(layoutInflater)
        )
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
        
        // Unregister the native ad factory
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            "adFactoryExample"
        )
    }
}

// Custom native ad factory for Android
class NativeAdFactory(private val layoutInflater: LayoutInflater) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        // Create a native ad view that matches the app's post design
        val adView = layoutInflater.inflate(R.layout.native_ad_post, null) as NativeAdView
        
        // Get references to the views
        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val callToActionView = adView.findViewById<Button>(R.id.ad_call_to_action)
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)
        val advertiserView = adView.findViewById<TextView>(R.id.ad_advertiser)
        
        // Set the headline
        headlineView.text = nativeAd.headline
        adView.headlineView = headlineView
        
        // Set the body text
        if (nativeAd.body != null) {
            bodyView.text = nativeAd.body
            bodyView.visibility = View.VISIBLE
            adView.bodyView = bodyView
        } else {
            bodyView.visibility = View.INVISIBLE
        }
        
        // Set the call to action
        if (nativeAd.callToAction != null) {
            callToActionView.text = nativeAd.callToAction
            callToActionView.visibility = View.VISIBLE
            adView.callToActionView = callToActionView
        } else {
            callToActionView.visibility = View.INVISIBLE
        }
        
        // Set the app icon
        if (nativeAd.icon != null) {
            iconView.setImageDrawable(nativeAd.icon?.drawable)
            iconView.visibility = View.VISIBLE
            adView.iconView = iconView
        } else {
            iconView.visibility = View.GONE
        }
        
        // Set the media view
        if (nativeAd.mediaContent != null) {
            mediaView.setMediaContent(nativeAd.mediaContent!!)
            mediaView.visibility = View.VISIBLE
            adView.mediaView = mediaView
        } else {
            mediaView.visibility = View.GONE
        }
        
        // Set the advertiser
        if (nativeAd.advertiser != null) {
            advertiserView.text = nativeAd.advertiser
            advertiserView.visibility = View.VISIBLE
            adView.advertiserView = advertiserView
        } else {
            advertiserView.visibility = View.GONE
        }
        
        // Register the native ad view with the native ad object
        adView.setNativeAd(nativeAd)
        
        return adView
    }
} 