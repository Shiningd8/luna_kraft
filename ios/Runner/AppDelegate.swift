import UIKit
import Flutter
import GoogleMobileAds

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Initialize Google Mobile Ads SDK
    GADMobileAds.sharedInstance().start(completionHandler: nil)
    
    // Register the native ad factory
    let nativeAdFactory = LunaKraftNativeAdFactory()
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
        self, factoryId: "adFactoryExample", nativeAdFactory: nativeAdFactory)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    // Unregister the native ad factory
    FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(self, factoryId: "adFactoryExample")
  }
}

class LunaKraftNativeAdFactory : FLTNativeAdFactory {
    func createNativeAd(_ nativeAd: GADNativeAd,
                       customOptions: [AnyHashable : Any]? = nil) -> GADNativeAdView? {
        // Create the native ad view
        let nibView = Bundle.main.loadNibNamed("NativeAdPost", owner: nil, options: nil)!.first
        let nativeAdView = nibView as! GADNativeAdView
        
        // Set the native ad view's properties
        nativeAdView.nativeAd = nativeAd
        
        // Set the headline
        (nativeAdView.headlineView as! UILabel).text = nativeAd.headline
        nativeAdView.headlineView?.isHidden = nativeAd.headline == nil
        
        // Set the body
        (nativeAdView.bodyView as! UILabel).text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
        
        // Set the call to action
        (nativeAdView.callToActionView as! UIButton).setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
        
        // Set the icon
        (nativeAdView.iconView as! UIImageView).image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = nativeAd.icon == nil
        
        // Set the media view
        if let mediaView = nativeAdView.mediaView as? GADMediaView {
            mediaView.mediaContent = nativeAd.mediaContent
            mediaView.isHidden = nativeAd.mediaContent == nil
        }
        
        // Set the advertiser
        if let advertiserView = nativeAdView.advertiserView as? UILabel {
            advertiserView.text = nativeAd.advertiser
            advertiserView.isHidden = nativeAd.advertiser == nil
        }
        
        return nativeAdView
    }
}
