import UIKit
import Flutter
import AVFoundation


@UIApplicationMain
class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
    
    override func application(_ application: UIApplication,
                              didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }

       //set audio session to be on background always
        application.beginReceivingRemoteControlEvents()
        do {
            if #available(iOS 10.0, *) {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [.mixWithOthers,.allowBluetooth,.allowAirPlay,.allowBluetoothA2DP])
            } else {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [.mixWithOthers,.allowBluetooth])
            }
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
